@tool
class_name PhiliaBehavior
extends Node

## Pilote le déplacement et le déclenchement d'action d'une entité selon
## un comportement générique (§11 du concept : passif/neutre/agressif/
## fuite). Deux façons de le configurer, au choix :
##   - un préréglage (preset) tout fait ;
##   - directement une zone (detection_radius/action_radius) + une action
##     (action_name), sans coder de comportement dédié.
## Philia décide QUAND déclencher (zone + cooldown), jamais CE QUE
## l'action fait : action_triggered relaie juste le nom, le jeu
## l'interprète (attaquer, parler, fuir concrètement...) — §20.
##
## S'attache comme enfant du nœud à piloter (Node3D ou CharacterBody3D) et
## déplace directement sa position — pas de physique/collision gérée ici,
## volontairement simple ; un jeu qui a besoin de move_and_slide() peut
## lire target/effective_preset et piloter lui-même son CharacterBody3D à
## la place de laisser ce nœud bouger la position (voir _physics_process).

signal action_triggered(action: String)

enum Preset { PASSIVE, WANDER, AGGRESSIVE, FLEE }

const PRESET_NAMES := {
	"passive": Preset.PASSIVE, "wander": Preset.WANDER,
	"aggressive": Preset.AGGRESSIVE, "flee": Preset.FLEE,
}

@export var preset: Preset = Preset.PASSIVE
@export var move_speed: float = 1.5
@export var detection_radius: float = 6.0  ## rayon de détection de la cible (AGGRESSIVE/FLEE)
@export var action_radius: float = 1.5     ## distance sous laquelle l'action se déclenche (AGGRESSIVE)
@export var action_name: String = "attack" ## nom relayé tel quel par action_triggered
@export var action_cooldown: float = 1.0
@export var wander_radius: float = 4.0
@export var flee_hp_ratio: float = 0.3     ## hp/max_hp sous ce seuil -> fuite forcée si `stats` est fourni

var target: Node3D = null    ## cible optionnelle (souvent le joueur), assignée par le jeu
var stats: PhiliaStats = null  ## optionnel : bascule automatiquement en fuite sous flee_hp_ratio

var _origin: Vector3
var _wander_target: Vector3
var _action_timer := 0.0


## Configure ce nœud depuis un dictionnaire (ex: le champ "behavior" d'un
## gabarit PhiliaGameplayData) plutôt qu'en code — préréglage par nom
## ("passive"/"wander"/"aggressive"/"flee"), le reste optionnel.
func configure(cfg: Dictionary) -> void:
	preset = PRESET_NAMES.get(String(cfg.get("preset", "passive")).to_lower(), Preset.PASSIVE)
	move_speed = cfg.get("move_speed", move_speed)
	detection_radius = cfg.get("detection_radius", detection_radius)
	action_radius = cfg.get("action_radius", action_radius)
	action_name = cfg.get("action", action_name)
	action_cooldown = cfg.get("action_cooldown", action_cooldown)
	wander_radius = cfg.get("wander_radius", wander_radius)
	flee_hp_ratio = cfg.get("flee_hp_ratio", flee_hp_ratio)


func _ready() -> void:
	var body := get_parent() as Node3D
	if body:
		_origin = body.global_position
		_wander_target = _origin


func _physics_process(delta: float) -> void:
	var body := get_parent() as Node3D
	if body == null:
		return
	_action_timer = maxf(_action_timer - delta, 0.0)

	var effective_preset := preset
	if stats != null and stats.get_stat("max_hp") > 0.0 \
			and stats.get_stat("hp") / stats.get_stat("max_hp") <= flee_hp_ratio:
		effective_preset = Preset.FLEE

	match effective_preset:
		Preset.WANDER:
			_process_wander(body, delta)
		Preset.AGGRESSIVE:
			_process_aggressive(body, delta)
		Preset.FLEE:
			_process_flee(body, delta)
		_:
			pass  ## PASSIVE : ne fait rien


func _process_wander(body: Node3D, delta: float) -> void:
	if body.global_position.distance_to(_wander_target) < 0.3:
		_wander_target = _origin + Vector3(
			randf_range(-wander_radius, wander_radius), 0.0, randf_range(-wander_radius, wander_radius)
		)
	_move_toward(body, _wander_target, delta)


func _process_aggressive(body: Node3D, delta: float) -> void:
	if target == null:
		return
	var dist := body.global_position.distance_to(target.global_position)
	if dist > detection_radius:
		return
	if dist <= action_radius:
		if _action_timer <= 0.0:
			_action_timer = action_cooldown
			action_triggered.emit(action_name)
	else:
		_move_toward(body, target.global_position, delta)


func _process_flee(body: Node3D, delta: float) -> void:
	if target == null:
		return
	var away := body.global_position - target.global_position
	if body.global_position.distance_to(target.global_position) >= detection_radius or away.length() < 0.01:
		return
	_move_toward(body, body.global_position + away.normalized() * wander_radius, delta)


func _move_toward(body: Node3D, destination: Vector3, delta: float) -> void:
	var to_dest := destination - body.global_position
	to_dest.y = 0.0
	if to_dest.length() < 0.05:
		return
	var step := to_dest.normalized() * move_speed * delta
	if step.length() > to_dest.length():
		step = to_dest
	body.global_position += step
	body.rotation.y = atan2(to_dest.x, to_dest.z)
