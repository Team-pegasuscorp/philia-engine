@tool
class_name PhiliaMap
extends RefCounted

## Modèle de données d'une carte .philiamap : générique, indépendant du jeu qui l'importe.
## Sérialisé en JSON lisible (voir docs/concept.md §21.2) pour rester diffable/mergeable.

const FORMAT_VERSION := 3
const DEFAULT_LAYER := "Sol"

## Types "Tiles" (doc §7/§8) dont la variante de raccord (coin/bord/centre…)
## est recalculée automatiquement selon les voisins de même type sur le même
## calque. Les modules (Porte, Pilier…) et Coin/Bord posés à la main restent
## des choix manuels, non recalculés.
const AUTOTILE_TYPES: Array[String] = ["Sol", "Mur", "Terrain"]

## Bitmask de voisinage (N=1, E=2, S=4, W=8), convention Godot TileSet.
const NEIGHBOR_OFFSETS := {
	1: Vector2i(0, -1),
	2: Vector2i(1, 0),
	4: Vector2i(0, 1),
	8: Vector2i(-1, 0),
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


func get_tile(x: int, y: int, layer: String = DEFAULT_LAYER) -> Dictionary:
	for tile in tiles:
		if tile.get("x") == x and tile.get("y") == y and tile.get("layer", DEFAULT_LAYER) == layer:
			return tile
	return {}


func set_tile(x: int, y: int, type: String, rotation: int = 0, layer: String = DEFAULT_LAYER) -> void:
	var tile := get_tile(x, y, layer)
	if tile.is_empty():
		tiles.append({"x": x, "y": y, "type": type, "rotation": rotation, "layer": layer, "variant": 0})
	else:
		tile["type"] = type
		tile["rotation"] = rotation
	_recompute_variants_around(x, y, layer)


func remove_tile(x: int, y: int, layer: String = DEFAULT_LAYER) -> void:
	for i in range(tiles.size() - 1, -1, -1):
		var tile := tiles[i]
		if tile.get("x") == x and tile.get("y") == y and tile.get("layer", DEFAULT_LAYER) == layer:
			tiles.remove_at(i)
			_recompute_variants_around(x, y, layer)
			return


func rotate_tile(x: int, y: int, layer: String = DEFAULT_LAYER) -> void:
	var tile := get_tile(x, y, layer)
	if not tile.is_empty():
		tile["rotation"] = int(tile.get("rotation", 0) + 90) % 360


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
