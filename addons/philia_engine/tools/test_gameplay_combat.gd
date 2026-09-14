@tool
extends SceneTree

## Vérifie PhiliaCombat (V6, §15/§19) sans éditeur.
##
##   godot --headless --script res://addons/philia_engine/tools/test_gameplay_combat.gd

var _failures := 0


func _initialize() -> void:
	_test_damage_uses_force_by_default()
	_test_explicit_damage_overrides_force()
	_test_dead_entities_cannot_fight()
	_test_death_triggers_animator()

	if _failures == 0:
		print("OK: PhiliaCombat (0 échec).")
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


func _test_damage_uses_force_by_default() -> void:
	print("PhiliaCombat: dégâts par défaut = force de l'attaquant")
	var attacker := PhiliaStats.new({"hp": 10.0, "max_hp": 10.0, "force": 3.0})
	var defender := PhiliaStats.new({"hp": 10.0, "max_hp": 10.0})
	var dealt := PhiliaCombat.attack(attacker, defender)
	_check(dealt == 3.0, "dégâts infligés = force de l'attaquant")
	_check(defender.get_stat("hp") == 7.0, "hp du défenseur décrémenté")


func _test_explicit_damage_overrides_force() -> void:
	print("PhiliaCombat: base_damage explicite prime sur la force")
	var attacker := PhiliaStats.new({"hp": 10.0, "max_hp": 10.0, "force": 3.0})
	var defender := PhiliaStats.new({"hp": 10.0, "max_hp": 10.0})
	var dealt := PhiliaCombat.attack(attacker, defender, 5.0)
	_check(dealt == 5.0, "dégâts infligés = base_damage fourni, pas force")


func _test_dead_entities_cannot_fight() -> void:
	print("PhiliaCombat: entité morte ne peut ni frapper ni être frappée")
	var alive := PhiliaStats.new({"hp": 10.0, "max_hp": 10.0, "force": 3.0})
	var dead_attacker := PhiliaStats.new({"hp": 0.0, "max_hp": 10.0, "force": 3.0})
	var dead_defender := PhiliaStats.new({"hp": 0.0, "max_hp": 10.0})
	_check(PhiliaCombat.attack(dead_attacker, alive) == 0.0, "un attaquant mort n'inflige rien")
	_check(PhiliaCombat.attack(alive, dead_defender) == 0.0, "une cible déjà morte n'encaisse rien")


func _test_death_triggers_animator() -> void:
	print("PhiliaCombat: la mort déclenche l'animator de la cible")
	var attacker := PhiliaStats.new({"hp": 10.0, "max_hp": 10.0, "force": 100.0})
	var defender := PhiliaStats.new({"hp": 10.0, "max_hp": 10.0})
	var attacker_animator := PhiliaCharacterAnimator.new()
	var defender_animator := PhiliaCharacterAnimator.new()

	PhiliaCombat.attack(attacker, defender, -1.0, attacker_animator, defender_animator)
	_check(defender.is_dead(), "hp du défenseur à 0")
	_check(defender_animator.is_dead, "PhiliaCharacterAnimator.die() appelé sur la cible")
	_check(not attacker_animator.is_dead, "l'animator de l'attaquant n'est pas affecté")

	attacker_animator.free()
	defender_animator.free()
