@tool
class_name PhiliaClock
extends Node

## Horloge générique jour/heure/minute (§10 du concept : "Jour + heure +
## minute"). Ne décide d'aucun contenu de jeu : elle avance et prévient via
## signaux, et expose `matches()` pour qu'un système de jeu (portes, scènes,
## triggers — voir PhiliaConditions) décide quoi faire de l'heure qu'il est.
## Réutilisable pour toute idée ayant besoin d'un temps qui passe
## indépendamment du framerate, pas seulement Le Couloir.

signal minute_passed(day: int, hour: int, minute: int)
signal hour_passed(day: int, hour: int, minute: int)
signal day_passed(day: int)

@export var day: int = 1
@export var hour: int = 0
@export var minute: int = 0

## Minutes de jeu qui s'écoulent par seconde réelle. 0 = horloge figée,
## avancée uniquement à la main via advance_minutes() (utile pour un jeu où
## le temps passe sur des actions du joueur plutôt qu'en continu).
@export var minutes_per_second: float = 0.0

var _minute_accumulator: float = 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or minutes_per_second <= 0.0:
		return
	_minute_accumulator += delta * minutes_per_second
	while _minute_accumulator >= 1.0:
		_minute_accumulator -= 1.0
		advance_minutes(1)


func advance_minutes(amount: int) -> void:
	for i in amount:
		minute += 1
		if minute >= 60:
			minute = 0
			hour += 1
			if hour >= 24:
				hour = 0
				day += 1
				day_passed.emit(day)
			hour_passed.emit(day, hour, minute)
		minute_passed.emit(day, hour, minute)


## true si l'heure/jour courants correspondent à `condition` (clés
## optionnelles : day, hour, minute, hour_min, hour_max — §10 du concept :
## "Tous les jours à 18:00" vs "Le 23 octobre à 18:00"). Toutes les clés
## présentes doivent correspondre (ET logique). Un dictionnaire vide
## correspond toujours.
func matches(condition: Dictionary) -> bool:
	if condition.has("day") and int(condition["day"]) != day:
		return false
	if condition.has("hour") and int(condition["hour"]) != hour:
		return false
	if condition.has("minute") and int(condition["minute"]) != minute:
		return false
	if condition.has("hour_min") and hour < int(condition["hour_min"]):
		return false
	if condition.has("hour_max") and hour > int(condition["hour_max"]):
		return false
	return true


func total_minutes() -> int:
	return (day - 1) * 1440 + hour * 60 + minute


func set_from_total_minutes(total: int) -> void:
	day = 1 + int(total / 1440.0)
	hour = int((total % 1440) / 60.0)
	minute = total % 60


## Affichage humain par défaut (§2 du concept : "18 octobre — 17:42"), à
## remplacer par le jeu si un calendrier nommé (mois/jours de semaine) est
## nécessaire — cette horloge ne connaît que des entiers.
func format() -> String:
	return "Jour %d — %02d:%02d" % [day, hour, minute]


func to_dict() -> Dictionary:
	return {"day": day, "hour": hour, "minute": minute}


func from_dict(data: Dictionary) -> void:
	day = data.get("day", 1)
	hour = data.get("hour", 0)
	minute = data.get("minute", 0)
