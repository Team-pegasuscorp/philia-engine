@tool
extends SceneTree

## Vérifie l'annuler/rétablir du dock "Philia Gameplay" sans éditeur :
## Appliquer/Supprimer un gabarit annulables, Ctrl+Z/Ctrl+Y via
## _unhandled_key_input(), et Nouveau/Charger qui réinitialisent
## l'historique. Même principe que tools/test_dock_undo_redo.gd pour
## l'éditeur de niveaux.
##
##   godot --headless --script res://addons/philia_engine/tools/test_gameplay_dock_undo_redo.gd

const DOCK_SCENE := preload("res://addons/philia_engine/editor/philia_gameplay_dock.tscn")

var _failures := 0
var _dock: Control


func _initialize() -> void:
	_dock = DOCK_SCENE.instantiate()
	root.add_child(_dock)
	await process_frame

	_test_apply_then_undo_redo()
	_test_delete_then_undo()
	_test_item_apply_then_undo()
	_test_ctrl_z_ctrl_y_shortcuts()
	_test_new_clears_history()

	if _failures == 0:
		print("OK: undo/redo dock Philia Gameplay (0 échec).")
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


func _test_apply_then_undo_redo() -> void:
	print("Appliquer un gabarit, puis Annuler/Rétablir")
	_dock._on_new_template_pressed()
	_dock._template_id_edit.text = "loup"
	_dock._hp_spin.value = 8.0
	_dock._on_apply_template_pressed()

	_check(_dock.data.entity_templates.has("loup"), "gabarit présent après Appliquer")
	_check(not _dock._undo_button.disabled, "bouton Annuler actif")

	_dock._on_undo_pressed()
	_check(not _dock.data.entity_templates.has("loup"), "Annuler retire le gabarit appliqué")
	_check(not _dock._redo_button.disabled, "bouton Rétablir actif après un annuler")

	_dock._on_redo_pressed()
	_check(_dock.data.entity_templates.has("loup"), "Rétablir réapplique le gabarit")


func _test_delete_then_undo() -> void:
	print("Supprimer un gabarit, puis Annuler")
	_dock._template_list.select(_index_of(_dock._template_list, "loup"))
	_dock._on_delete_template_pressed()
	_check(not _dock.data.entity_templates.has("loup"), "gabarit supprimé")

	_dock._on_undo_pressed()
	_check(_dock.data.entity_templates.has("loup"), "Annuler restaure le gabarit supprimé")


func _test_item_apply_then_undo() -> void:
	print("Appliquer un objet, puis Annuler")
	_dock._on_new_item_pressed()
	_dock._item_id_edit.text = "epee"
	_dock._bonus_stat_edit.text = "force"
	_dock._bonus_delta_spin.value = 3.0
	_dock._on_add_bonus_pressed()
	_dock._on_apply_item_pressed()
	_check(_dock.data.items.has("epee"), "objet présent après Appliquer")

	_dock._on_undo_pressed()
	_check(not _dock.data.items.has("epee"), "Annuler retire l'objet appliqué")

	_dock._on_redo_pressed()
	_check(_dock.data.items.has("epee"), "Rétablir réapplique l'objet")


func _test_ctrl_z_ctrl_y_shortcuts() -> void:
	print("Raccourcis clavier Ctrl+Z / Ctrl+Y")
	## Action connue juste avant le test, pour ne pas dépendre de ce que le
	## test précédent a laissé comme dernière action annulable.
	_dock._on_new_template_pressed()
	_dock._template_id_edit.text = "renard"
	_dock._on_apply_template_pressed()
	var had_renard_before: bool = _dock.data.entity_templates.has("renard")

	var undo_event := InputEventKey.new()
	undo_event.keycode = KEY_Z
	undo_event.ctrl_pressed = true
	undo_event.pressed = true
	_dock._unhandled_key_input(undo_event)
	_check(_dock.data.entity_templates.has("renard") != had_renard_before, "Ctrl+Z change bien l'état (annule la dernière action)")

	var redo_event := InputEventKey.new()
	redo_event.keycode = KEY_Y
	redo_event.ctrl_pressed = true
	redo_event.pressed = true
	_dock._unhandled_key_input(redo_event)
	_check(_dock.data.entity_templates.has("renard") == had_renard_before, "Ctrl+Y rétablit l'état d'avant Ctrl+Z")


func _test_new_clears_history() -> void:
	print("Nouveau réinitialise l'historique")
	_check(_dock._undo_stack.can_undo(), "historique non vide avant Nouveau")
	_dock._on_new_pressed()
	_check(not _dock._undo_stack.can_undo() and not _dock._undo_stack.can_redo(), "historique vidé après Nouveau")
	_check(_dock._undo_button.disabled and _dock._redo_button.disabled, "boutons désactivés après Nouveau")


func _index_of(list: ItemList, text: String) -> int:
	for i in range(list.item_count):
		if list.get_item_text(i) == text:
			return i
	return -1
