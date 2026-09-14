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
	_check(_controller._wolf.behavior.preset == PhiliaBehavior.Preset.PASSIVE, "comportement du loup mort forcé sur PASSIVE")

	## Libère la première scène avant d'en instancier une seconde à la même
	## position : sinon les deux joueurs (capsules superposées) se
	## repoussent violemment au premier tick de physique et faussent tout.
	_controller.free()
	await _test_wolf_chases_and_attacks()
	await _test_equip_weapon_increases_damage()

	if _failures == 0:
		print("OK: scène jouable (0 échec).")
		quit()
	else:
		push_error("ÉCHEC: %d assertion(s) invalide(s)." % _failures)
		quit(1)


## Instance séparée : vérifie que le loup (PhiliaBehavior AGGRESSIVE)
## poursuit le joueur puis l'attaque réellement, sans intervention du
## joueur (pas de touche F, juste le temps qui passe).
func _test_wolf_chases_and_attacks() -> void:
	print("Comportement du loup (PhiliaBehavior AGGRESSIVE)")
	var packed: PackedScene = load(SCENE_PATH)
	var controller: Node3D = packed.instantiate()
	root.add_child(controller)
	await process_frame

	var wolf: Node3D = controller._wolf
	var player: CharacterBody3D = controller._player
	wolf.position = player.position + Vector3(4, 0, 0)  ## à portée de détection, hors portée d'action

	var start_dist := wolf.global_position.distance_to(player.global_position)
	var player_hp_before: float = player.stats.get_stat("hp")
	for i in 200:
		await physics_frame
		if wolf.global_position.distance_to(player.global_position) < start_dist:
			break
	_check(wolf.global_position.distance_to(player.global_position) < start_dist, "le loup se rapproche du joueur sans intervention")

	for i in 200:
		await physics_frame
		if player.stats.get_stat("hp") < player_hp_before:
			break
	_check(player.stats.get_stat("hp") < player_hp_before, "le loup finit par attaquer et blesser le joueur")

	controller.free()


## Instance séparée : vérifie que le joueur démarre avec une épée en
## réserve, et qu'équiper (touche E, PhiliaEquipment) augmente réellement
## les dégâts infligés au loup.
func _test_equip_weapon_increases_damage() -> void:
	print("Équipement : E équipe l'épée et augmente les dégâts")
	var packed: PackedScene = load(SCENE_PATH)
	var controller: Node3D = packed.instantiate()
	root.add_child(controller)
	await process_frame

	var player: CharacterBody3D = controller._player
	var wolf: Node3D = controller._wolf
	wolf.position = player.position  ## à portée d'attaque sans avoir à marcher

	_check(player.inventory.has_item("epee"), "le joueur démarre avec une épée dans l'inventaire")
	_check(not player.inventory.is_equipped("epee"), "l'épée n'est pas équipée par défaut")

	var force_before: float = player.stats.get_stat("force")
	var max_hp: float = wolf.stats.get_stat("max_hp")
	controller._on_player_attack_requested()
	var unarmed_damage: float = max_hp - wolf.stats.get_stat("hp")
	wolf.stats.heal(999.0)  ## remet le loup à plein PV pour une comparaison équitable (pas de dégâts clampés)

	player.equip_toggle_requested.emit()
	_check(player.inventory.is_equipped("epee"), "equip_toggle_requested (touche E) équipe l'épée")
	_check(player.stats.get_stat("force") > force_before, "la force du joueur augmente une fois équipé")

	controller._on_player_attack_requested()
	var armed_damage: float = max_hp - wolf.stats.get_stat("hp")
	_check(armed_damage > unarmed_damage, "l'attaque équipée inflige plus de dégâts que l'attaque à mains nues")

	player.equip_toggle_requested.emit()
	_check(not player.inventory.is_equipped("epee"), "equip_toggle_requested à nouveau déséquipe l'épée")
	_check(player.stats.get_stat("force") == force_before, "la force revient à sa valeur d'origine")

	controller.free()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok - %s" % label)
	else:
		print("  FAIL - %s" % label)
		_failures += 1
