@tool
class_name PhiliaMap
extends RefCounted

## Modèle de données d'une carte .philiamap : générique, indépendant du jeu qui l'importe.
## Sérialisé en JSON lisible (voir docs/concept.md §21.2) pour rester diffable/mergeable.

const FORMAT_VERSION := 1

var format_version: int = FORMAT_VERSION
var seed: int = 0
var tiles: Array[Dictionary] = []
var entities: Array[Dictionary] = []


func to_dict() -> Dictionary:
	return {
		"format_version": format_version,
		"seed": seed,
		"tiles": tiles,
		"entities": entities,
	}


static func from_dict(data: Dictionary) -> PhiliaMap:
	var map := PhiliaMap.new()
	map.format_version = data.get("format_version", FORMAT_VERSION)
	map.seed = data.get("seed", 0)
	map.tiles.assign(data.get("tiles", []))
	map.entities.assign(data.get("entities", []))
	return map


func get_tile(x: int, y: int) -> Dictionary:
	for tile in tiles:
		if tile.get("x") == x and tile.get("y") == y:
			return tile
	return {}


func set_tile(x: int, y: int, type: String, rotation: int = 0) -> void:
	var tile := get_tile(x, y)
	if tile.is_empty():
		tiles.append({"x": x, "y": y, "type": type, "rotation": rotation})
	else:
		tile["type"] = type
		tile["rotation"] = rotation


func remove_tile(x: int, y: int) -> void:
	for i in range(tiles.size() - 1, -1, -1):
		if tiles[i].get("x") == x and tiles[i].get("y") == y:
			tiles.remove_at(i)
			return


func rotate_tile(x: int, y: int) -> void:
	var tile := get_tile(x, y)
	if not tile.is_empty():
		tile["rotation"] = int(tile.get("rotation", 0) + 90) % 360


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
