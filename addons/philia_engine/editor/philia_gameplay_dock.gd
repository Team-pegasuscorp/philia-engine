@tool
extends Control

## Dock éditeur pour le contenu de gameplay V6 (§19) : gabarits d'entité
## (stats + inventaire de départ), quêtes, dialogues — un seul fichier
## .philiagameplay (PhiliaGameplayData, §21.2) édité via 3 onglets. Toute
## la logique de conversion formulaire <-> dict vit ici ; PhiliaGameplayData
## reste un pur conteneur de données, PhiliaDialogueGraphNode un pur
## widget, aucun des deux ne connaît l'autre (§20).

const DEFAULT_PATH := "res://gameplay/example.philiagameplay"
const DIALOGUE_NODE_SCENE := preload("res://addons/philia_engine/editor/philia_dialogue_graph_node.tscn")

@onready var _path_edit: LineEdit = %PathEdit
@onready var _new_button: Button = %NewButton
@onready var _save_button: Button = %SaveButton
@onready var _load_button: Button = %LoadButton
@onready var _status_label: Label = %StatusLabel

@onready var _template_list: ItemList = %TemplateList
@onready var _template_id_edit: LineEdit = %TemplateIdEdit
@onready var _hp_spin: SpinBox = %HpSpin
@onready var _max_hp_spin: SpinBox = %MaxHpSpin
@onready var _force_spin: SpinBox = %ForceSpin
@onready var _speed_spin: SpinBox = %SpeedSpin
@onready var _perception_spin: SpinBox = %PerceptionSpin
@onready var _inventory_list: ItemList = %InventoryList
@onready var _item_name_edit: LineEdit = %ItemNameEdit
@onready var _item_qty_spin: SpinBox = %ItemQtySpin
@onready var _add_item_button: Button = %AddItemButton
@onready var _remove_item_button: Button = %RemoveItemButton
@onready var _capacity_spin: SpinBox = %CapacitySpin
@onready var _new_template_button: Button = %NewTemplateButton
@onready var _delete_template_button: Button = %DeleteTemplateButton
@onready var _apply_template_button: Button = %ApplyTemplateButton

@onready var _quest_list: ItemList = %QuestList
@onready var _quest_id_edit: LineEdit = %QuestIdEdit
@onready var _objectives_list: ItemList = %ObjectivesList
@onready var _objective_id_edit: LineEdit = %ObjectiveIdEdit
@onready var _objective_required_spin: SpinBox = %ObjectiveRequiredSpin
@onready var _add_objective_button: Button = %AddObjectiveButton
@onready var _remove_objective_button: Button = %RemoveObjectiveButton
@onready var _new_quest_button: Button = %NewQuestButton
@onready var _delete_quest_button: Button = %DeleteQuestButton
@onready var _apply_quest_button: Button = %ApplyQuestButton

@onready var _dialogue_list: ItemList = %DialogueList
@onready var _dialogue_id_edit: LineEdit = %DialogueIdEdit
@onready var _start_node_edit: LineEdit = %StartNodeEdit
@onready var _dialogue_graph: GraphEdit = %DialogueGraph
@onready var _new_dialogue_button: Button = %NewDialogueButton
@onready var _delete_dialogue_button: Button = %DeleteDialogueButton
@onready var _apply_dialogue_button: Button = %ApplyDialogueButton
@onready var _add_node_button: Button = %AddNodeButton

var data := PhiliaGameplayData.new()
var _pending_inventory: Array[Dictionary] = []  ## édité pour le gabarit sélectionné, appliqué au clic sur "Appliquer"
var _pending_objectives: Array[Dictionary] = []
var _node_counter := 0


