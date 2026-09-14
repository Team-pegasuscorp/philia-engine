@tool
class_name PhiliaQuestLog
extends RefCounted

## Registre de quêtes pour un joueur/une entité (V6, §19). Regroupe
## plusieurs PhiliaQuest et relaie leurs signaux sous une forme unique
## (quest_completed/quest_failed avec l'id de la quête) pratique à
## connecter une seule fois côté jeu, plutôt que quête par quête.

signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)

var quests: Dictionary = {}  ## id -> PhiliaQuest


func add_quest(quest: PhiliaQuest) -> void:
	quests[quest.id] = quest
	quest.completed.connect(func() -> void: quest_completed.emit(quest.id))
	quest.failed.connect(func() -> void: quest_failed.emit(quest.id))


func get_quest(quest_id: String) -> PhiliaQuest:
	return quests.get(quest_id)


func start_quest(quest_id: String) -> void:
	var quest: PhiliaQuest = quests.get(quest_id)
	if quest:
		quest.start()


func progress(quest_id: String, objective_id: String, amount: int = 1) -> void:
	var quest: PhiliaQuest = quests.get(quest_id)
	if quest:
		quest.progress_objective(objective_id, amount)


func is_quest_complete(quest_id: String) -> bool:
	var quest: PhiliaQuest = quests.get(quest_id)
	return quest != null and quest.is_complete()


func to_dict() -> Dictionary:
	var data := {}
	for quest_id in quests:
		data[quest_id] = quests[quest_id].to_dict()
	return data


static func from_dict(data: Dictionary) -> PhiliaQuestLog:
	var quest_log := PhiliaQuestLog.new()
	for quest_id in data:
		quest_log.add_quest(PhiliaQuest.from_dict(data[quest_id]))
	return quest_log
