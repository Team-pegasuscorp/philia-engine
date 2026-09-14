@tool
class_name PhiliaStats
extends RefCounted

## Caractéristiques génériques d'une entité (§11 : vie, vitesse, force,
## perception). Wrappe le champ optionnel "stats" d'une entité de
## .philiamap (dictionnaire plat JSON) — pas une scène. Philia fournit le
## calcul (dégâts, mort), le jeu qui importe la carte décide du sens exact
## de chaque statistique (§11/§20).

signal died
signal stat_changed(key: String, value: float)

const DEFAULT_STATS := {
	"hp": 10.0, "max_hp": 10.0,
	"speed": 1.0, "force": 1.0, "perception": 1.0,
}

var data: Dictionary


func _init(source: Dictionary = {}) -> void:
	data = DEFAULT_STATS.duplicate()
	data.merge(source, true)


static func from_entity(entity: Dictionary) -> PhiliaStats:
	return PhiliaStats.new(entity.get("stats", {}))


## Écrit le dictionnaire courant dans entity["stats"] (même référence de
## Dictionary que data, donc les futures modifications restent visibles
## sans rappel explicite tant que l'entité garde cette référence).
func apply_to_entity(entity: Dictionary) -> void:
	entity["stats"] = data


func get_stat(key: String) -> float:
	return data.get(key, 0.0)


func set_stat(key: String, value: float) -> void:
	if key == "hp":
		value = clampf(value, 0.0, get_stat("max_hp"))
	data[key] = value
	stat_changed.emit(key, value)
	if key == "hp" and value <= 0.0:
		died.emit()


func modify_stat(key: String, delta: float) -> void:
	set_stat(key, get_stat(key) + delta)


func is_dead() -> bool:
	return get_stat("hp") <= 0.0


## Retourne les dégâts réellement appliqués (0 si déjà mort ou amount <= 0).
func take_damage(amount: float) -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	var before := get_stat("hp")
	set_stat("hp", before - amount)
	return before - get_stat("hp")


## Retourne le soin réellement appliqué (borné par max_hp).
func heal(amount: float) -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	var before := get_stat("hp")
	set_stat("hp", before + amount)
	return get_stat("hp") - before
