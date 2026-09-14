@tool
extends SceneTree

## Assemble scenes/demo_playable.tscn : sol, joueur (personnage Quaternius
## + PhiliaStats + déplacement), loup (même modèle en guise d'ennemi +
## PhiliaStats), un PhiliaTriggerArea3D qui lance un dialogue, et un HUD
## texte. scenes/demo_playable/controller.gd charge gameplay/demo.philiagameplay
## (généré par generate_demo_gameplay_data.gd, à lancer avant celui-ci) et
## relie triggers/dialogue/quête/combat entre eux au runtime.
##
##   godot --headless --script res://addons/philia_engine/tools/generate_demo_playable_scene.gd

const CHARACTER_SCENE_PATH := "res://characters/quaternius/demo_character.tscn"
const CONTROLLER_SCRIPT_PATH := "res://scenes/demo_playable/controller.gd"
const PLAYER_SCRIPT_PATH := "res://scenes/demo_playable/player.gd"
const ENEMY_SCRIPT_PATH := "res://scenes/demo_playable/enemy.gd"
const HUD_SCRIPT_PATH := "res://scenes/demo_playable/hud.gd"
const OUTPUT_PATH := "res://scenes/demo_playable.tscn"
const GROUND_SIZE := 40.0
const GROUND_MATERIAL_PATH := "res://addons/philia_engine/assets/materials/grass_field.tres"
const GROUND_UV_TILES := 16.0  ## nombre de répétitions de la texture sur toute la largeur du sol


func _initialize() -> void:
	var root := Node3D.new()
	root.name = "PhiliaPlayableDemo"
	root.set_script(load(CONTROLLER_SCRIPT_PATH))

	_add_ground(root)
	_add_light(root)
	_add_player(root)
	_add_wolf(root)
	_add_trigger(root)
	_add_hud(root)

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

	print("OK: scène jouable (%s) générée." % OUTPUT_PATH)
	quit()


func _add_ground(root: Node3D) -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	root.add_child(ground)
	ground.owner = root

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var box := BoxMesh.new()
	box.size = Vector3(GROUND_SIZE, 0.2, GROUND_SIZE)
	## Texture seamless (albedo/normal/ORM/relief) générée par tile-gen,
	## voir tools/generate_grass_field_material.gd. uv1_scale répète la
	## tuile sur toute la surface plutôt que de l'étirer une seule fois.
	var philia_material: PhiliaMaterial = load(GROUND_MATERIAL_PATH)
	var material := PhiliaImporter3D.build_standard_material(philia_material)
	material.uv1_scale = Vector3(GROUND_UV_TILES, GROUND_UV_TILES, 1.0)
	material.heightmap_scale = 0.1
	box.material = material
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(0, -0.1, 0)
	ground.add_child(mesh_instance)
	mesh_instance.owner = root

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box.size
	shape.shape = box_shape
	shape.position = mesh_instance.position
	ground.add_child(shape)
	shape.owner = root


func _add_light(root: Node3D) -> void:
	var light := DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.rotation_degrees = Vector3(-50, -30, 0)
	root.add_child(light)
	light.owner = root


func _instantiate_character(root: Node3D, parent: Node3D) -> Node3D:
	var character_scene: PackedScene = load(CHARACTER_SCENE_PATH)
	var character := character_scene.instantiate()
	character.name = "CharacterInstance"
	parent.add_child(character)
	character.owner = root
	return character


func _add_player(root: Node3D) -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0, 8)
	player.set_script(load(PLAYER_SCRIPT_PATH))
	root.add_child(player)
	player.owner = root

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0, 0.9, 0)
	player.add_child(shape)
	shape.owner = root

	_instantiate_character(root, player)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 2.6, 4.5)
	camera.rotation_degrees = Vector3(-24, 0, 0)
	camera.current = true
	player.add_child(camera)
	camera.owner = root


func _add_wolf(root: Node3D) -> void:
	var wolf := Node3D.new()
	wolf.name = "Wolf"
	wolf.position = Vector3(0, 0, -1)  ## juste après le trigger (z=3) pour être visible tout de suite après le dialogue
	wolf.set_script(load(ENEMY_SCRIPT_PATH))
	root.add_child(wolf)
	wolf.owner = root
	_instantiate_character(root, wolf)

	var behavior := PhiliaBehavior.new()
	behavior.name = "Behavior"
	behavior.preset = PhiliaBehavior.Preset.AGGRESSIVE
	behavior.move_speed = 1.2
	behavior.detection_radius = 6.0
	behavior.action_radius = 1.5
	behavior.action_name = "attack"
	behavior.action_cooldown = 1.2
	behavior.flee_hp_ratio = 0.25
	wolf.add_child(behavior)
	behavior.owner = root


func _add_trigger(root: Node3D) -> void:
	var trigger := PhiliaTriggerArea3D.new()
	trigger.name = "GuardTrigger"
	trigger.position = Vector3(0, 1, 3)
	root.add_child(trigger)
	trigger.owner = root

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 2, 2)
	shape.shape = box
	trigger.add_child(shape)
	shape.owner = root


func _add_hud(root: Node3D) -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(load(HUD_SCRIPT_PATH))
	root.add_child(hud)
	hud.owner = root

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	hud.add_child(margin)
	margin.owner = root

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	margin.add_child(vbox)
	vbox.owner = root

	for entry in [
		["PlayerHpLabel", "Joueur PV : --"],
		["EnemyHpLabel", "Loup PV : --"],
		["QuestLabel", "Quête non commencée"],
		["InstructionsLabel", "Flèches : déplacer — F : attaquer — 1/2/3 : choix de dialogue"],
	]:
		var label := Label.new()
		label.name = entry[0]
		label.text = entry[1]
		vbox.add_child(label)
		label.owner = root

	var dialogue_panel := PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.offset_left = 16
	dialogue_panel.offset_right = -16
	dialogue_panel.offset_top = -140
	dialogue_panel.offset_bottom = -16
	hud.add_child(dialogue_panel)
	dialogue_panel.owner = root

	var d_vbox := VBoxContainer.new()
	d_vbox.name = "VBox"
	dialogue_panel.add_child(d_vbox)
	d_vbox.owner = root

	var speaker_label := Label.new()
	speaker_label.name = "SpeakerLabel"
	d_vbox.add_child(speaker_label)
	speaker_label.owner = root

	var text_label := Label.new()
	text_label.name = "TextLabel"
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	d_vbox.add_child(text_label)
	text_label.owner = root

	var choices_label := Label.new()
	choices_label.name = "ChoicesLabel"
	d_vbox.add_child(choices_label)
	choices_label.owner = root
