@tool
class_name PhiliaConditions
extends RefCounted

## Évalue si une tuile/entité .philiamap doit être active selon le temps et
## les connaissances du joueur (§9 : "une même porte peut produire une
## scène différente selon l'heure" ; §10 : conditions dépendant de la date,
## de l'heure, ou de l'histoire). Champ optionnel "conditions" sur une
## tuile ou une entité : Array[Dictionary], TOUTES doivent être vraies (ET
## logique) pour que l'élément soit actif. Sans ce champ, toujours actif.
##
## Volontairement à part de PhiliaMap/PhiliaClock/PhiliaJournal plutôt que
## fondu dans l'un des trois : évaluer une condition a besoin des trois en
## même temps, alors que chacun doit rester utilisable seul (§20 : ne pas
## coupler ce que Godot/le générique n'a pas besoin de connaître).
##
## Formes de condition reconnues (toutes sérialisables en JSON, §21.3) :
##   {"day": 23}                                  -> jour précis
##   {"hour": 18}                                  -> heure précise
##   {"hour_min": 16, "hour_max": 22}               -> plage d'heures
##   {"journal_has": "personnes", "where": {...}}   -> le carnet contient
##       une entrée de cette catégorie dont les champs correspondent à
##       "where" (PhiliaJournal.has_matching_entry).

static func is_active(element: Dictionary, clock: PhiliaClock, journal: PhiliaJournal) -> bool:
	var conditions: Array = element.get("conditions", [])
	for condition in conditions:
		if not _matches_one(condition, clock, journal):
			return false
	return true


static func _matches_one(condition: Dictionary, clock: PhiliaClock, journal: PhiliaJournal) -> bool:
	if condition.has("journal_has"):
		var category := String(condition["journal_has"])
		var where: Dictionary = condition.get("where", {})
		return journal.has_matching_entry(category, where)
	return clock.matches(condition)
