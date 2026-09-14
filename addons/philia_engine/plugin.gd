@tool
extends EditorPlugin

const PhiliaDock := preload("res://addons/philia_engine/editor/philia_dock.tscn")

var _dock: Control


func _enter_tree() -> void:
	_dock = PhiliaDock.instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, _dock)


func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
