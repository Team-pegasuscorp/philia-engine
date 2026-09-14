@tool
class_name PhiliaQuest
extends RefCounted

## Une quête générique (V6, §19) : liste d'objectifs avec un compteur
## count/required chacun. Philia ne connaît pas le sens des objectifs
## (tuer un loup, ramasser du bois, atteindre un trigger...) — le jeu
## incrémente la progression via progress_objective(), Philia se contente
## de suivre l'état et de signaler la complétion (§20).

signal objective_progress(objective_id: String, count: int, required: int)
signal completed
signal failed

enum State { INACTIVE, ACTIVE, COMPLETED, FAILED }

var id: String
var state: State = State.INACTIVE
var objectives: Array[Dictionary] = []  ## {id, required, count}


func _init(quest_id: String = "", source_objectives: Array = []) -> void:
	id = quest_id
	for obj in source_objectives:
		objectives.append({
			"id": obj.get("id", ""),
			"required": int(obj.get("required", 1)),
			"count": int(obj.get("count", 0)),
		})


## Reconstruit une quête depuis un dictionnaire JSON-compatible produit par
## to_dict() (utile pour une sauvegarde de partie, V6 §19).
static func from_dict(data: Dictionary) -> PhiliaQuest:
	var quest := PhiliaQuest.new(data.get("id", ""), data.get("objectives", []))
	quest.state = data.get("state", State.INACTIVE) as State
	return quest


func to_dict() -> Dictionary:
	return {"id": id, "state": state, "objectives": objectives}


func start() -> void:
	if state == State.INACTIVE:
		state = State.ACTIVE


func is_objective_complete(objective_id: String) -> bool:
	var obj := _get_objective(objective_id)
	return not obj.is_empty() and obj["count"] >= obj["required"]


## Avance un objectif de `amount` (borné par required). Sans effet si la
## quête n'est pas active ou que l'objectif est déjà rempli. Complète
## automatiquement la quête (et émet completed) quand tous les objectifs
## le sont.
func progress_objective(objective_id: String, amount: int = 1) -> void:
	if state != State.ACTIVE:
		return
	var obj := _get_objective(objective_id)
	if obj.is_empty() or obj["count"] >= obj["required"]:
		return
	obj["count"] = mini(obj["count"] + amount, obj["required"])
	objective_progress.emit(objective_id, obj["count"], obj["required"])
	if _all_objectives_complete():
		state = State.COMPLETED
		completed.emit()


func fail() -> void:
	if state == State.ACTIVE:
		state = State.FAILED
		failed.emit()


func is_complete() -> bool:
	return state == State.COMPLETED


func _get_objective(objective_id: String) -> Dictionary:
	for obj in objectives:
		if obj["id"] == objective_id:
			return obj
	return {}


func _all_objectives_complete() -> bool:
	for obj in objectives:
		if obj["count"] < obj["required"]:
			return false
	return true
