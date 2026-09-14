extends Node3D

## Scène jouable minimale démontrant les systèmes V6 branchés ensemble sur
## le personnage Quaternius : un Trigger lance un dialogue (PhiliaDialogue),
## un choix de dialogue démarre une quête (PhiliaQuestLog), tuer le loup
## (PhiliaCombat) progresse l'objectif de la quête. Rien ici n'est un
## composant réutilisable de l'addon — juste la preuve que les systèmes
## indépendants de la V6 s'assemblent sans modification (§20), et que le
## contenu produit par le dock "Philia Gameplay" (gameplay/demo.philiagameplay,
## voir tools/generate_demo_gameplay_data.gd) est directement consommable
## à l'exécution.
##
## Contrôles : flèches pour se déplacer, F pour attaquer le loup à portée,
## touches 1/2/3 pour choisir une réplique de dialogue. Le loup poursuit
## et attaque via PhiliaBehavior (préréglage AGGRESSIVE, configuré dans
## tools/generate_demo_playable_scene.gd) dès qu'il détecte le joueur.

const GAMEPLAY_DATA_PATH := "res://gameplay/demo.philiagameplay"
const ATTACK_RANGE := 2.5

@onready var _player: CharacterBody3D = $Player
@onready var _wolf: Node3D = $Wolf
@onready var _trigger: PhiliaTriggerArea3D = $GuardTrigger
@onready var _hud: CanvasLayer = $HUD

var gameplay_data: PhiliaGameplayData
var quest_log := PhiliaQuestLog.new()
var active_dialogue: PhiliaDialogue = null


func _ready() -> void:
	gameplay_data = PhiliaGameplayData.load(GAMEPLAY_DATA_PATH)
	if gameplay_data == null:
		push_error("Impossible de charger %s — lance d'abord generate_demo_gameplay_data.gd" % GAMEPLAY_DATA_PATH)
		return

	quest_log.add_quest(gameplay_data.get_quest("hunt_wolves"))
	quest_log.quest_completed.connect(_on_quest_completed)

	_wolf.setup(gameplay_data.instantiate_stats("wolf"))
	_wolf.stats.died.connect(_on_wolf_died)
	_wolf.behavior.target = _player
	_wolf.behavior.action_triggered.connect(_on_wolf_action_triggered)

	_trigger.triggered.connect(_on_trigger_entered)
	_player.attack_requested.connect(_on_player_attack_requested)
	_player.dialogue_choice_requested.connect(_on_dialogue_choice_requested)

	_hud.set_player_hp(_player.stats.get_stat("hp"), _player.stats.get_stat("max_hp"))
	_hud.set_enemy_hp(_wolf.stats.get_stat("hp"), _wolf.stats.get_stat("max_hp"))
	_hud.set_quest_text(_quest_status_text())


func _on_trigger_entered(body: Node3D) -> void:
	if body != _player or active_dialogue != null:
		return
	active_dialogue = gameplay_data.get_dialogue("guard_talk")
	active_dialogue.line_shown.connect(_on_dialogue_line_shown)
	active_dialogue.ended.connect(_on_dialogue_ended)
	active_dialogue.start()


func _on_dialogue_line_shown(_node_id: String, speaker: String, text: String, choices: Array) -> void:
	_hud.show_dialogue(speaker, text, choices)


func _on_dialogue_ended() -> void:
	_hud.hide_dialogue()
	active_dialogue = null


func _on_dialogue_choice_requested(index: int) -> void:
	if active_dialogue == null or not active_dialogue.is_active():
		return
	var choices: Array = active_dialogue.nodes[active_dialogue.current_node].get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var action: String = choices[index].get("action", "")
	if action == "quest_start:hunt_wolves":
		quest_log.start_quest("hunt_wolves")
		_hud.set_quest_text(_quest_status_text())
	active_dialogue.choose(index)


func _on_player_attack_requested() -> void:
	if _wolf.stats.is_dead() or _player.global_position.distance_to(_wolf.global_position) > ATTACK_RANGE:
		return
	PhiliaCombat.attack(_player.stats, _wolf.stats, -1.0, _player.animator, _wolf.animator)
	_hud.set_enemy_hp(_wolf.stats.get_stat("hp"), _wolf.stats.get_stat("max_hp"))


func _on_wolf_action_triggered(action: String) -> void:
	if action != "attack" or _player.stats.is_dead():
		return
	PhiliaCombat.attack(_wolf.stats, _player.stats, -1.0, _wolf.animator, _player.animator)
	_hud.set_player_hp(_player.stats.get_stat("hp"), _player.stats.get_stat("max_hp"))


func _on_wolf_died() -> void:
	quest_log.progress("hunt_wolves", "kill_wolf", 1)
	_hud.set_quest_text(_quest_status_text())
	_wolf.behavior.preset = PhiliaBehavior.Preset.PASSIVE  ## un mort ne poursuit/attaque plus


func _on_quest_completed(quest_id: String) -> void:
	_hud.set_quest_text("Quête \"%s\" terminée !" % quest_id)


func _quest_status_text() -> String:
	var quest := quest_log.get_quest("hunt_wolves")
	if quest == null or quest.state == PhiliaQuest.State.INACTIVE:
		return "Quête non commencée — parle au garde"
	var obj: Dictionary = quest.objectives[0]
	return "Chasser le loup : %d/%d" % [obj["count"], obj["required"]]
