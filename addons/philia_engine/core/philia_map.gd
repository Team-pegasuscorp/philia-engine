@tool
class_name PhiliaMap
extends RefCounted

## Modèle de données d'une carte .philiamap : générique, indépendant du jeu qui l'importe.
## Sérialisé en JSON lisible (voir docs/concept.md §21.2) pour rester diffable/mergeable.

const FORMAT_VERSION := 4
const DEFAULT_LAYER := "Sol"

## Types "Tiles" (doc §7/§8) dont la variante de raccord (coin/bord/centre…)
## est recalculée automatiquement selon les voisins de même type sur le même
## calque. Les modules (Porte, Pilier…) et Coin/Bord posés à la main restent
## des choix manuels, non recalculés.
## Sol/Mur/Terrain : usage manuel (donjons, §1-§8). Le reste : biomes du
## générateur de monde par bruit (§9) — Eau n'est pas dans la liste du doc
## mais complète naturellement Marais/Montagne comme zone infranchissable.
const AUTOTILE_TYPES: Array[String] = [
	"Sol", "Mur", "Terrain",
	"Plaine", "Forêt", "Désert", "Plage", "Neige", "Marais", "Montagne", "Eau",
]

## Bitmask de voisinage (N=1, E=2, S=4, W=8), convention Godot TileSet.
const NEIGHBOR_OFFSETS := {
	1: Vector2i(0, -1),
	2: Vector2i(1, 0),
	4: Vector2i(0, 1),
	8: Vector2i(-1, 0),
}

## Types solides par défaut (bloquent le déplacement/donnent une collision
## plein-case), remplaçable au cas par cas via le champ optionnel "solid"
## (bool) d'une tuile. Le jeu qui importe la carte reste libre d'ignorer
## cette info générique (ex: une Porte peut devenir non-solide une fois
## ouverte) — voir docs/concept.md §11.
const DEFAULT_SOLID_TYPES: Array[String] = ["Mur", "Coin", "Bord", "Pilier", "Caisse", "Machine", "Rocher", "Montagne", "Eau"]

## Empreinte (largeur, hauteur en cases) des modules qui occupent plusieurs
## cases (doc §7 : "Un module peut occuper plusieurs cases"). Absent de la
## table -> 1x1. La case d'origine (x, y) est le coin haut-gauche.
const MODULE_FOOTPRINTS: Dictionary = {
	"Porte": Vector2i(2, 1),
	"Escalier": Vector2i(1, 2),
	"Machine": Vector2i(2, 2),
}

## Matériau par défaut (chemin vers une ressource PhiliaMaterial, §6) pour
## un type de module, remplaçable au cas par cas via le champ optionnel
## "material" d'une tuile. Uniquement pour les modules non-autotile pour
## l'instant — les terrains autotile (Sol/Mur/Terrain) sont rendus par le
## TileSet partagé, pas par tuile individuelle.
const DEFAULT_MATERIALS: Dictionary = {
	"Pilier": "res://addons/philia_engine/assets/materials/stone.tres",
	"Caisse": "res://addons/philia_engine/assets/materials/wood.tres",
	"Machine": "res://addons/philia_engine/assets/materials/rusty_metal.tres",
	"Rocher": "res://addons/philia_engine/assets/materials/stone.tres",
}

## Types dont la géométrie est produite par PhiliaProceduralMesh (§4) plutôt
## que par un bloc/mesh fixe, uniquement à l'import 3D (PhiliaImporter2D
## garde un aperçu couleur plat, la déformation de maillage n'a de sens
## qu'en 3D). Valeur = nom de la fonction generate_<valeur> correspondante.
const PROCEDURAL_TYPES: Dictionary = {
	"Rocher": "rock",
	"Pilier": "pillar",
}

var format_version: int = FORMAT_VERSION
var seed: int = 0
var layers: Array[String] = [DEFAULT_LAYER]
var tiles: Array[Dictionary] = []
var entities: Array[Dictionary] = []


func to_dict() -> Dictionary:
	return {
		"format_version": format_version,
		"seed": seed,
		"layers": layers,
		"tiles": tiles,
		"entities": entities,
	}


static func from_dict(data: Dictionary) -> PhiliaMap:
	var map := PhiliaMap.new()
	map.format_version = data.get("format_version", FORMAT_VERSION)
	map.seed = data.get("seed", 0)
	var loaded_layers: Array = data.get("layers", [DEFAULT_LAYER])
	map.layers.assign(loaded_layers if not loaded_layers.is_empty() else [DEFAULT_LAYER])
	map.tiles.assign(data.get("tiles", []))
	for tile in map.tiles:
		if not tile.has("layer"):
			tile["layer"] = DEFAULT_LAYER
	map.entities.assign(data.get("entities", []))
	map.recompute_all_variants()
	return map


func add_layer(layer_name: String) -> void:
	if not layers.has(layer_name):
		layers.append(layer_name)


func remove_layer(layer_name: String) -> void:
	if layers.size() <= 1 or not layers.has(layer_name):
		return
	layers.erase(layer_name)
	for i in range(tiles.size() - 1, -1, -1):
		if tiles[i].get("layer", DEFAULT_LAYER) == layer_name:
			tiles.remove_at(i)


static func footprint_for(type: String) -> Vector2i:
	return MODULE_FOOTPRINTS.get(type, Vector2i(1, 1))


