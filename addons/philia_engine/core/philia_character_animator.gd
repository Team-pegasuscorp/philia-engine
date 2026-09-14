@tool
class_name PhiliaCharacterAnimator
extends Node

## Oriente les animations d'un personnage selon son état, sans dupliquer ce
## que fait déjà l'AnimationTree de Godot (§15/§20) : ce nœud choisit
## uniquement QUEL état traverser (travel()) sur une state machine
## existante — tout le blending/les transitions/la liste d'animations
## restent définis dans l'AnimationTree lui-même (voir
## tools/generate_demo_character.gd pour un exemple d'assemblage complet).
##
## Seuils de vitesse repris de l'exemple du concept (§15) :
##   velocity = 0 -> Idle
##   velocity = 2 -> Walk
##   velocity = 6 -> Run
##
## Les noms d'état sont remplaçables (locomotion_states/attack_state/
## death_state) pour s'adapter à une state machine différente de celle du
## personnage de démo.

@export var animation_tree: AnimationTree
@export var playback_path: StringName = "parameters/playback"

@export var walk_speed_threshold: float = 0.5
@export var run_speed_threshold: float = 4.0

@export var locomotion_states: Dictionary = {
	"idle": "Idle",
	"walk": "Walk",
	"run": "Run",
}
@export var attack_state: String = "Attack"
@export var death_state: String = "Death"

var is_dead: bool = false


## À appeler chaque frame (ou sur changement de vélocité) avec la vitesse
## courante du personnage : choisit Idle/Walk/Run selon les seuils.
func update_locomotion(speed: float) -> void:
	if is_dead:
		return
	var key := "idle"
	if speed >= run_speed_threshold:
		key = "run"
	elif speed >= walk_speed_threshold:
		key = "walk"
	_travel(locomotion_states.get(key, "Idle"))


func trigger_attack() -> void:
	if not is_dead:
		_travel(attack_state)


## HP = 0 -> Death (§15). État absorbant : plus aucun travel() n'agit
## ensuite tant que is_dead n'est pas remis à false manuellement.
func die() -> void:
	is_dead = true
	_travel(death_state)


func _travel(state_name: String) -> void:
	if animation_tree == null:
		return
	var playback: AnimationNodeStateMachinePlayback = animation_tree.get(playback_path)
	if playback:
		playback.travel(state_name)
