@tool
extends SceneTree

## Vérifie PhiliaQuest / PhiliaQuestLog (V6, §19) sans éditeur.
##
##   godot --headless --script res://addons/philia_engine/tools/test_gameplay_quests.gd

var _failures := 0


func _initialize() -> void:
	_test_objective_progress_and_completion()
	_test_inactive_quest_ignores_progress()
	_test_fail()
	_test_dict_round_trip()
	_test_quest_log_forwards_signals()
	await _test_trigger_integration()

	if _failures == 0:
		print("OK: PhiliaQuest + PhiliaQuestLog (0 échec).")
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


func _make_quest() -> PhiliaQuest:
	return PhiliaQuest.new("hunt_wolves", [
		{"id": "kill_wolves", "required": 3},
		{"id": "collect_pelts", "required": 2},
	])


func _test_objective_progress_and_completion() -> void:
	print("PhiliaQuest: progression et complétion")
	var quest := _make_quest()
	var progress_calls := []
	quest.objective_progress.connect(func(oid, count, required): progress_calls.append([oid, count, required]))
	var completed_signaled := [false]
	quest.completed.connect(func(): completed_signaled[0] = true)

	quest.start()
	quest.progress_objective("kill_wolves", 2)
	_check(progress_calls[0] == ["kill_wolves", 2, 3], "objective_progress émis avec le bon compte")
	_check(not quest.is_objective_complete("kill_wolves"), "objectif pas encore rempli")

	quest.progress_objective("kill_wolves", 999)
	_check(quest.is_objective_complete("kill_wolves"), "quantité bornée par required, objectif rempli")
	_check(not quest.is_complete(), "quête pas complète tant qu'un objectif manque")

	quest.progress_objective("collect_pelts", 2)
	_check(quest.is_complete(), "quête complète quand tous les objectifs le sont")
	_check(completed_signaled[0], "signal completed émis")

	quest.progress_objective("collect_pelts", 1)
	_check(quest.objectives[1]["count"] == 2, "aucune progression supplémentaire après complétion")


func _test_inactive_quest_ignores_progress() -> void:
	print("PhiliaQuest: quête inactive ignore la progression")
	var quest := _make_quest()
	quest.progress_objective("kill_wolves", 1)
	_check(quest.objectives[0]["count"] == 0, "aucune progression avant start()")


func _test_fail() -> void:
	print("PhiliaQuest: échec")
	var quest := _make_quest()
	var failed_signaled := [false]
	quest.failed.connect(func(): failed_signaled[0] = true)
	quest.start()
	quest.fail()
	_check(quest.state == PhiliaQuest.State.FAILED, "état FAILED")
	_check(failed_signaled[0], "signal failed émis")
	quest.progress_objective("kill_wolves", 1)
	_check(quest.objectives[0]["count"] == 0, "aucune progression possible après échec")


func _test_dict_round_trip() -> void:
	print("PhiliaQuest: aller-retour to_dict/from_dict")
	var quest := _make_quest()
	quest.start()
	quest.progress_objective("kill_wolves", 1)
	var restored := PhiliaQuest.from_dict(quest.to_dict())
	_check(restored.id == "hunt_wolves", "id préservé")
	_check(restored.state == PhiliaQuest.State.ACTIVE, "état préservé")
	_check(restored.objectives[0]["count"] == 1, "progression préservée")


func _test_quest_log_forwards_signals() -> void:
	print("PhiliaQuestLog: forwarding des signaux avec l'id de quête")
	var quest_log := PhiliaQuestLog.new()
	quest_log.add_quest(_make_quest())
	quest_log.add_quest(PhiliaQuest.new("simple", [{"id": "step", "required": 1}]))

	var completed_ids := []
	quest_log.quest_completed.connect(func(qid): completed_ids.append(qid))

	quest_log.start_quest("simple")
	quest_log.progress("simple", "step", 1)
	_check(completed_ids == ["simple"], "quest_completed relaie l'id de la bonne quête")
	_check(not quest_log.is_quest_complete("hunt_wolves"), "l'autre quête du log n'est pas affectée")


## Démontre l'intégration avec un PhiliaTriggerArea2D déjà existant (V6
## triggers) sans coupler PhiliaQuest à PhiliaTriggerArea2D dans le moteur :
## le jeu connecte lui-même triggered -> progress().
func _test_trigger_integration() -> void:
	print("Intégration Trigger -> Quête")
	var quest_log := PhiliaQuestLog.new()
	quest_log.add_quest(PhiliaQuest.new("reach_door", [{"id": "open_door", "required": 1}]))
	quest_log.start_quest("reach_door")

	var trigger := PhiliaTriggerArea2D.new()
	root.add_child(trigger)
	await process_frame
	trigger.triggered.connect(func(_body): quest_log.progress("reach_door", "open_door", 1))

	var player := Node2D.new()
	trigger.emit_signal("body_entered", player)
	_check(quest_log.is_quest_complete("reach_door"), "trigger connecté fait progresser puis complète la quête")

	trigger.queue_free()
	player.queue_free()