## Recherche exacte : ne trouve que la tuile dont la case d'origine est
## (x, y). Utilisée par l'autotiling (toujours 1x1) et en interne.
func get_tile(x: int, y: int, layer: String = DEFAULT_LAYER) -> Dictionary:
	for tile in tiles:
		if tile.get("x") == x and tile.get("y") == y and tile.get("layer", DEFAULT_LAYER) == layer:
			return tile
	return {}


## Comme get_tile, mais trouve aussi un module multi-case dont l'empreinte
## couvre (x, y) sans que ce soit sa case d'origine. À utiliser pour tout ce
## qui doit réagir au clic/survol d'une case quelconque (suppression,
## rotation, affichage).
func get_tile_at(x: int, y: int, layer: String = DEFAULT_LAYER) -> Dictionary:
	var exact := get_tile(x, y, layer)
	if not exact.is_empty():
		return exact
	for tile in tiles:
		if tile.get("layer", DEFAULT_LAYER) != layer:
			continue
		var w: int = tile.get("w", 1)
		var h: int = tile.get("h", 1)
		if w <= 1 and h <= 1:
			continue
		var ox: int = tile.get("x")
		var oy: int = tile.get("y")
		if x >= ox and x < ox + w and y >= oy and y < oy + h:
			return tile
	return {}


func set_tile(x: int, y: int, type: String, rotation: int = 0, layer: String = DEFAULT_LAYER) -> void:
	var footprint := footprint_for(type)
	if footprint == Vector2i(1, 1):
		var tile := get_tile(x, y, layer)
		if tile.is_empty():
			tiles.append({"x": x, "y": y, "type": type, "rotation": rotation, "layer": layer, "variant": 0})
		else:
			tile["type"] = type
			tile["rotation"] = rotation
			tile.erase("w")
			tile.erase("h")
		_recompute_variants_around(x, y, layer)
		return

	## Module multi-case : nettoie toute tuile (simple ou multi-case) qui
	## chevauche l'empreinte avant de poser la nouvelle.
	for cy in range(y, y + footprint.y):
		for cx in range(x, x + footprint.x):
			remove_tile(cx, cy, layer)
	tiles.append({
		"x": x, "y": y, "type": type, "rotation": rotation, "layer": layer,
		"w": footprint.x, "h": footprint.y,
	})


func remove_tile(x: int, y: int, layer: String = DEFAULT_LAYER) -> void:
	var tile := get_tile_at(x, y, layer)
	if tile.is_empty():
		return
	var origin_x: int = tile.get("x")
	var origin_y: int = tile.get("y")
	var tile_layer: String = tile.get("layer", DEFAULT_LAYER)
	var index := tiles.find(tile)
	if index != -1:
		tiles.remove_at(index)
	_recompute_variants_around(origin_x, origin_y, tile_layer)


func rotate_tile(x: int, y: int, layer: String = DEFAULT_LAYER) -> void:
	var tile := get_tile_at(x, y, layer)
	if not tile.is_empty():
		tile["rotation"] = int(tile.get("rotation", 0) + 90) % 360


## Seed de génération procédurale pour cette tuile : le champ optionnel
## "seed" prime, sinon dérivé du seed de la carte + de la position (stable
## d'un import à l'autre, mais différent d'une case à l'autre — "Le
## générateur produit une géométrie différente selon le seed", §4).
static func seed_for(tile: Dictionary, map_seed: int) -> int:
	if tile.has("seed"):
		return int(tile["seed"])
	return hash("%d_%d_%d" % [map_seed, tile.get("x", 0), tile.get("y", 0)])


func recompute_all_variants() -> void:
	for tile in tiles:
		_recompute_variant_at(tile.get("x"), tile.get("y"), tile.get("layer", DEFAULT_LAYER))


## Recalcule la variante de (x, y) et de ses 4 voisins directs : poser ou
## retirer une tuile peut changer le raccord de celles qui l'entourent.
func _recompute_variants_around(x: int, y: int, layer: String) -> void:
	_recompute_variant_at(x, y, layer)
	for offset in NEIGHBOR_OFFSETS.values():
		_recompute_variant_at(x + offset.x, y + offset.y, layer)


func _recompute_variant_at(x: int, y: int, layer: String) -> void:
	var tile := get_tile(x, y, layer)
	if tile.is_empty() or not AUTOTILE_TYPES.has(tile.get("type")):
		return
	var type: String = tile["type"]
	var mask := 0
	for bit in NEIGHBOR_OFFSETS:
		var offset: Vector2i = NEIGHBOR_OFFSETS[bit]
		var neighbor := get_tile(x + offset.x, y + offset.y, layer)
		if not neighbor.is_empty() and neighbor.get("type") == type:
			mask |= bit
	tile["variant"] = mask


static func is_solid(tile: Dictionary) -> bool:
	if tile.has("solid"):
		return bool(tile["solid"])
	return DEFAULT_SOLID_TYPES.has(tile.get("type", ""))


## Chemin vers la ressource PhiliaMaterial à utiliser pour cette tuile, ou
## "" si aucun matériau n'est défini (le rendu retombe sur une couleur de
## secours de la palette).
static func material_for(tile: Dictionary) -> String:
	if tile.has("material"):
		return String(tile["material"])
	return DEFAULT_MATERIALS.get(tile.get("type", ""), "")


func save(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict(), "\t"))
	return OK


static func load(path: String) -> PhiliaMap:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return from_dict(parsed)
