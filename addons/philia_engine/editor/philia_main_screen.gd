@tool
extends Control

## Écran principal dédié "Philia" (EditorPlugin main screen, comme les
## onglets 2D/3D/Script de Godot) : regroupe l'éditeur de niveaux et le
## dock Philia Gameplay au même endroit, à la place d'être dispersés en
## docks au fond de l'éditeur Godot générique. plugin.gd bascule sa
## visibilité via _make_visible() quand l'onglet "Philia" est
## sélectionné/quitté — les deux éditeurs restent des Control classiques
## (philia_dock.tscn / philia_gameplay_dock.tscn), juste présentés
## autrement.

signal import_requested(map: PhiliaMap)

@onready var _level_editor: Control = %Niveaux


func _ready() -> void:
	_level_editor.import_requested.connect(func(map: PhiliaMap) -> void: import_requested.emit(map))


func set_level_editor_status(text: String) -> void:
	_level_editor.set_status(text)
