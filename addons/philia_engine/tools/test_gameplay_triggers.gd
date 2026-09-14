@tool
extends SceneTree

## Vérifie les tuiles Spawn/Trigger (V6, §7/§19) sans éditeur : import 2D et
## 3D, forme des nœuds produits, forwarding de signal du trigger.
##
##   godot --headless --script res://addons/philia_engine/tools/test_gameplay_triggers.gd

var _failures := 0


func _initialize() -> void:
	_test_import_2d()
	_test_import_3d()
	await _test_trigger_2d_forwards_signal()
	await _test_trigger_3d_forwards_signal()

	if _failures == 0:
		print("OK: Spawn/Trigger (0 échec).")
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


func _make_map() -> PhiliaMap:
	var map := PhiliaMap.new()
	map.set_tile(0, 0, "Sol")
	map.tiles.append({"x": 1, "y": 0, "type": "Spawn", "rotation": 0, "layer": PhiliaMap.DEFAULT_LAYER, "id": "start"})
	map.tiles.append({"x": 2, "y": 0, "type": "Trigger", "rotation": 0, "layer": PhiliaMap.DEFAULT_LAYER, "id": "door_open"})
	return map


func _test_import_2d() -> void:
	print("Import 2D: Spawn/Trigger")
	var root := PhiliaImporter.build_scene(_make_map())
	var tiles_layer := root.get_node("Tiles/%s" % PhiliaMap.DEFAULT_LAYER)

	var spawn := tiles_layer.get_node("Spawn_1_0")
	_check(spawn is Marker2D, "Spawn -> Marker2D")
	_check(spawn.get_meta("philia_spawn_id") == "start", "id du tile reporté en meta")
	_check(spawn.is_in_group("philia_spawns"), "groupe philia_spawns")
	_check(spawn.get_child_count() == 0, "Spawn sans géométrie ni collision")

	var trigger := tiles_layer.get_node("Trigger_2_0")
	_check(trigger is PhiliaTriggerArea2D, "Trigger -> PhiliaTriggerArea2D")
	_check(trigger.get_meta("philia_trigger_id") == "door_open", "id du tile reporté en meta")
	_check(trigger.is_in_group("philia_triggers"), "groupe philia_triggers")
	_check(trigger.get_child_count() == 1 and trigger.get_child(0) is CollisionShape2D, "Trigger porte une CollisionShape2D")

	root.free()


func _test_import_3d() -> void:
	print("Import 3D: Spawn/Trigger")
	var root := PhiliaImporter3D.build_scene(_make_map())
	var tiles_layer := root.get_node("Tiles/%s" % PhiliaMap.DEFAULT_LAYER)

	var spawn := tiles_layer.get_node("Spawn_1_0")
	_check(spawn is Marker3D, "Spawn -> Marker3D")
	_check(spawn.get_meta("philia_spawn_id") == "start", "id du tile reporté en meta")
	_check(spawn.is_in_group("philia_spawns"), "groupe philia_spawns")
	_check(spawn.get_child_count() == 0, "Spawn sans géométrie ni collision")

	var trigger := tiles_layer.get_node("Trigger_2_0")
	_check(trigger is PhiliaTriggerArea3D, "Trigger -> PhiliaTriggerArea3D")
	_check(trigger.get_meta("philia_trigger_id") == "door_open", "id du tile reporté en meta")
	_check(trigger.is_in_group("philia_triggers"), "groupe philia_triggers")
	_check(trigger.get_child_count() == 1 and trigger.get_child(0) is CollisionShape3D, "Trigger porte une CollisionShape3D")

	root.free()


func _test_trigger_2d_forwards_signal() -> void:
	print("PhiliaTriggerArea2D: forwarding de signal")
	var area := PhiliaTriggerArea2D.new()
	root.add_child(area)
	await process_frame  ## _ready() n'est appelé qu'à la frame suivant l'entrée dans le tree
	var entered := [null]
	var exited := [null]
	area.triggered.connect(func(b): entered[0] = b)
	area.trigger_ended.connect(func(b): exited[0] = b)

	var dummy := Node2D.new()
	area.emit_signal("body_entered", dummy)
	_check(entered[0] == dummy, "triggered émis en forward de body_entered")
	area.emit_signal("body_exited", dummy)
	_check(exited[0] == dummy, "trigger_ended émis en forward de body_exited")

	area.queue_free()
	dummy.queue_free()


func _test_trigger_3d_forwards_signal() -> void:
	print("PhiliaTriggerArea3D: forwarding de signal")
	var area := PhiliaTriggerArea3D.new()
	root.add_child(area)
	await process_frame
	var entered := [null]
	area.triggered.connect(func(b): entered[0] = b)

	var dummy := Node3D.new()
	area.emit_signal("body_entered", dummy)
	_check(entered[0] == dummy, "triggered émis en forward de body_entered")

	area.queue_free()
	dummy.queue_free()
