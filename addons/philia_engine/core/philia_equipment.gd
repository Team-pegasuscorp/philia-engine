@tool
class_name PhiliaEquipment
extends RefCounted

## Applique/retire les bonus de stats d'un objet équipé (§11/§20), sur le
## même principe que PhiliaCombat : orchestration pure entre deux systèmes
## qui ne se connaissent pas. PhiliaInventory ne sait que marquer un
## emplacement "equipped" (bool) ; PhiliaStats ne sait qu'ajouter/retirer
## une valeur à une stat nommée. `bonuses` vient typiquement de
## PhiliaGameplayData.item_bonuses(item) : {stat: delta}.
##
## Limite assumée pour rester simple : si un objet équipé est totalement
## retiré de l'inventaire (remove_item jusqu'à 0), le slot disparaît et
## son bonus reste appliqué aux stats sans que rien ne le retire — appeler
## unequip() avant de retirer un objet équipé si ce cas doit être évité.

## Équipe `item` (doit déjà être dans `inventory`) et applique `bonuses` à
## `stats`. Sans effet si absent de l'inventaire ou déjà équipé. Retourne
## true si l'équipement a eu lieu.
static func equip(inventory: PhiliaInventory, stats: PhiliaStats, item: String, bonuses: Dictionary) -> bool:
	if not inventory.has_item(item) or inventory.is_equipped(item):
		return false
	inventory.set_equipped(item, true)
	for stat_name in bonuses:
		stats.modify_stat(stat_name, bonuses[stat_name])
	return true


## Déséquipe `item` et retire `bonuses` de `stats`. Sans effet si l'objet
## n'est pas équipé. Retourne true si le déséquipement a eu lieu.
static func unequip(inventory: PhiliaInventory, stats: PhiliaStats, item: String, bonuses: Dictionary) -> bool:
	if not inventory.is_equipped(item):
		return false
	inventory.set_equipped(item, false)
	for stat_name in bonuses:
		stats.modify_stat(stat_name, -bonuses[stat_name])
	return true
