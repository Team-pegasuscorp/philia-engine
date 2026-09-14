@tool
extends SceneTree

## Assemble une scène jouable autour du personnage de démo
## (demo_character.tscn, généré par generate_demo_character.gd) : sol,
## lumière, caméra, et un script qui fait boucler Idle -> Walk -> Run ->
## Attack pour voir l'Animation State Machine tourner en appuyant sur
## Lecture, sans contrôleur de jeu à écrire.
##
##   godot --headless --script res://addons/philia_engine/tools/generate_demo_character_scene_3d.gd

const CHARACTER_SCENE_PATH := "res://characters/quaternius/demo_character.tscn"
const CYCLE_SCRIPT_PATH := "res://characters/quaternius/demo_character_cycle.gd"
const OUTPUT_PATH := "res://scenes/demo_character_3d.tscn"


func _initialize() -> void:
	var root := Node3D.new()
	root.name = "PhiliaDemoCharacterScene"

	var ground := StaticBody3D.new()
	ground.name = "Ground"
	root.add_child(ground)
	ground.owner = root

	var ground_mesh := MeshInstance3D.new()
	ground_mesh.name = "Mesh"
	var plane := BoxMesh.new()
	plane.size = Vector3(10, 0.2, 10)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.35, 0.55, 0.35)
	plane.material = ground_material
	ground_mesh.mesh = plane
	ground_mesh.position = Vector3(0, -0.1, 0)
	ground.add_child(ground_mesh)
	ground_mesh.owner = root

	var ground_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = plane.size
	ground_shape.shape = box_shape
	ground_shape.position = ground_mesh.position
	ground.add_child(ground_shape)
	ground_shape.owner = root

	var light := DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.rotation_degrees = Vector3(-50, -30, 0)
	root.add_child(light)
	light.owner = root

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 1.6, 3.5)
	camera.rotation_degrees = Vector3(-10, 0, 0)
	camera.current = true
	root.add_child(camera)
	camera.owner = root

	var character_scene: PackedScene = load(CHARACTER_SCENE_PATH)
	var character := character_scene.instantiate()
	root.add_child(character)
	character.owner = root

	var cycle := Node.new()
	cycle.name = "DemoCycle"
	cycle.set_script(load(CYCLE_SCRIPT_PATH))
	character.add_child(cycle)
	cycle.owner = root

	var packed := PackedScene.new()
	var pack_err := packed.pack(root)
	if pack_err != OK:
		push_error("Échec pack scène: %s" % error_string(pack_err))
		quit(1)
		return

	var save_err := ResourceSaver.save(packed, OUTPUT_PATH)
	if save_err != OK:
		push_error("Échec sauvegarde scène: %s" % error_string(save_err))
		quit(1)
		return

	print("OK: scène de démo personnage générée (%s)." % OUTPUT_PATH)
	quit()