func _ready() -> void:
	_path_edit.text = DEFAULT_PATH

	_new_button.pressed.connect(_on_new_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_load_button.pressed.connect(_on_load_pressed)

	_template_list.item_selected.connect(_on_template_selected)
	_add_item_button.pressed.connect(_on_add_item_pressed)
	_remove_item_button.pressed.connect(_on_remove_item_pressed)
	_new_template_button.pressed.connect(_on_new_template_pressed)
	_delete_template_button.pressed.connect(_on_delete_template_pressed)
	_apply_template_button.pressed.connect(_on_apply_template_pressed)

	_quest_list.item_selected.connect(_on_quest_selected)
	_add_objective_button.pressed.connect(_on_add_objective_pressed)
	_remove_objective_button.pressed.connect(_on_remove_objective_pressed)
	_new_quest_button.pressed.connect(_on_new_quest_pressed)
	_delete_quest_button.pressed.connect(_on_delete_quest_pressed)
	_apply_quest_button.pressed.connect(_on_apply_quest_pressed)

	_dialogue_list.item_selected.connect(_on_dialogue_selected)
	_new_dialogue_button.pressed.connect(_on_new_dialogue_pressed)
	_delete_dialogue_button.pressed.connect(_on_delete_dialogue_pressed)
	_apply_dialogue_button.pressed.connect(_on_apply_dialogue_pressed)
	_add_node_button.pressed.connect(_on_add_node_pressed)
	_dialogue_graph.connection_request.connect(_on_connection_request)
	_dialogue_graph.disconnection_request.connect(_on_disconnection_request)

	_refresh_all()


func _update_status(message: String = "") -> void:
	var base := "%d gabarit(s), %d quête(s), %d dialogue(s)" % [
		data.entity_templates.size(), data.quests.size(), data.dialogues.size()
	]
	_status_label.text = message if not message.is_empty() else base


func _refresh_all() -> void:
	_refresh_template_list()
	_refresh_quest_list()
	_refresh_dialogue_list()
	_update_status()


# ---------- Fichier ----------

func _on_new_pressed() -> void:
	data = PhiliaGameplayData.new()
	_clear_template_form()
	_clear_quest_form()
	_clear_dialogue_form()
	_refresh_all()


func _on_save_pressed() -> void:
	var path := _path_edit.text.strip_edges()
	if path.is_empty():
		_status_label.text = "Chemin de sauvegarde vide"
		return
	if path.begins_with("res://"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := data.save(path)
	_update_status("Sauvegardé dans %s" % path if err == OK else "Erreur de sauvegarde (%s)" % error_string(err))


func _on_load_pressed() -> void:
	var path := _path_edit.text.strip_edges()
	var loaded := PhiliaGameplayData.load(path)
	if loaded == null:
		_status_label.text = "Impossible de charger %s" % path
		return
	data = loaded
	_clear_template_form()
	_clear_quest_form()
	_clear_dialogue_form()
	_refresh_all()
	_update_status("Chargé depuis %s" % path)


# ---------- Gabarits ----------

func _refresh_template_list() -> void:
	_template_list.clear()
	for template_id in data.entity_templates:
		_template_list.add_item(template_id)


func _on_new_template_pressed() -> void:
	var template_id := _unique_id(data.entity_templates, "gabarit")
	data.entity_templates[template_id] = {"stats": {}, "inventory": [], "inventory_capacity": 0}
	_refresh_template_list()
	_select_item_by_text(_template_list, template_id)
	_on_template_selected(_template_list.get_selected_items()[0])


func _on_delete_template_pressed() -> void:
	var selected := _template_list.get_selected_items()
	if selected.is_empty():
		return
	data.entity_templates.erase(_template_list.get_item_text(selected[0]))
	_refresh_template_list()
	_clear_template_form()


func _on_template_selected(index: int) -> void:
	var template_id := _template_list.get_item_text(index)
	var tmpl: Dictionary = data.entity_templates.get(template_id, {})
	var stats: Dictionary = tmpl.get("stats", {})
	_template_id_edit.text = template_id
	_hp_spin.value = stats.get("hp", PhiliaStats.DEFAULT_STATS["hp"])
	_max_hp_spin.value = stats.get("max_hp", PhiliaStats.DEFAULT_STATS["max_hp"])
	_force_spin.value = stats.get("force", PhiliaStats.DEFAULT_STATS["force"])
	_speed_spin.value = stats.get("speed", PhiliaStats.DEFAULT_STATS["speed"])
	_perception_spin.value = stats.get("perception", PhiliaStats.DEFAULT_STATS["perception"])
	_capacity_spin.value = tmpl.get("inventory_capacity", 0)
	_pending_inventory = []
	for entry in tmpl.get("inventory", []):
		_pending_inventory.append(entry)
	_refresh_inventory_list()


func _clear_template_form() -> void:
	_template_id_edit.text = ""
	_pending_inventory.clear()
	_refresh_inventory_list()


func _refresh_inventory_list() -> void:
	_inventory_list.clear()
	for entry in _pending_inventory:
		_inventory_list.add_item("%s x%d" % [entry.get("item", ""), entry.get("quantity", 1)])


func _on_add_item_pressed() -> void:
	var item_name := _item_name_edit.text.strip_edges()
	if item_name.is_empty():
		return
	_pending_inventory.append({"item": item_name, "quantity": int(_item_qty_spin.value)})
	_item_name_edit.text = ""
	_refresh_inventory_list()


func _on_remove_item_pressed() -> void:
	var selected := _inventory_list.get_selected_items()
	if selected.is_empty():
		return
	_pending_inventory.remove_at(selected[0])
	_refresh_inventory_list()


func _on_apply_template_pressed() -> void:
	var template_id := _template_id_edit.text.strip_edges()
	if template_id.is_empty():
		return
	data.entity_templates[template_id] = {
		"stats": {
			"hp": _hp_spin.value, "max_hp": _max_hp_spin.value, "force": _force_spin.value,
			"speed": _speed_spin.value, "perception": _perception_spin.value,
		},
		"inventory": _pending_inventory.duplicate(true),
		"inventory_capacity": int(_capacity_spin.value),
	}
	_refresh_template_list()
	_select_item_by_text(_template_list, template_id)
	_update_status("Gabarit \"%s\" appliqué" % template_id)


# ---------- Quêtes ----------

func _refresh_quest_list() -> void:
	_quest_list.clear()
	for quest_id in data.quests:
		_quest_list.add_item(quest_id)


func _on_new_quest_pressed() -> void:
	var quest_id := _unique_id(data.quests, "quete")
	data.quests[quest_id] = PhiliaQuest.new(quest_id, []).to_dict()
	_refresh_quest_list()
	_select_item_by_text(_quest_list, quest_id)
	_on_quest_selected(_quest_list.get_selected_items()[0])


func _on_delete_quest_pressed() -> void:
	var selected := _quest_list.get_selected_items()
	if selected.is_empty():
		return
	data.quests.erase(_quest_list.get_item_text(selected[0]))
	_refresh_quest_list()
	_clear_quest_form()


func _on_quest_selected(index: int) -> void:
	var quest_id := _quest_list.get_item_text(index)
	var quest_dict: Dictionary = data.quests.get(quest_id, {})
	_quest_id_edit.text = quest_id
	_pending_objectives = []
	for obj in quest_dict.get("objectives", []):
		_pending_objectives.append(obj)
	_refresh_objectives_list()


func _clear_quest_form() -> void:
	_quest_id_edit.text = ""
	_pending_objectives.clear()
	_refresh_objectives_list()


func _refresh_objectives_list() -> void:
	_objectives_list.clear()
	for obj in _pending_objectives:
		_objectives_list.add_item("%s (0/%d)" % [obj.get("id", ""), obj.get("required", 1)])


func _on_add_objective_pressed() -> void:
	var objective_id := _objective_id_edit.text.strip_edges()
	if objective_id.is_empty():
		return
	_pending_objectives.append({"id": objective_id, "required": int(_objective_required_spin.value), "count": 0})
	_objective_id_edit.text = ""
	_refresh_objectives_list()


func _on_remove_objective_pressed() -> void:
	var selected := _objectives_list.get_selected_items()
	if selected.is_empty():
		return
	_pending_objectives.remove_at(selected[0])
	_refresh_objectives_list()


func _on_apply_quest_pressed() -> void:
	var quest_id := _quest_id_edit.text.strip_edges()
	if quest_id.is_empty():
		return
	data.quests[quest_id] = {
		"id": quest_id,
		"state": PhiliaQuest.State.INACTIVE,
		"objectives": _pending_objectives.duplicate(true),
	}
	_refresh_quest_list()
	_select_item_by_text(_quest_list, quest_id)
	_update_status("Quête \"%s\" appliquée" % quest_id)


# ---------- Dialogues ----------

func _refresh_dialogue_list() -> void:
	_dialogue_list.clear()
	for dialogue_id in data.dialogues:
		_dialogue_list.add_item(dialogue_id)


func _on_new_dialogue_pressed() -> void:
	var dialogue_id := _unique_id(data.dialogues, "dialogue")
	data.dialogues[dialogue_id] = {"id": dialogue_id, "start": "", "nodes": {}}
	_refresh_dialogue_list()
	_select_item_by_text(_dialogue_list, dialogue_id)
	_on_dialogue_selected(_dialogue_list.get_selected_items()[0])


func _on_delete_dialogue_pressed() -> void:
	var selected := _dialogue_list.get_selected_items()
	if selected.is_empty():
		return
	data.dialogues.erase(_dialogue_list.get_item_text(selected[0]))
	_refresh_dialogue_list()
	_clear_dialogue_form()


func _on_dialogue_selected(index: int) -> void:
	var dialogue_id := _dialogue_list.get_item_text(index)
	_dialogue_id_edit.text = dialogue_id
	load_dialogue_into_graph(data.dialogues.get(dialogue_id, {}))


func _clear_dialogue_form() -> void:
	_dialogue_id_edit.text = ""
	_start_node_edit.text = ""
	_clear_dialogue_graph()


func _clear_dialogue_graph() -> void:
	for child in _dialogue_graph.get_children():
		if child is GraphNode:
			child.queue_free()
	_dialogue_graph.clear_connections()
	_node_counter = 0


## Reconstruit le graphe visuel depuis un dict au format
## PhiliaDialogue.to_dict() — inverse de serialize_dialogue_graph().
func load_dialogue_into_graph(dialogue_dict: Dictionary) -> void:
	_clear_dialogue_graph()
	_start_node_edit.text = dialogue_dict.get("start", "")
	var nodes: Dictionary = dialogue_dict.get("nodes", {})
	var offset := Vector2.ZERO
	for node_id in nodes:
		var node_data: Dictionary = nodes[node_id]
		var graph_node := _instantiate_dialogue_node(node_id)
		graph_node.position_offset = offset
		offset += Vector2(300, 0)
		graph_node.set_speaker(node_data.get("speaker", ""))
		graph_node.set_text(node_data.get("text", ""))
		for choice in node_data.get("choices", []):
			graph_node.add_choice(choice.get("text", ""), choice.get("action", ""))
	## Deuxième passe : les connexions, une fois tous les nœuds créés.
	for node_id in nodes:
		var choices: Array = nodes[node_id].get("choices", [])
		for i in choices.size():
			var next_id: String = choices[i].get("next", "")
			if next_id != "" and nodes.has(next_id):
				_dialogue_graph.connect_node(node_id, 3 + i, next_id, 0)


func _instantiate_dialogue_node(node_id: String) -> PhiliaDialogueGraphNode:
	var graph_node: PhiliaDialogueGraphNode = DIALOGUE_NODE_SCENE.instantiate()
	graph_node.name = node_id
	graph_node.title = node_id
	_dialogue_graph.add_child(graph_node)
	return graph_node


func _on_add_node_pressed() -> void:
	var node_id := _next_node_id()
	var graph_node := _instantiate_dialogue_node(node_id)
	graph_node.position_offset = _dialogue_graph.scroll_offset + Vector2(40, 40)


func _next_node_id() -> String:
	_node_counter += 1
	var node_id := "node_%d" % _node_counter
	while _dialogue_graph.has_node(NodePath(node_id)):
		_node_counter += 1
		node_id = "node_%d" % _node_counter
	return node_id


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	## Un seul lien sortant par port (un choix ne mène qu'à un seul nœud) :
	## on retire d'abord toute connexion existante depuis ce port.
	for conn in _dialogue_graph.get_connection_list():
		if conn["from_node"] == from_node and conn["from_port"] == from_port:
			_dialogue_graph.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
	_dialogue_graph.connect_node(from_node, from_port, to_node, to_port)


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_dialogue_graph.disconnect_node(from_node, from_port, to_node, to_port)


## Traduit le graphe visuel courant en dict au format
## PhiliaDialogue.to_dict() — inverse de load_dialogue_into_graph().
func serialize_dialogue_graph() -> Dictionary:
	var nodes := {}
	var connections := _dialogue_graph.get_connection_list()
	for child in _dialogue_graph.get_children():
		if not (child is PhiliaDialogueGraphNode):
			continue
		var graph_node: PhiliaDialogueGraphNode = child
		var choices := []
		for i in graph_node.choice_count():
			var port := graph_node.choice_port(i)
			var next_id := ""
			for conn in connections:
				if conn["from_node"] == graph_node.name and conn["from_port"] == port:
					next_id = String(conn["to_node"])
					break
			choices.append({
				"text": graph_node.get_choice_text(i),
				"action": graph_node.get_choice_action(i),
				"next": next_id,
			})
		nodes[String(graph_node.name)] = {
			"speaker": graph_node.get_speaker(),
			"text": graph_node.get_text(),
			"choices": choices,
		}
	return {"id": _dialogue_id_edit.text.strip_edges(), "start": _start_node_edit.text.strip_edges(), "nodes": nodes}


func _on_apply_dialogue_pressed() -> void:
	var dialogue_id := _dialogue_id_edit.text.strip_edges()
	if dialogue_id.is_empty():
		return
	data.dialogues[dialogue_id] = serialize_dialogue_graph()
	_refresh_dialogue_list()
	_select_item_by_text(_dialogue_list, dialogue_id)
	_update_status("Dialogue \"%s\" appliqué" % dialogue_id)


# ---------- Utilitaires ----------

func _unique_id(existing: Dictionary, prefix: String) -> String:
	var n := 1
	var candidate := "%s_%d" % [prefix, n]
	while existing.has(candidate):
		n += 1
		candidate = "%s_%d" % [prefix, n]
	return candidate


func _select_item_by_text(list: ItemList, text: String) -> void:
	for i in range(list.item_count):
		if list.get_item_text(i) == text:
			list.select(i)
			return
