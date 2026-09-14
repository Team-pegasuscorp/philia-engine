@tool
extends SceneTree

## Vérifie PhiliaUndoStack sans éditeur.
##
##   godot --headless --script res://addons/philia_engine/tools/test_undo_stack.gd

var _failures := 0


func _initialize() -> void:
	_test_push_undo_redo()
	_test_new_action_clears_redo()
	_test_empty_stack_is_noop()
	_test_changed_signal()
	_test_clear()

	if _failures == 0:
		print("OK: PhiliaUndoStack (0 échec).")
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


func _test_push_undo_redo() -> void:
	print("push / undo / redo")
	var stack := PhiliaUndoStack.new()
	var state_a := {"value": "A"}
	var state_b := {"value": "B"}
	var state_c := {"value": "C"}

	stack.push(state_a)  ## avant de passer à B
	var current := state_b
	stack.push(current)  ## avant de passer à C
	current = state_c

	_check(stack.can_undo(), "can_undo vrai après 2 push")
	current = stack.undo(current)
	_check(current["value"] == "B", "undo restaure l'état précédent (B)")
	current = stack.undo(current)
	_check(current["value"] == "A", "second undo restaure l'état encore avant (A)")
	_check(not stack.can_undo(), "plus rien à annuler")

	_check(stack.can_redo(), "can_redo vrai après des undo")
	current = stack.redo(current)
	_check(current["value"] == "B", "redo réapplique B")
	current = stack.redo(current)
	_check(current["value"] == "C", "second redo réapplique C")
	_check(not stack.can_redo(), "plus rien à rétablir")


func _test_new_action_clears_redo() -> void:
	print("un nouveau push vide la pile de rétablissement")
	var stack := PhiliaUndoStack.new()
	stack.push({"value": "A"})
	var current := {"value": "B"}
	current = stack.undo(current)
	_check(stack.can_redo(), "redo disponible après un undo")
	stack.push({"value": "D"})
	_check(not stack.can_redo(), "redo effacé par une nouvelle action")


func _test_empty_stack_is_noop() -> void:
	print("pile vide : undo/redo sans effet")
	var stack := PhiliaUndoStack.new()
	var current := {"value": "seul"}
	var result := stack.undo(current)
	_check(result == current, "undo sur pile vide renvoie l'état inchangé")
	result = stack.redo(current)
	_check(result == current, "redo sur pile vide renvoie l'état inchangé")


func _test_changed_signal() -> void:
	print("signal changed émis sur push/undo/redo/clear")
	var stack := PhiliaUndoStack.new()
	var count := [0]
	stack.changed.connect(func(): count[0] += 1)

	stack.push({"value": "A"})
	_check(count[0] == 1, "changed après push")
	var current := stack.undo({"value": "B"})
	_check(count[0] == 2, "changed après undo")
	stack.redo(current)
	_check(count[0] == 3, "changed après redo")
	stack.clear()
	_check(count[0] == 4, "changed après clear")


func _test_clear() -> void:
	print("clear() vide les deux piles")
	var stack := PhiliaUndoStack.new()
	stack.push({"value": "A"})
	var current := stack.undo({"value": "B"})
	_check(stack.can_redo(), "redo dispo avant clear")
	stack.clear()
	_check(not stack.can_undo() and not stack.can_redo(), "plus rien annulable/rétablissable après clear")
