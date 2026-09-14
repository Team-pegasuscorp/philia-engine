@tool
class_name PhiliaInventory
extends RefCounted

## Inventaire générique d'une entité (V6 gameplay, §19). Wrappe le champ
## optionnel "inventory" d'une entité de .philiamap : liste plate de
## {item, quantity}. Philia empile/retire, le jeu qui importe la carte
## décide du sens des items (équipement, consommable, quête...) — §20.

signal item_added(item: String, quantity: int)
signal item_removed(item: String, quantity: int)

var slots: Array[Dictionary] = []
var capacity: int = 0  ## 0 = illimité (nombre d'emplacements distincts)


func _init(source: Array = [], max_capacity: int = 0) -> void:
	capacity = max_capacity
	for entry in source:
		slots.append({
			"item": entry.get("item", ""),
			"quantity": int(entry.get("quantity", 1)),
			"equipped": bool(entry.get("equipped", false)),
		})


static func from_entity(entity: Dictionary, max_capacity: int = 0) -> PhiliaInventory:
	return PhiliaInventory.new(entity.get("inventory", []), max_capacity)


func apply_to_entity(entity: Dictionary) -> void:
	entity["inventory"] = slots


func get_quantity(item: String) -> int:
	for slot in slots:
		if slot["item"] == item:
			return slot["quantity"]
	return 0


func has_item(item: String, quantity: int = 1) -> bool:
	return get_quantity(item) >= quantity


## false si un nouvel emplacement dépasserait la capacité — un item déjà
## présent peut toujours grossir, seul un item inédit compte contre capacity.
func add_item(item: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false
	for slot in slots:
		if slot["item"] == item:
			slot["quantity"] += quantity
			item_added.emit(item, quantity)
			return true
	if capacity > 0 and slots.size() >= capacity:
		return false
	slots.append({"item": item, "quantity": quantity, "equipped": false})
	item_added.emit(item, quantity)
	return true


## true/false purement déclaratif — PhiliaInventory ne sait pas ce
## qu'"équipé" change mécaniquement (voir PhiliaEquipment, §20).
func is_equipped(item: String) -> bool:
	for slot in slots:
		if slot["item"] == item:
			return slot.get("equipped", false)
	return false


func set_equipped(item: String, value: bool) -> bool:
	for slot in slots:
		if slot["item"] == item:
			slot["equipped"] = value
			return true
	return false


func remove_item(item: String, quantity: int = 1) -> bool:
	if quantity <= 0 or not has_item(item, quantity):
		return false
	for i in slots.size():
		if slots[i]["item"] == item:
			slots[i]["quantity"] -= quantity
			if slots[i]["quantity"] <= 0:
				slots.remove_at(i)
			item_removed.emit(item, quantity)
			return true
	return false
