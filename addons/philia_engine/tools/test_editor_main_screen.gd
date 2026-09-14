@tool
extends SceneTree

## Vérifie la structure de l'écran principal "Philia" (editor/philia_main_screen.tscn)
## sans éditeur : les deux onglets sont bien là, et le sous-éditeur de
## niveaux (Niveaux) reste bien relié à l'écran principal (import_requested
## relayé, set_level_editor_status atteint son label). L'intégration réelle
## de l'EditorPlugin (add_child sur le main screen de l'éditeur, bascule
## via _make_visible) ne peut pas être testée headless — EditorInterface
## n'existe que dans un éditeur réellement lancé.
##
##   godot --headless --script res://addons/philia_engine/tools/test_editor_main_screen.gd

const MAIN_SCREEN_SCENE := preload("res://addons/philia_engine/editor/philia_main_screen.tscn")

var _failures := 0


func _initialize() -> void:
	var main_screen: Control = MAIN_SCREEN_SCENE.instantiate()
	root.add_child(main_screen)
	await process_frame

	var tabs := main_screen.get_node("Tabs") as TabContainer
	_check(tabs != null, "TabContainer présent")
	_check(tabs.get_tab_count() == 2, "2 onglets (Niveaux, Gameplay)")
	_check(tabs.get_tab_title(0) == "Niveaux", "onglet 0 = Niveaux")
	_check(tabs.get_tab_title(1) == "Gameplay", "onglet 1 = Gameplay")

	var forwarded := []
	main_screen.import_requested.connect(func(m): forwarded.append(m))
	var level_editor := main_screen.get_node("%Niveaux")
	level_editor.import_requested.emit(PhiliaMap.new())
	_check(forwarded.size() == 1, "import_requested du sous-éditeur relayé par l'écran principal")

	main_screen.set_level_editor_status("test statut")
	_check(level_editor._status_label.text == "test statut", "set_level_editor_status atteint bien le label du sous-éditeur")

	if _failures == 0:
		print("OK: écran principal Philia (0 échec).")
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
