@tool
extends SceneTree

## Génère une carte d'exemple et l'importe dans une scène jouable, pour
## vérifier le pipeline complet sans passer par l'éditeur : construire un
## PhiliaMap -> sauvegarder .philiamap -> importer -> scène lançable (F5).
## Sert aussi de test que le format est pilotable par un agent (§21.3).
##
##   godot --headless --script res://addons/philia_engine/tools/generate_demo_scene.gd

const MAP_PATH := "res://maps/example.philiamap"
const SCENE_PATH := "res://scenes/demo.tscn"


func _initialize() -> void:
	var map := _build_example_map()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAP_PATH.get_base_dir()))
	var save_err := map.save(MAP_PATH)
	if save_err != OK:
		push_error("Échec sauvegarde carte: %s" % error_string(save_err))
		quit(1)
		return

	var scene_root := PhiliaImporter.build_scene(map)

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(8, 6) * 32 * 0.5 # centre approximatif de la salle
	camera.enabled = true
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


## Petite salle 8x6 avec murs autotilés, porte, pilier, caisse et une
## entité — de quoi voir tous les systèmes (calques, autotiling, terrain
## Godot, collisions, import) en une seule scène.
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

	map.entities.append({
		"entity": "wolf_01",
		"position": [2 * 32, 0, 3 * 32],
		"rotation": 90,
		"state": "idle",
	})

	return map
