@tool
extends SceneTree

## Assemble le personnage Quaternius (Universal Base Characters) avec la
## bibliothèque d'animations (Universal Animation Library, §14) et une
## AnimationTree/state machine (§15) orchestrée par PhiliaCharacterAnimator.
##
## Les deux packs partagent le même squelette "Universal" (mêmes noms
## d'os) : pas de retargeting Godot nécessaire, la bibliothèque
## d'animations s'attache telle quelle sur le personnage.
##
##   godot --headless --script res://addons/philia_engine/tools/generate_demo_character.gd

const CHARACTER_PATH := "res://characters/quaternius/base_characters/Superhero_Male_FullBody.gltf"
const ANIMATIONS_PATH := "res://characters/quaternius/animations/UAL1_Standard.glb"
const OUTPUT_PATH := "res://characters/quaternius/demo_character.tscn"

## État de state machine -> nom du clip après import (Godot retire le
## suffixe "_Loop" du nom source à l'import, ex: "Idle_Loop" -> "Idle").
const STATE_CLIPS := {
	"Idle": "Idle",
	"Walk": "Walk",
	"Run": "Jog_Fwd",
	"Attack": "Punch_Cross",
	"Death": "Death01",
}


func _initialize() -> void:
	var character_scene: PackedScene = load(CHARACTER_PATH)
	var character := character_scene.instantiate()
	character.name = "PhiliaDemoCharacter"

	var anim_scene: PackedScene = load(ANIMATIONS_PATH)
	var anim_source := anim_scene.instantiate()
	var source_player: AnimationPlayer = anim_source.get_node("AnimationPlayer")
	var library: AnimationLibrary = source_player.get_animation_library("")

	var anim_player := AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	character.add_child(anim_player)
	anim_player.owner = character
	anim_player.add_animation_library("", library)

	var state_machine := AnimationNodeStateMachine.new()
	for state_name in STATE_CLIPS:
		var anim_node := AnimationNodeAnimation.new()
		anim_node.animation = STATE_CLIPS[state_name]
		state_machine.add_node(state_name, anim_node)

	for from_state in STATE_CLIPS:
		for to_state in STATE_CLIPS:
			if from_state == to_state:
				continue
			state_machine.add_transition(from_state, to_state, _make_transition())

	var tree := AnimationTree.new()
	tree.name = "AnimationTree"
	tree.tree_root = state_machine
	character.add_child(tree)
	tree.owner = character
	tree.anim_player = tree.get_path_to(anim_player)
	tree.active = true

	var animator := PhiliaCharacterAnimator.new()
	animator.name = "Animator"
	animator.animation_tree = tree
	character.add_child(animator)
	animator.owner = character

	var packed := PackedScene.new()
	var pack_err := packed.pack(character)
	if pack_err != OK:
		push_error("Échec pack scène: %s" % error_string(pack_err))
		quit(1)
		return

	var save_err := ResourceSaver.save(packed, OUTPUT_PATH)
	if save_err != OK:
		push_error("Échec sauvegarde scène: %s" % error_string(save_err))
		quit(1)
		return

	print("OK: personnage de démo généré (%s)." % OUTPUT_PATH)
	quit()


func _make_transition() -> AnimationNodeStateMachineTransition:
	var t := AnimationNodeStateMachineTransition.new()
	t.xfade_time = 0.25
	t.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_SYNC
	return t
