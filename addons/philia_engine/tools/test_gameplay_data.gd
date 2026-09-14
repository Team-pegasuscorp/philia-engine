@tool
extends SceneTree

## Vérifie PhiliaGameplayData (V6, §19) sans éditeur.
##
##   godot --headless --script res://addons/philia_engine/tools/test_gameplay_data.gd

const TEST_PATH := "/tmp/philia_gameplay_data_test.philiagameplay"

var _failures := 0


func _initialize() -> void:
	_test_instantiate_stats_and_inventory()
	_test_instantiate_behavior_config()
	_test_item_bonuses()
	_test_get_quest_and_dialogue()
	_test_disk_round_trip()

	if _failures == 0:
		print("OK: PhiliaGameplayData (0 échec).")
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


func _make_data() -> PhiliaGameplayData:
	var data := PhiliaGameplayData.new()
	data.entity_templates["wolf"] = {
		"stats": {"hp": 8.0, "max_hp": 8.0, "force": 3.0},
		"behavior": {"preset": "aggressive", "detection_radius": 6.0, "action": "bite"},
		"inventory": [{"item": "pelt", "quantity": 1}],
		"inventory_capacity": 4,
	}
	data.quests["hunt_wolves"] = PhiliaQuest.new("hunt_wolves", [{"id": "kill_wolves", "required": 3}]).to_dict()
	data.dialogues["guard_talk"] = PhiliaDialogue.new("guard_talk", {
		"greet": {"speaker": "Garde", "text": "Halte !", "next": ""},
	}, "greet").to_dict()
	data.items["epee"] = {"stat_bonuses": {"force": 3.0}}
	return data


func _test_instantiate_stats_and_inventory() -> void:
	print("PhiliaGameplayData: instantiate_stats / instantiate_inventory")
	var data := _make_data()
	var stats := data.instantiate_stats("wolf")
	_check(stats.get_stat("hp") == 8.0 and stats.get_stat("force") == 3.0, "stats du gabarit reprises")
	var inv := data.instantiate_inventory("wolf")
	_check(inv.has_item("pelt") and inv.capacity == 4, "inventaire et capacité du gabarit repris")

	var default_stats := data.instantiate_stats("inconnu")
	_check(default_stats.get_stat("hp") == PhiliaStats.DEFAULT_STATS["hp"], "gabarit inconnu -> stats par défaut")


func _test_instantiate_behavior_config() -> void:
	print("PhiliaGameplayData: instantiate_behavior_config")
	var data := _make_data()
	var cfg := data.instantiate_behavior_config("wolf")
	_check(cfg.get("preset") == "aggressive" and cfg.get("action") == "bite", "config comportement reprise du gabarit")

	var behavior := PhiliaBehavior.new()
	behavior.configure(cfg)
	_check(behavior.preset == PhiliaBehavior.Preset.AGGRESSIVE, "utilisable directement par PhiliaBehavior.configure()")

	_check(data.instantiate_behavior_config("inconnu").is_empty(), "gabarit inconnu -> dict vide")


func _test_item_bonuses() -> void:
	print("PhiliaGameplayData: item_bonuses")
	var data := _make_data()
	var bonuses := data.item_bonuses("epee")
	_check(bonuses.get("force") == 3.0, "bonus de l'objet repris")
	_check(data.item_bonuses("inconnu").is_empty(), "objet inconnu -> dict vide")

	## Utilisable directement par PhiliaEquipment.
	var stats := PhiliaStats.new({"force": 1.0})
	var inv := PhiliaInventory.new()
	inv.add_item("epee")
	PhiliaEquipment.equip(inv, stats, "epee", bonuses)
	_check(stats.get_stat("force") == 4.0, "bonus consommable directement par PhiliaEquipment.equip()")


func _test_get_quest_and_dialogue() -> void:
	print("PhiliaGameplayData: get_quest / get_dialogue")
	var data := _make_data()
	var quest := data.get_quest("hunt_wolves")
	_check(quest != null and quest.objectives[0]["required"] == 3, "quête reconstruite")
	_check(data.get_quest("inconnu") == null, "quête inconnue -> null")

	var dialogue := data.get_dialogue("guard_talk")
	_check(dialogue != null and dialogue.start_node == "greet", "dialogue reconstruit")
	_check(data.get_dialogue("inconnu") == null, "dialogue inconnu -> null")


func _test_disk_round_trip() -> void:
	print("PhiliaGameplayData: aller-retour disque")
	var data := _make_data()
	_check(data.save(TEST_PATH) == OK, "écriture disque réussie")
	var loaded := PhiliaGameplayData.load(TEST_PATH)
	_check(loaded != null, "lecture disque réussie")
	_check(loaded.entity_templates.has("wolf"), "gabarit préservé")
	_check(loaded.items.has("epee"), "objet préservé")
	_check(loaded.quests.has("hunt_wolves"), "quête préservée")
	_check(loaded.dialogues.has("guard_talk"), "dialogue préservé")
	DirAccess.remove_absolute(TEST_PATH)
