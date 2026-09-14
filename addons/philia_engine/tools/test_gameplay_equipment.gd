@tool
extends SceneTree

## Vérifie PhiliaEquipment (V6, §11/§20) sans éditeur.
##
##   godot --headless --script res://addons/philia_engine/tools/test_gameplay_equipment.gd

var _failures := 0


func _initialize() -> void:
	_test_equip_applies_bonuses()
	_test_unequip_removes_bonuses()
	_test_equip_requires_item_in_inventory()
	_test_double_equip_is_noop()
	_test_unequip_without_equip_is_noop()

	if _failures == 0:
		print("OK: PhiliaEquipment (0 échec).")
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


func _test_equip_applies_bonuses() -> void:
	print("equip() applique les bonus et marque l'objet équipé")
	var stats := PhiliaStats.new({"force": 2.0, "speed": 1.0})
	var inv := PhiliaInventory.new()
	inv.add_item("epee")
	var bonuses := {"force": 3.0}

	_check(PhiliaEquipment.equip(inv, stats, "epee", bonuses), "equip réussit")
	_check(stats.get_stat("force") == 5.0, "bonus de force appliqué")
	_check(inv.is_equipped("epee"), "objet marqué équipé")


func _test_unequip_removes_bonuses() -> void:
	print("unequip() retire les bonus et marque l'objet non équipé")
	var stats := PhiliaStats.new({"force": 2.0})
	var inv := PhiliaInventory.new()
	inv.add_item("epee")
	var bonuses := {"force": 3.0}
	PhiliaEquipment.equip(inv, stats, "epee", bonuses)

	_check(PhiliaEquipment.unequip(inv, stats, "epee", bonuses), "unequip réussit")
	_check(stats.get_stat("force") == 2.0, "bonus de force retiré (retour à la valeur d'origine)")
	_check(not inv.is_equipped("epee"), "objet marqué non équipé")


func _test_equip_requires_item_in_inventory() -> void:
	print("equip() échoue si l'objet n'est pas dans l'inventaire")
	var stats := PhiliaStats.new({"force": 2.0})
	var inv := PhiliaInventory.new()
	_check(not PhiliaEquipment.equip(inv, stats, "epee", {"force": 3.0}), "equip refusé")
	_check(stats.get_stat("force") == 2.0, "aucun bonus appliqué")


func _test_double_equip_is_noop() -> void:
	print("équiper deux fois n'applique pas le bonus deux fois")
	var stats := PhiliaStats.new({"force": 2.0})
	var inv := PhiliaInventory.new()
	inv.add_item("epee")
	var bonuses := {"force": 3.0}
	PhiliaEquipment.equip(inv, stats, "epee", bonuses)
	_check(not PhiliaEquipment.equip(inv, stats, "epee", bonuses), "second equip refusé")
	_check(stats.get_stat("force") == 5.0, "bonus toujours appliqué une seule fois")


func _test_unequip_without_equip_is_noop() -> void:
	print("déséquiper un objet jamais équipé ne fait rien")
	var stats := PhiliaStats.new({"force": 2.0})
	var inv := PhiliaInventory.new()
	inv.add_item("epee")
	_check(not PhiliaEquipment.unequip(inv, stats, "epee", {"force": 3.0}), "unequip refusé")
	_check(stats.get_stat("force") == 2.0, "aucun changement de stat")
