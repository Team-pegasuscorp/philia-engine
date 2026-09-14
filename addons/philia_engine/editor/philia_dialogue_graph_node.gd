@tool
class_name PhiliaDialogueGraphNode
extends GraphNode

## Un nœud du graphe de dialogue (éditeur V6, §19) : une réplique
## (speaker/text) et une liste de choix, chacun avec son propre port de
## sortie (row du GraphNode). Le port d'entrée (row 0) reçoit les
## connexions des choix d'autres nœuds qui mènent ici. Cette classe ne
## connaît rien de PhiliaDialogue ni du GraphEdit qui la contient —
## philia_gameplay_dock.gd traduit le graphe (nœuds + connexions) en dict
## au format PhiliaDialogue.to_dict(), et c'est aussi lui qui réindexe les
## connexions du GraphEdit quand choice_remove_requested est émis (retirer
## une row du milieu décale les ports des rows suivantes — cette classe ne
## connaît pas les connexions externes pour le faire elle-même) (§20).

signal choice_remove_requested(index: int)

const FIRST_CHOICE_ROW := 3  ## SpeakerRow(0), TextEdit(1), ChoiceControlsRow(2), choix à partir de 3

@onready var _speaker_edit: LineEdit = %SpeakerEdit
@onready var _text_edit: TextEdit = %TextEdit
@onready var _add_choice_button: Button = %AddChoiceButton

var _choice_rows: Array[HBoxContainer] = []


func _ready() -> void:
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
	_add_choice_button.pressed.connect(add_choice)


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
	var remove_button := Button.new()
	remove_button.text = "×"
	remove_button.tooltip_text = "Retirer ce choix"
	remove_button.pressed.connect(func() -> void: choice_remove_requested.emit(_choice_rows.find(row)))
	row.add_child(text_edit)
	row.add_child(action_edit)
	row.add_child(remove_button)
	add_child(row)
	_choice_rows.append(row)
	set_slot(choice_port(_choice_rows.size() - 1), false, 0, Color.WHITE, true, 0, Color(0.3, 0.8, 0.4))


## Retire le choix à `index`, où qu'il soit dans la liste : les rows
## suivantes se décalent d'un cran (remove_child() réindexe les children
## immédiatement, contrairement à queue_free() seul) et leurs slots sont
## réappliqués sur leur nouvelle position. Ne touche à aucune connexion du
## GraphEdit — c'est à l'appelant (philia_gameplay_dock.gd) de sauvegarder
## puis réindexer les connexions existantes avant/après cet appel.
func remove_choice_at(index: int) -> void:
	if index < 0 or index >= _choice_rows.size():
		return
	var row := _choice_rows[index]
	remove_child(row)
	row.queue_free()
	_choice_rows.remove_at(index)
	for i in range(index, _choice_rows.size()):
		set_slot(choice_port(i), false, 0, Color.WHITE, true, 0, Color(0.3, 0.8, 0.4))
