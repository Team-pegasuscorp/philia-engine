@tool
extends SceneTree

## Génère un petit monde par bruit (PhiliaWorldGenerator, §9) et l'importe
## en 3D — de quoi voir Montagne/Eau/Forêt/Désert/Plage/Neige/Marais/Plaine
## se raccorder tout seuls selon le relief, plus les rochers/arbres dispersés.
##
##   godot --headless --script res://addons/philia_engine/tools/generate_demo_world_3d.gd

const MAP_PATH := "res://maps/world_example.philiamap"
const SCENE_PATH := "res://scenes/demo_world_3d.tscn"
const SIZE := 32
const SEED := 20260914


func _initialize() -> void:
	var map := PhiliaWorldGenerator.generate(SIZE, SIZE, SEED, {"vegetation_density": 0.12})
	PhiliaPopulationSpawner.spawn(map, {
		"Forêt": {"Deer": 0.15, "Wolf": 0.04, "Rabbit": 0.2},
		"Plaine": {"Rabbit": 0.08},
	}, SEED)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAP_PATH.get_base_dir()))
	var save_err := map.save(MAP_PATH)
	if save_err != OK:
		push_error("Échec sauvegarde carte: %s" % error_string(save_err))
		quit(1)
		return

	var scene_root := PhiliaImporter3D.build_scene(map)

	var light := DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.rotation_degrees = Vector3(-50, -35, 0)
	light.light_energy = 1.1
	scene_root.add_child(light)
	light.owner = scene_root

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(SIZE * 0.5, SIZE * 0.75, SIZE * 1.1)
	camera.look_at_from_position(camera.position, Vector3(SIZE * 0.5, 0, SIZE * 0.5), Vector3.UP)
	camera.current = true
	scene_root.add_child(camera)
	camera.owner = scene_root

	var packed := PackedScene.new()
	var pack_err := packed.pack(scene_root)
	if pack_err != OK:
		push_error("Échec pack scène: %s" % error_string(pack_err))
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_PATH.get_base_dir()))
	var scene_save_err := ResourceSaver.save(packed, SCENE_PATH)
	if scene_save_err != OK:
		push_error("Échec sauvegarde scène: %s" % error_string(scene_save_err))
		quit(1)
		return

	print("OK: monde (%s) et scène (%s) générés (%dx%d, seed=%d)." % [MAP_PATH, SCENE_PATH, SIZE, SIZE, SEED])
	quit()
