@tool
class_name PhiliaTriggerArea3D
extends Area3D

## Pendant 3D de PhiliaTriggerArea2D — voir ce fichier pour le rationnel.

signal triggered(body: Node3D)
signal trigger_ended(body: Node3D)


func _ready() -> void:
	body_entered.connect(func(body: Node3D) -> void: triggered.emit(body))
	body_exited.connect(func(body: Node3D) -> void: trigger_ended.emit(body))
