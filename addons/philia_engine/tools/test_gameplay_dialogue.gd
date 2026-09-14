@tool
extends SceneTree

## Vérifie PhiliaDialogue (V6, §19) sans éditeur.
##
##   godot --headless --script res://addons/philia_engine/tools/test_gameplay_dialogue.gd

var _failures := 0


func _initialize() -> void:
	_test_start_and_choice()
	_test_choice_without_next_ends()
	_test_linear_advance()
	_test_invalid_choice_index_ignored()
	_test_dict_round_trip()
	_test_action_field_passthrough_to_quest()

	if _failures == 0:
		print("OK: PhiliaDialogue (0 échec).")
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


func _make_dialogue() -> PhiliaDialogue:
	return PhiliaDialogue.new("guard_talk", {
		"greet": {
			"speaker": "Garde", "text": "Halte !",
			"choices": [
				{"text": "Je viens en paix", "next": "peace", "action": "quest:reach_door:talk_guard"},
				{"text": "...", "next": ""},
			],
		},
		"peace": {"speaker": "Garde", "text": "Bien, passe.", "next": ""},
	}, "greet")


func _test_start_and_choice() -> void:
	print("PhiliaDialogue: start() et choose() suivent le graphe")
	var dialogue := _make_dialogue()
	var shown := []
	dialogue.line_shown.connect(func(nid, speaker, text, choices): shown.append([nid, speaker, text, choices.size()]))

	dialogue.start()
	_check(shown[0] == ["greet", "Garde", "Halte !", 2], "premier nœud émis avec ses 2 choix")
	_check(dialogue.is_active(), "dialogue actif après start()")

	dialogue.choose(0)
	_check(shown[1] == ["peace", "Garde", "Bien, passe.", 0], "choix 0 mène au nœud peace, sans choix")


func _test_choice_without_next_ends() -> void:
	print("PhiliaDialogue: choix sans next termine le dialogue")
	var dialogue := _make_dialogue()
	var ended_signaled := [false]
	dialogue.ended.connect(func(): ended_signaled[0] = true)
	dialogue.start()
	dialogue.choose(1)
	_check(ended_signaled[0], "signal ended émis")
	_check(not dialogue.is_active(), "dialogue plus actif")


func _test_linear_advance() -> void:
	print("PhiliaDialogue: advance() sur un nœud sans choix")
	var dialogue := _make_dialogue()
	dialogue.start()
	dialogue.choose(0)  ## -> peace, next: ""
	var ended_signaled := [false]
	dialogue.ended.connect(func(): ended_signaled[0] = true)
	dialogue.advance()
	_check(ended_signaled[0], "advance() vers next=\"\" termine le dialogue")


func _test_invalid_choice_index_ignored() -> void:
	print("PhiliaDialogue: index de choix invalide ignoré")
	var dialogue := _make_dialogue()
	dialogue.start()
	dialogue.choose(5)
	_check(dialogue.current_node == "greet", "reste sur le nœud courant")
	dialogue.choose(-1)
	_check(dialogue.current_node == "greet", "index négatif aussi ignoré")


func _test_dict_round_trip() -> void:
	print("PhiliaDialogue: aller-retour to_dict/from_dict")
	var dialogue := _make_dialogue()
	var restored := PhiliaDialogue.from_dict(dialogue.to_dict())
	_check(restored.id == "guard_talk", "id préservé")
	_check(restored.start_node == "greet", "nœud de départ préservé")
	restored.start()
	_check(restored.nodes["greet"]["choices"][0]["action"] == "quest:reach_door:talk_guard", "champ action préservé")


## Démontre que le champ "action" d'un choix, jamais interprété par
## Philia, peut servir de point d'accroche générique vers un autre
## système déjà existant (ici PhiliaQuestLog) sans coupler les classes.
func _test_action_field_passthrough_to_quest() -> void:
	print("Intégration Dialogue -> Quête via le champ action")
	var quest_log := PhiliaQuestLog.new()
	quest_log.add_quest(PhiliaQuest.new("reach_door", [{"id": "talk_guard", "required": 1}]))
	quest_log.start_quest("reach_door")

	var dialogue := _make_dialogue()
	dialogue.start()
	## Le jeu lirait "action" au moment où le joueur clique ce choix ; ici on
	## simule directement ce clic pour vérifier le branchement.
	var chosen: Dictionary = dialogue.nodes["greet"]["choices"][0]
	var parts: PackedStringArray = chosen["action"].split(":")
	quest_log.progress(parts[1], parts[2], 1)
	_check(quest_log.is_quest_complete("reach_door"), "action du choix de dialogue fait progresser la quête")
