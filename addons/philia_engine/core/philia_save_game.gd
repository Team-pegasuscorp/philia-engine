@tool
class_name PhiliaSaveGame
extends RefCounted

## Sauvegarde de partie générique (V6, §19) : un ensemble de sections
## nommées (dictionnaires JSON-compatibles), chacune fournie par un autre
## système Philia via son propre to_dict()/data (PhiliaStats,
## PhiliaInventory, PhiliaQuestLog...) ou directement par le jeu. Philia ne
## connaît pas le contenu d'une section, seulement son nom (§20) — même
## texte JSON lisible/diffable que .philiamap (§21.2).

const FORMAT_VERSION := 1

var format_version: int = FORMAT_VERSION
var sections: Dictionary = {}  ## nom -> Dictionary


func set_section(section_name: String, data: Dictionary) -> void:
	sections[section_name] = data


func get_section(section_name: String, default: Dictionary = {}) -> Dictionary:
	return sections.get(section_name, default)


func has_section(section_name: String) -> bool:
	return sections.has(section_name)


func to_dict() -> Dictionary:
	return {"format_version": format_version, "sections": sections}


static func from_dict(data: Dictionary) -> PhiliaSaveGame:
	var save_game := PhiliaSaveGame.new()
	save_game.format_version = data.get("format_version", FORMAT_VERSION)
	save_game.sections = data.get("sections", {})
	return save_game


func save(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict(), "\t"))
	return OK


static func load(path: String) -> PhiliaSaveGame:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return from_dict(parsed)
