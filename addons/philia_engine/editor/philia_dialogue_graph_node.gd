@tool
class_name PhiliaDialogueGraphNode
extends GraphNode

## Un nœud du graphe de dialogue (éditeur V6, §19) : une réplique
## (speaker/text) et une liste de choix, chacun avec son propre port de
## sortie (row du GraphNode). Le port d'entrée (row 0) reçoit les
## connexions des choix d'autres nœuds qui mènent ici. Cette classe ne
## connaît rien de PhiliaDialogue — philia_gameplay_dock.gd traduit le
## graphe (nœuds + connexions du GraphEdit) en dict au format
## PhiliaDialogue.to_dict() (§20).
##
## Limite assumée pour rester simple : un choix ne peut être retiré que
## par la fin (le dernier ajouté), jamais au milieu — Godot ne réindexe
## pas les connexions existantes d'un GraphEdit quand une row change de
## position, retirer un choix du milieu casserait silencieusement les
## connexions des choix suivants.

const FIRST_CHOICE_ROW := 3  ## SpeakerRow(0), TextEdit(1), ChoiceControlsRow(2), choix à partir de 3

@onready var _speaker_edit: LineEdit = %SpeakerEdit
@onready var _text_edit: TextEdit = %TextEdit
@onready var _add_choice_button: Button = %AddChoiceButton
@onready var _remove_choice_button: Button = %RemoveChoiceButton

var _choice_rows: Array[HBoxContainer] = []


func _ready() -> void:
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
	_add_choice_button.pressed.connect(add_choice)
	_remove_choice_button.pressed.connect(remove_last_choice)


func get_speaker() -> String:
	return _speaker_edit.text


func set_speaker(value: String) -> void:
	_speaker_edit.text = value


func get_text() -> String:
	return _text_edit.text


func set_text(value: String) -> void:
	_text_edit.text = value


func choice_count() -> int:
	return _choice_rows.size()


func get_choice_text(index: int) -> String:
	return (_choice_rows[index].get_child(0) as LineEdit).text


func get_choice_action(index: int) -> String:
	return (_choice_rows[index].get_child(1) as LineEdit).text


## Row (= port de sortie GraphEdit) d'un choix donné, à passer en
## from_port à GraphEdit.connect_node()/get_connection_list().
func choice_port(index: int) -> int:
	return FIRST_CHOICE_ROW + index


func add_choice(text: String = "", action: String = "") -> void:
	var row := HBoxContainer.new()
	var text_edit := LineEdit.new()
	text_edit.placeholder_text = "Texte du choix"
	text_edit.text = text
	text_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	var action_edit := LineEdit.new()
	action_edit.placeholder_text = "action (optionnel)"
	action_edit.text = action
	action_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(text_edit)
	row.add_child(action_edit)
	add_child(row)
	_choice_rows.append(row)
	set_slot(choice_port(_choice_rows.size() - 1), false, 0, Color.WHITE, true, 0, Color(0.3, 0.8, 0.4))


## Retire uniquement le dernier choix (voir note de tête de fichier).
func remove_last_choice() -> void:
	if _choice_rows.is_empty():
		return
	var row := _choice_rows.pop_back()
	set_slot(FIRST_CHOICE_ROW + _choice_rows.size(), false, 0, Color.WHITE, false, 0, Color.WHITE)
	row.queue_free()
