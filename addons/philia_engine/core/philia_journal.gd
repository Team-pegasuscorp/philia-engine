@tool
class_name PhiliaJournal
extends RefCounted

## Carnet du joueur générique (§19 du concept) : mémoire persistante de ce
## que le joueur a découvert, qui survit aux boucles/resets contrairement à
## la position dans le couloir (voir PhiliaLoopController). Ne préjuge ni du
## contenu ni du jeu : les entrées sont des dictionnaires libres classés par
## catégorie ("dates", "personnes", "regles", "hypotheses" pour Le Couloir,
## mais catégories entièrement libres pour une autre idée). Sérialisé en
## JSON comme PhiliaMap (§21.2 : diffable/mergeable, pas de format opaque).

const FORMAT_VERSION := 1

var format_version: int = FORMAT_VERSION
var entries: Dictionary = {} # category (String) -> Array[Dictionary]


func add_entry(category: String, entry: Dictionary) -> void:
	if not entries.has(category):
		entries[category] = []
	entries[category].append(entry)


## true si au moins une entrée de `category` satisfait `predicate`. Utilisé
## par PhiliaConditions pour des conditions du type "le joueur sait déjà
## que X" sans coupler ce carnet à une logique de jeu particulière.
func has_entry(category: String, predicate: Callable) -> bool:
	for entry in entries.get(category, []):
		if predicate.call(entry):
			return true
	return false


## Variante sans Callable, pour des conditions sérialisables en JSON
## (§21.3 : tout doit être pilotable par un agent, donc pas seulement par
## du code) : `where` est un sous-ensemble de champs à faire correspondre
## exactement sur au moins une entrée de la catégorie.
func has_matching_entry(category: String, where: Dictionary) -> bool:
	return has_entry(category, func(entry: Dictionary) -> bool:
		for key in where:
			if entry.get(key) != where[key]:
				return false
		return true
	)


func get_entries(category: String) -> Array:
	return entries.get(category, [])


func to_dict() -> Dictionary:
	return {"format_version": format_version, "entries": entries}


static func from_dict(data: Dictionary) -> PhiliaJournal:
	var journal := PhiliaJournal.new()
	journal.format_version = data.get("format_version", FORMAT_VERSION)
	journal.entries = data.get("entries", {})
	return journal


func save(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict(), "\t"))
	return OK


static func load(path: String) -> PhiliaJournal:
	if not FileAccess.file_exists(path):
		return PhiliaJournal.new()
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return PhiliaJournal.new()
	return from_dict(parsed)
