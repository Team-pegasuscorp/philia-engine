extends CanvasLayer

## HUD minimal pour la scène jouable de démo (pas un composant réutilisable
## de l'addon) : affiche PV joueur/ennemi, état de la quête, et une boîte
## de dialogue texte. Ne connaît aucun système V6 — le contrôleur de scène
## lui pousse du texte déjà prêt à afficher.

@onready var _player_hp_label: Label = $Margin/VBox/PlayerHpLabel
@onready var _enemy_hp_label: Label = $Margin/VBox/EnemyHpLabel
@onready var _quest_label: Label = $Margin/VBox/QuestLabel
@onready var _weapon_label: Label = $Margin/VBox/WeaponLabel
@onready var _dialogue_panel: PanelContainer = $DialoguePanel
@onready var _speaker_label: Label = $DialoguePanel/VBox/SpeakerLabel
@onready var _text_label: Label = $DialoguePanel/VBox/TextLabel
@onready var _choices_label: Label = $DialoguePanel/VBox/ChoicesLabel


func _ready() -> void:
	_dialogue_panel.hide()


func set_player_hp(hp: float, max_hp: float) -> void:
	_player_hp_label.text = "Joueur PV : %d/%d" % [maxf(hp, 0.0), max_hp]


func set_enemy_hp(hp: float, max_hp: float) -> void:
	_enemy_hp_label.text = "Loup PV : %d/%d" % [maxf(hp, 0.0), max_hp]


func set_quest_text(text: String) -> void:
	_quest_label.text = text


func set_weapon_text(text: String) -> void:
	_weapon_label.text = text


func show_dialogue(speaker: String, text: String, choices: Array) -> void:
	_dialogue_panel.show()
	_speaker_label.text = speaker
	_text_label.text = text
	var lines := PackedStringArray()
	for i in choices.size():
		lines.append("%d) %s" % [i + 1, choices[i].get("text", "")])
	_choices_label.text = "\n".join(lines)


func hide_dialogue() -> void:
	_dialogue_panel.hide()
