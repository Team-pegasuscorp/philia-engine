@tool
extends EditorPlugin

const PhiliaDock := preload("res://addons/philia_engine/editor/philia_dock.tscn")

var _dock: Control


func _enter_tree() -> void:
	_dock = PhiliaDock.instantiate()
	_dock.import_requested.connect(_on_import_requested)
	add_control_to_bottom_panel(_dock, "Philia-Engine")


func _exit_tree() -> void:
	if _dock:
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
		_dock = null


func _on_import_requested(map: PhiliaMap) -> void:
	var scene_root := get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		_dock.set_status("Aucune scène ouverte : crée/ouvre une scène avant d'importer.")
		return
	var imported := PhiliaImporter.build_scene(map)
	scene_root.add_child(imported)
	imported.owner = scene_root
	_dock.set_status("Carte importée dans la scène (%d tuiles, %d entités)." % [map.tiles.size(), map.entities.size()])
