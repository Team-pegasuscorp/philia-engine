extends CharacterBody3D

## Contrôleur du joueur pour la scène jouable de démo (pas un composant
## réutilisable de l'addon, voir characters/quaternius/demo_character_cycle.gd
## pour le même principe). Déplacement aux flèches, attaque (touche F),
## choix de dialogue (touches 1/2/3) relayés au contrôleur de scène via
## des signaux — ce script ne connaît ni la quête, ni le dialogue, ni
## l'ennemi (§20).

signal attack_requested
signal dialogue_choice_requested(index: int)

const SPEED := 3.0
const GRAVITY := 12.0

@onready var _character: Node3D = $CharacterInstance
@onready var animator: PhiliaCharacterAnimator = $CharacterInstance/Animator

var stats := PhiliaStats.new({"hp": 20.0, "max_hp": 20.0, "force": 4.0})


func _physics_process(delta: float) -> void:
	## Flèches (actions ui_* par défaut) ET ZQSD/WASD en dur — pas de
	## dépendance à un InputMap projet pour cette démo.
	var right := Input.get_action_strength("ui_right") + _key_strength(KEY_D)
	var left := Input.get_action_strength("ui_left") + _key_strength(KEY_A) + _key_strength(KEY_Q)
	var down := Input.get_action_strength("ui_down") + _key_strength(KEY_S)
	var up := Input.get_action_strength("ui_up") + _key_strength(KEY_W) + _key_strength(KEY_Z)
	var input_dir := Vector2(right - left, down - up)
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)
	if direction.length() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		_character.rotation.y = atan2(direction.x, direction.z)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	move_and_slide()
	animator.update_locomotion(Vector2(velocity.x, velocity.z).length())


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_F:
			attack_requested.emit()
		KEY_1:
			dialogue_choice_requested.emit(0)
		KEY_2:
			dialogue_choice_requested.emit(1)
		KEY_3:
			dialogue_choice_requested.emit(2)


func _key_strength(keycode: Key) -> float:
	return 1.0 if Input.is_key_pressed(keycode) else 0.0
