@tool
class_name PhiliaTriggerArea2D
extends Area2D

## Zone de trigger générique 2D (V6 §7/§19). Republie body_entered/
## body_exited sous un nom neutre (triggered/trigger_ended) — reste un
## Area2D standard, donc body_entered reste aussi directement utilisable.
## Aucun comportement propre : le jeu qui importe la carte décide de ce
## qu'un trigger déclenche (§20). Construit par PhiliaImporter pour toute
## tuile de type "Trigger".

signal triggered(body: Node2D)
signal trigger_ended(body: Node2D)


func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void: triggered.emit(body))
	body_exited.connect(func(body: Node2D) -> void: trigger_ended.emit(body))
