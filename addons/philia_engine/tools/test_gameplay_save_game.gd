@tool
extends SceneTree

## Vérifie PhiliaSaveGame (V6, §19) sans éditeur, y compris un aller-retour
## disque avec de vraies sections Stats/Inventaire/Quêtes.
##
##   godot --headless --script res://addons/philia_engine/tools/test_gameplay_save_game.gd

const TEST_PATH := "/tmp/philia_save_game_test.philiasave"

var _failures := 0


func _initialize() -> void:
	_test_sections_in_memory()
	_test_dict_round_trip()
	_test_disk_round_trip_with_real_systems()
	_test_load_missing_file_returns_null()

	if _failures == 0:
		print("OK: PhiliaSaveGame (0 échec).")
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


func _test_sections_in_memory() -> void:
	print("PhiliaSaveGame: sections en mémoire")
	var save_game := PhiliaSaveGame.new()
	_check(not save_game.has_section("stats"), "aucune section au départ")
	save_game.set_section("stats", {"hp": 5.0})
	_check(save_game.has_section("stats"), "section présente après set_section")
	_check(save_game.get_section("stats") == {"hp": 5.0}, "contenu de la section correct")
	_check(save_game.get_section("missing", {"x": 1}) == {"x": 1}, "valeur par défaut si section absente")


func _test_dict_round_trip() -> void:
	print("PhiliaSaveGame: aller-retour to_dict/from_dict")
	var save_game := PhiliaSaveGame.new()
	save_game.set_section("stats", {"hp": 7.0})
	var restored := PhiliaSaveGame.from_dict(save_game.to_dict())
	_check(restored.format_version == PhiliaSaveGame.FORMAT_VERSION, "format_version préservé")
	_check(restored.get_section("stats") == {"hp": 7.0}, "section préservée")


func _test_disk_round_trip_with_real_systems() -> void:
	print("PhiliaSaveGame: aller-retour disque avec Stats/Inventaire/Quêtes réels")
	var stats := PhiliaStats.new({"hp": 6.0, "max_hp": 10.0, "force": 4.0})
	var inventory := PhiliaInventory.new([], 5)
	inventory.add_item("torch", 2)
	var quest_log := PhiliaQuestLog.new()
	quest_log.add_quest(PhiliaQuest.new("hunt_wolves", [{"id": "kill_wolves", "required": 3}]))
	quest_log.start_quest("hunt_wolves")
	quest_log.progress("hunt_wolves", "kill_wolves", 2)

	var save_game := PhiliaSaveGame.new()
	save_game.set_section("stats", stats.data)
	save_game.set_section("inventory", {"slots": inventory.slots, "capacity": inventory.capacity})
	save_game.set_section("quests", quest_log.to_dict())

	var save_err := save_game.save(TEST_PATH)
	_check(save_err == OK, "écriture disque réussie")

	var loaded := PhiliaSaveGame.load(TEST_PATH)
	_check(loaded != null, "lecture disque réussie")

	var restored_stats := PhiliaStats.new(loaded.get_section("stats"))
	_check(restored_stats.get_stat("hp") == 6.0 and restored_stats.get_stat("force") == 4.0, "PhiliaStats reconstruit à l'identique")

	var inv_section := loaded.get_section("inventory")
	var restored_inventory := PhiliaInventory.new(inv_section.get("slots", []), inv_section.get("capacity", 0))
	_check(restored_inventory.get_quantity("torch") == 2, "PhiliaInventory reconstruit à l'identique")

	var restored_quests := PhiliaQuestLog.from_dict(loaded.get_section("quests"))
	_check(restored_quests.get_quest("hunt_wolves").objectives[0]["count"] == 2, "PhiliaQuestLog reconstruit à l'identique")

	DirAccess.remove_absolute(TEST_PATH)


func _test_load_missing_file_returns_null() -> void:
	print("PhiliaSaveGame: chargement d'un fichier absent")
	_check(PhiliaSaveGame.load("/tmp/philia_save_game_does_not_exist.philiasave") == null, "load() renvoie null si le fichier n'existe pas")
