@tool
extends SceneTree

## Vérifie le câblage de scenes/demo_playable.tscn sans clavier ni
## affichage : entrée dans le trigger -> dialogue -> choix qui démarre la
## quête -> combat qui tue le loup -> progression de la quête jusqu'à
## complétion. Appelle directement les méthodes/signaux que joueur/scène
## utiliseraient (pas de simulation d'input, headless).
##
##   godot --headless --script res://addons/philia_engine/tools/test_demo_playable_scene.gd

const SCENE_PATH := "res://scenes/demo_playable.tscn"

var _failures := 0
var _controller: Node3D


func _initialize() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	_controller = packed.instantiate()
	root.add_child(_controller)
	await process_frame

	_check(_controller.gameplay_data != null, "gameplay/demo.philiagameplay chargé au démarrage")
	_check(_controller.quest_log.get_quest("hunt_wolves").state == PhiliaQuest.State.INACTIVE, "quête inactive avant le dialogue")

	## Le joueur entre dans le trigger du garde.
	_controller._on_trigger_entered(_controller._player)
	_check(_controller.active_dialogue != null and _controller.active_dialogue.is_active(), "dialogue démarré par le trigger")
	_check(_controller._hud._dialogue_panel.visible, "panneau de dialogue affiché")

	## Choix 0 : "Je m'en occupe" -> démarre la quête.
	_controller._on_dialogue_choice_requested(0)
	_check(_controller.quest_log.get_quest("hunt_wolves").state == PhiliaQuest.State.ACTIVE, "quête démarrée par le choix de dialogue")
	_check(_controller.active_dialogue.current_node == "accept", "dialogue avance vers le nœud accept")

	## Fin du dialogue (nœud "accept" n'a pas de choix -> advance()).
	_controller.active_dialogue.advance()
	_check(_controller.active_dialogue == null, "dialogue terminé après la dernière ligne")
	_check(not _controller._hud._dialogue_panel.visible, "panneau de dialogue masqué à la fin")

	## Combat : le joueur attaque le loup jusqu'à sa mort.
	_controller._wolf.position = _controller._player.position  ## se placer à portée pour le test
	var quest_completed := [false]
	_controller.quest_log.quest_completed.connect(func(qid): quest_completed[0] = (qid == "hunt_wolves"))
	for i in 10:
		if _controller._wolf.stats.is_dead():
			break
		_controller._on_player_attack_requested()
	_check(_controller._wolf.stats.is_dead(), "le loup meurt après suffisamment d'attaques")
	_check(quest_completed[0], "la mort du loup complète la quête hunt_wolves")

	if _failures == 0:
		print("OK: scène jouable (0 échec).")
		quit()
	else:
		push_error("ÉCHEC: %d assertion(s) invalide(s)." % _failures)
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok - %s" % label)
	else:
		print("  FAIL - %s" % label)
		_failures += 1
