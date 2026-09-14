extends Node

## Script de démo (pas un composant réutilisable de l'addon) : fait tourner
## le personnage en boucle à travers Idle -> Walk -> Run -> Attack -> Idle
## pour qu'on puisse voir l'Animation State Machine fonctionner rien qu'en
## appuyant sur Lecture, sans avoir besoin d'un contrôleur de jeu.

const PHASES := [
	{"name": "Idle", "duration": 2.0, "speed": 0.0},
	{"name": "Walk", "duration": 3.0, "speed": 1.0},
	{"name": "Run", "duration": 3.0, "speed": 5.0},
	{"name": "Attack", "duration": 1.2, "speed": 0.0, "attack": true},
]

## Ce nœud est ajouté comme enfant direct du personnage (sibling de
## "Animator") par le générateur de scène — voir tools/generate_demo_character_scene_3d.gd.
@onready var _animator: PhiliaCharacterAnimator = get_parent().get_node("Animator")

var _phase_index := 0
var _phase_timer := 0.0


func _ready() -> void:
	_enter_phase(0)


func _process(delta: float) -> void:
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_enter_phase((_phase_index + 1) % PHASES.size())


func _enter_phase(index: int) -> void:
	_phase_index = index
	var phase: Dictionary = PHASES[index]
	_phase_timer = phase["duration"]
	print("Philia demo character -> ", phase["name"])
	if phase.get("attack", false):
		_animator.trigger_attack()
	else:
		_animator.update_locomotion(phase["speed"])
