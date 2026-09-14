@tool
extends EditorPlugin

## Écran principal "Philia" (onglet en haut, comme 2D/3D/Script) plutôt
## que des docks dispersés au fond de l'éditeur générique — voir
## editor/philia_main_screen.gd pour le détail.

const PhiliaMainScreen := preload("res://addons/philia_engine/editor/philia_main_screen.tscn")
const PLUGIN_ICON := preload("res://addons/philia_engine/icons/plugin_icon.svg")

var _main_screen: Control


func _enter_tree() -> void:
	_main_screen = PhiliaMainScreen.instantiate()
	_main_screen.import_requested.connect(_on_import_requested)
	get_editor_interface().get_editor_main_screen().add_child(_main_screen)
	_make_visible(false)


func _exit_tree() -> void:
	if _main_screen:
		_main_screen.queue_free()
		_main_screen = null


func _has_main_screen() -> bool:
	return true


func _make_visible(next_visible: bool) -> void:
	if _main_screen:
		_main_screen.visible = next_visible


func _get_plugin_name() -> String:
	return "Philia"


func _get_plugin_icon() -> Texture2D:
	return PLUGIN_ICON


func _on_import_requested(map: PhiliaMap) -> void:
	var scene_root := get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		_main_screen.set_level_editor_status("Aucune scène ouverte : crée/ouvre une scène avant d'importer.")
		return
	var imported := PhiliaImporter.build_scene(map)
	scene_root.add_child(imported)
	imported.owner = scene_root
	_main_screen.set_level_editor_status("Carte importée dans la scène (%d tuiles, %d entités)." % [map.tiles.size(), map.entities.size()])
