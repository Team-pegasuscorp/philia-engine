@tool
extends Control

@onready var _status_label: Label = %StatusLabel
@onready var _new_map_button: Button = %NewMapButton


func _ready() -> void:
	_new_map_button.pressed.connect(_on_new_map_pressed)
	_status_label.text = "Aucune carte ouverte"


func _on_new_map_pressed() -> void:
	var map := PhiliaMap.new()
	_status_label.text = "Carte vide créée (%d tuiles, %d entités)" % [map.tiles.size(), map.entities.size()]
