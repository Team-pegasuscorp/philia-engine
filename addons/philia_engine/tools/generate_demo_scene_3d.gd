@tool
extends SceneTree

## Pendant 3D de generate_demo_scene.gd : même salle 8x6, importée via
## PhiliaImporter3D (GridMap + Node3D/MeshInstance3D) au lieu de
## PhiliaImporter (2D). Carte séparée de maps/example.philiamap : la
## position d'une entité est un point brut, à l'échelle du cell_size de
## l'importeur utilisé (32px en 2D, 1 unité/case en 3D) — pas encore
## d'unité commune aux deux importeurs, donc une carte par échelle.
##
##   godot --headless --script res://addons/philia_engine/tools/generate_demo_scene_3d.gd

const MAP_PATH := "res://maps/example_3d.philiamap"
const SCENE_PATH := "res://scenes/demo_3d.tscn"


func _initialize() -> void:
	var map := _build_example_map()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAP_PATH.get_base_dir()))
	var save_err := map.save(MAP_PATH)
	if save_err != OK:
		push_error("Échec sauvegarde carte: %s" % error_string(save_err))
		quit(1)
		return

	var scene_root := PhiliaImporter3D.build_scene(map)

	var light := DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.rotation_degrees = Vector3(-45, -30, 0)
	scene_root.add_child(light)
	light.owner = scene_root

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(4, 6, 9)
	camera.rotation_degrees = Vector3(-45, 0, 0)
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

	print("OK: carte (%s) et scène (%s) générées." % [MAP_PATH, SCENE_PATH])
	quit()


## Même disposition que generate_demo_scene.gd, en unités de case (1.0)
## plutôt qu'en pixels pour l'entité.
func _build_example_map() -> PhiliaMap:
	var map := PhiliaMap.new()
	map.seed = 42

	for x in range(8):
		map.set_tile(x, 0, "Mur")
		map.set_tile(x, 5, "Mur")
	for y in range(1, 5):
		map.set_tile(0, y, "Mur")
		map.set_tile(7, y, "Mur")
	for x in range(1, 7):
		for y in range(1, 5):
			map.set_tile(x, y, "Sol")

	map.set_tile(4, 5, "Porte")
	map.set_tile(3, 2, "Pilier")
	map.set_tile(5, 3, "Caisse")
	map.set_tile(1, 1, "Rocher")
	map.set_tile(1, 4, "Rocher")

	map.entities.append({
		"entity": "wolf_01",
		"position": [2, 0.5, 3],
		"rotation": 90,
		"state": "idle",
	})

	return map
