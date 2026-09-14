@tool
class_name PhiliaDialogue
extends RefCounted

## Arbre de dialogue générique (V6, §19) : nœuds {speaker, text, next,
## choices}, chaque nœud ou choix menant au nœud suivant (ou fin de
## dialogue si absent/inconnu). Philia ne connaît pas le sens des choix :
## le champ optionnel "action" d'un nœud/choix est simplement relayé tel
## quel dans line_shown, le jeu décide de son interprétation (déclencher
## une quête, donner un objet...) — §20.

signal line_shown(node_id: String, speaker: String, text: String, choices: Array)
signal ended

var id: String
var start_node: String
var nodes: Dictionary = {}  ## node_id -> {speaker, text, next?, choices?: [{text, next, action?}], action?}
var current_node: String = ""


func _init(dialogue_id: String = "", source_nodes: Dictionary = {}, source_start: String = "") -> void:
	id = dialogue_id
	nodes = source_nodes.duplicate(true)
	start_node = source_start


static func from_dict(data: Dictionary) -> PhiliaDialogue:
	return PhiliaDialogue.new(data.get("id", ""), data.get("nodes", {}), data.get("start", ""))


func to_dict() -> Dictionary:
	return {"id": id, "start": start_node, "nodes": nodes}


func start() -> void:
	_advance_to(start_node)


## true si un dialogue est en cours (utile pour bloquer les contrôles du
## joueur côté jeu tant que le dialogue n'est pas terminé).
func is_active() -> bool:
	return current_node != ""


## Avance vers le nœud pointé par choices[choice_index]["next"] du nœud
## courant. Sans effet si aucun dialogue n'est en cours ou que l'index est
## invalide.
func choose(choice_index: int) -> void:
	if not is_active():
		return
	var node: Dictionary = nodes.get(current_node, {})
	var choices: Array = node.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return
	_advance_to(choices[choice_index].get("next", ""))


## Pour un nœud sans choix (ligne simple) : avance vers le "next" du nœud
## lui-même.
func advance() -> void:
	if not is_active():
		return
	var node: Dictionary = nodes.get(current_node, {})
	_advance_to(node.get("next", ""))


func _advance_to(next_id: String) -> void:
	if next_id == "" or not nodes.has(next_id):
		current_node = ""
		ended.emit()
		return
	current_node = next_id
	var node: Dictionary = nodes[current_node]
	line_shown.emit(current_node, node.get("speaker", ""), node.get("text", ""), node.get("choices", []))
