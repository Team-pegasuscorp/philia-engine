@tool
extends EditorPlugin

const PhiliaDock := preload("res://addons/philia_engine/editor/philia_dock.tscn")

var _dock: Control


func _enter_tree() -> void:
	_dock = PhiliaDock.instantiate()
	add_control_to_bottom_panel(_dock, "Philia-Engine")


func _exit_tree() -> void:
	if _dock:
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
		_dock = null
