@tool
extends SceneTree

## Vérifie PhiliaStats et PhiliaInventory (V6, §11/§19) sans éditeur.
##
##   godot --headless --script res://addons/philia_engine/tools/test_gameplay_stats_inventory.gd

var _failures := 0


func _initialize() -> void:
	_test_stats_damage_and_death()
	_test_stats_apply_to_entity()
	_test_inventory_stack_and_capacity()
	_test_inventory_apply_to_entity()

	if _failures == 0:
		print("OK: PhiliaStats + PhiliaInventory (0 échec).")
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


func _test_stats_damage_and_death() -> void:
	print("PhiliaStats: dégâts / mort")
	var stats := PhiliaStats.new({"hp": 10.0, "max_hp": 10.0})
	var died_signaled := [false]  ## lambda: capture par valeur en GDScript, il faut un conteneur mutable
	stats.died.connect(func(): died_signaled[0] = true)

	_check(stats.take_damage(3.0) == 3.0, "dégâts appliqués intégralement sous le hp restant")
	_check(stats.get_stat("hp") == 7.0, "hp décrémenté")
	_check(stats.heal(20.0) == 3.0, "soin borné par max_hp")
	_check(stats.get_stat("hp") == 10.0, "hp reclampé à max_hp")
	_check(stats.take_damage(999.0) == 10.0, "dégâts bornés au hp disponible")
	_check(stats.is_dead(), "is_dead vrai à hp=0")
	_check(died_signaled[0], "signal died émis")
	_check(stats.take_damage(5.0) == 0.0, "aucun dégât supplémentaire une fois mort")


func _test_stats_apply_to_entity() -> void:
	print("PhiliaStats: aller-retour avec une entité")
	var entity := {"entity": "wolf_01", "stats": {"hp": 6.0, "max_hp": 8.0, "force": 2.0}}
	var stats := PhiliaStats.from_entity(entity)
	_check(stats.get_stat("hp") == 6.0 and stats.get_stat("force") == 2.0, "chargement depuis entity[\"stats\"]")
	stats.modify_stat("force", 1.0)
	stats.apply_to_entity(entity)
	_check(entity["stats"]["force"] == 3.0, "modification répercutée sur l'entité")


func _test_inventory_stack_and_capacity() -> void:
	print("PhiliaInventory: empilement / capacité")
	var inv := PhiliaInventory.new([], 2)
	_check(inv.add_item("wood", 3), "premier item ajouté")
	_check(inv.add_item("wood", 2), "stack existant grossit")
	_check(inv.get_quantity("wood") == 5, "quantité cumulée correcte")
	_check(inv.add_item("stone", 1), "deuxième emplacement distinct accepté")
	_check(not inv.add_item("iron", 1), "troisième emplacement distinct refusé (capacity=2)")
	_check(inv.remove_item("wood", 5), "retrait total d'un stack")
	_check(not inv.has_item("wood"), "item retiré n'existe plus")
	_check(inv.add_item("iron", 1), "emplacement libéré réutilisable")


func _test_inventory_apply_to_entity() -> void:
	print("PhiliaInventory: aller-retour avec une entité")
	var entity := {"entity": "player", "inventory": [{"item": "torch", "quantity": 1}]}
	var inv := PhiliaInventory.from_entity(entity)
	_check(inv.has_item("torch"), "chargement depuis entity[\"inventory\"]")
	inv.add_item("torch", 2)
	inv.apply_to_entity(entity)
	_check(entity["inventory"][0]["quantity"] == 3, "modification répercutée sur l'entité")
