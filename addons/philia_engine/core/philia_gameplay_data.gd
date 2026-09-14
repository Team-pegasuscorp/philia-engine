@tool
class_name PhiliaGameplayData
extends RefCounted

## Contenu de gameplay auteuré (V6, §19) : gabarits d'entité (stats +
## inventaire de départ), quêtes et dialogues, dans un seul fichier texte
## JSON (.philiagameplay) — même principe que .philiamap (§21.2). Format
## pur donnée, aucune scène Godot, aucun comportement : le jeu qui charge
## ce fichier décide quoi en faire (§20). Édité visuellement par
## editor/philia_gameplay_dock.gd, consommé à l'exécution via
## instantiate_stats()/instantiate_inventory()/get_quest()/get_dialogue().

const FORMAT_VERSION := 1
const EXTENSION := "philiagameplay"

var format_version: int = FORMAT_VERSION
var entity_templates: Dictionary = {}  ## id -> {stats: {...}, inventory: [...], inventory_capacity: int}
var quests: Dictionary = {}            ## id -> dict au format PhiliaQuest.to_dict()
var dialogues: Dictionary = {}         ## id -> dict au format PhiliaDialogue.to_dict()


func to_dict() -> Dictionary:
	return {
		"format_version": format_version,
		"entity_templates": entity_templates,
		"quests": quests,
		"dialogues": dialogues,
	}


static func from_dict(data: Dictionary) -> PhiliaGameplayData:
	var gameplay_data := PhiliaGameplayData.new()
	gameplay_data.format_version = data.get("format_version", FORMAT_VERSION)
	gameplay_data.entity_templates = data.get("entity_templates", {})
	gameplay_data.quests = data.get("quests", {})
	gameplay_data.dialogues = data.get("dialogues", {})
	return gameplay_data


func save(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict(), "\t"))
	return OK


static func load(path: String) -> PhiliaGameplayData:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return from_dict(parsed)


## Instancie un PhiliaStats prêt à l'emploi pour un gabarit donné (utilisé
## au spawn d'une entité, §11/§12). Gabarit inconnu -> stats par défaut.
func instantiate_stats(template_id: String) -> PhiliaStats:
	var tmpl: Dictionary = entity_templates.get(template_id, {})
	return PhiliaStats.new(tmpl.get("stats", {}))


func instantiate_inventory(template_id: String) -> PhiliaInventory:
	var tmpl: Dictionary = entity_templates.get(template_id, {})
	return PhiliaInventory.new(tmpl.get("inventory", []), tmpl.get("inventory_capacity", 0))


func get_quest(quest_id: String) -> PhiliaQuest:
	if not quests.has(quest_id):
		return null
	return PhiliaQuest.from_dict(quests[quest_id])


func get_dialogue(dialogue_id: String) -> PhiliaDialogue:
	if not dialogues.has(dialogue_id):
		return null
	return PhiliaDialogue.from_dict(dialogues[dialogue_id])
