@tool
extends SceneTree

## Vérifie PhiliaBehavior (V6, §11) sans éditeur : presets PASSIVE/WANDER/
## AGGRESSIVE/FLEE, configure() depuis un dict, bascule automatique en
## fuite sous flee_hp_ratio.
##
##   godot --headless --script res://addons/philia_engine/tools/test_gameplay_behavior.gd

var _failures := 0


func _initialize() -> void:
	await _test_passive_does_not_move()
	await _test_wander_moves_within_radius()
	await _test_aggressive_chases_then_triggers_action()
	await _test_flee_moves_away()
	await _test_low_hp_forces_flee_even_if_aggressive()
	_test_configure_from_dict()

	if _failures == 0:
		print("OK: PhiliaBehavior (0 échec).")
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


func _make_body(behavior_setup: Callable) -> Node3D:
	var body := Node3D.new()
	root.add_child(body)
	var behavior := PhiliaBehavior.new()
	behavior_setup.call(behavior)
	body.add_child(behavior)
	return body


func _test_passive_does_not_move() -> void:
	print("PhiliaBehavior: PASSIVE ne bouge pas")
	var body := _make_body(func(b): b.preset = PhiliaBehavior.Preset.PASSIVE)
	var start := body.global_position
	for i in 10:
		await physics_frame
	_check(body.global_position == start, "position inchangée")
	body.free()


func _test_wander_moves_within_radius() -> void:
	print("PhiliaBehavior: WANDER se déplace autour de l'origine")
	var body := _make_body(func(b):
		b.preset = PhiliaBehavior.Preset.WANDER
		b.wander_radius = 3.0
		b.move_speed = 5.0
	)
	var start := body.global_position
	var moved := false
	for i in 30:
		await physics_frame
		if body.global_position.distance_to(start) > 0.05:
			moved = true
	_check(moved, "la position a changé au fil du temps")
	_check(body.global_position.distance_to(start) <= 3.5, "reste dans un rayon raisonnable autour de l'origine")
	body.free()


func _test_aggressive_chases_then_triggers_action() -> void:
	print("PhiliaBehavior: AGGRESSIVE poursuit puis déclenche l'action")
	var target := Node3D.new()
	target.position = Vector3(3, 0, 0)
	root.add_child(target)

	var triggered := []
	var body := _make_body(func(b):
		b.preset = PhiliaBehavior.Preset.AGGRESSIVE
		b.detection_radius = 10.0
		b.action_radius = 1.0
		b.move_speed = 10.0
		b.action_name = "attack"
		b.target = target
	)
	(body.get_child(0) as PhiliaBehavior).action_triggered.connect(func(a): triggered.append(a))

	for i in 30:
		await physics_frame
	_check(body.global_position.distance_to(target.global_position) <= 1.0, "se rapproche jusqu'à action_radius")
	_check(triggered.has("attack"), "action_triggered(\"attack\") émis une fois à portée")

	body.free()
	target.free()


func _test_flee_moves_away() -> void:
	print("PhiliaBehavior: FLEE s'éloigne de la cible")
	var target := Node3D.new()
	target.position = Vector3(1, 0, 0)
	root.add_child(target)

	var body := _make_body(func(b):
		b.preset = PhiliaBehavior.Preset.FLEE
		b.detection_radius = 10.0
		b.wander_radius = 5.0
		b.move_speed = 5.0
		b.target = target
	)
	var start_dist := body.global_position.distance_to(target.global_position)
	for i in 20:
		await physics_frame
	_check(body.global_position.distance_to(target.global_position) > start_dist, "distance à la cible augmente")

	body.free()
	target.free()


func _test_low_hp_forces_flee_even_if_aggressive() -> void:
	print("PhiliaBehavior: hp bas force la fuite même en préréglage AGGRESSIVE")
	var target := Node3D.new()
	target.position = Vector3(1, 0, 0)
	root.add_child(target)

	var stats := PhiliaStats.new({"hp": 1.0, "max_hp": 10.0})  ## 10% -> sous flee_hp_ratio (0.3) par défaut
	var body := _make_body(func(b):
		b.preset = PhiliaBehavior.Preset.AGGRESSIVE
		b.detection_radius = 10.0
		b.action_radius = 0.5
		b.move_speed = 5.0
		b.target = target
		b.stats = stats
	)
	var start_dist := body.global_position.distance_to(target.global_position)
	for i in 20:
		await physics_frame
	_check(body.global_position.distance_to(target.global_position) > start_dist, "s'éloigne au lieu de charger malgré AGGRESSIVE")

	body.free()
	target.free()


func _test_configure_from_dict() -> void:
	print("PhiliaBehavior: configure() depuis un dict")
	var behavior := PhiliaBehavior.new()
	behavior.configure({
		"preset": "aggressive", "move_speed": 4.0, "detection_radius": 8.0,
		"action_radius": 2.0, "action": "bite", "action_cooldown": 0.5,
	})
	_check(behavior.preset == PhiliaBehavior.Preset.AGGRESSIVE, "preset lu depuis le nom")
	_check(behavior.move_speed == 4.0 and behavior.detection_radius == 8.0, "champs numériques lus")
	_check(behavior.action_name == "bite", "nom d'action lu")
	behavior.free()
