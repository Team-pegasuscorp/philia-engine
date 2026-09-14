@tool
extends SceneTree

## Vérifie l'annuler/rétablir de l'éditeur de niveaux (PhiliaGridCanvas +
## editor/philia_dock.gd) sans éditeur : place/supprime des tuiles en
## simulant des InputEventMouseButton (appel direct de _gui_input(), pas
## de vrai clic possible headless), undo/redo via les boutons, Ctrl+Z/
## Ctrl+Y via _unhandled_key_input(), et undo_stack réinitialisée par
## Nouveau/Charger.
##
##   godot --headless --script res://addons/philia_engine/tools/test_dock_undo_redo.gd

const DOCK_SCENE := preload("res://addons/philia_engine/editor/philia_dock.tscn")

var _failures := 0
var _dock: Control
var _canvas: PhiliaGridCanvas


func _initialize() -> void:
	_dock = DOCK_SCENE.instantiate()
	root.add_child(_dock)
	await process_frame
	_canvas = _dock.get_node("%GridCanvas")

	_test_place_then_undo_redo()
	_test_new_action_clears_redo_stack()
	_test_ctrl_z_ctrl_y_shortcuts()
	_test_new_map_clears_history()

	if _failures == 0:
		print("OK: undo/redo éditeur de niveaux (0 échec).")
		quit()
	else:
		push_error("ÉCHEC: %d assertion(s) invalide(s)." % _failures)
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok - %s" % label)
	else:
		print("  FAIL - %s" % label)
		_failures += 1


func _place_tile(x: int, y: int) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(x, y) * PhiliaGridCanvas.CELL_SIZE + Vector2.ONE
	_canvas._gui_input(event)


func _test_place_then_undo_redo() -> void:
	print("Placer une tuile, puis Annuler/Rétablir")
	_place_tile(0, 0)
	_check(_canvas.map.tiles.size() == 1, "une tuile posée")
	_check(not _dock._undo_button.disabled, "bouton Annuler actif après une action")

	_dock._on_undo_pressed()
	_check(_canvas.map.tiles.is_empty(), "Annuler retire la tuile posée")
	_check(not _dock._redo_button.disabled, "bouton Rétablir actif après un annuler")

	_dock._on_redo_pressed()
	_check(_canvas.map.tiles.size() == 1, "Rétablir repose la tuile")


func _test_new_action_clears_redo_stack() -> void:
	print("Une nouvelle action efface le rétablissement disponible")
	_dock._on_undo_pressed()  ## retire la tuile de _test_place_then_undo_redo -> redo dispo
	_check(not _dock._redo_button.disabled, "rétablir dispo avant la nouvelle action")
	_place_tile(1, 1)
	_check(_dock._redo_button.disabled, "rétablir effacé par la nouvelle tuile posée")


func _test_ctrl_z_ctrl_y_shortcuts() -> void:
	print("Raccourcis clavier Ctrl+Z / Ctrl+Y")
	var tiles_before := _canvas.map.tiles.size()

	var undo_event := InputEventKey.new()
	undo_event.keycode = KEY_Z
	undo_event.ctrl_pressed = true
	undo_event.pressed = true
	_dock._unhandled_key_input(undo_event)
	_check(_canvas.map.tiles.size() == tiles_before - 1, "Ctrl+Z annule via _unhandled_key_input")

	var redo_event := InputEventKey.new()
	redo_event.keycode = KEY_Y
	redo_event.ctrl_pressed = true
	redo_event.pressed = true
	_dock._unhandled_key_input(redo_event)
	_check(_canvas.map.tiles.size() == tiles_before, "Ctrl+Y rétablit via _unhandled_key_input")


func _test_new_map_clears_history() -> void:
	print("Nouveau/Charger réinitialise l'historique")
	_check(_dock._undo_button.disabled == false or _canvas.undo_stack.can_undo(), "historique non vide avant Nouveau")
	_dock._on_new_pressed()
	_check(not _canvas.undo_stack.can_undo() and not _canvas.undo_stack.can_redo(), "historique vidé après Nouveau")
