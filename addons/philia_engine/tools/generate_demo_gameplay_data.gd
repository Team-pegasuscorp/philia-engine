@tool
extends SceneTree

## Génère gameplay/demo.philiagameplay : le contenu (gabarit "wolf",
## quête "hunt_wolves", dialogue "guard_talk") utilisé par la scène jouable
## scenes/demo_playable.tscn. Volontairement écrit en code plutôt que dans
## le dock éditeur pour rester reproductible/scriptable (§21.3), mais
## strictement le même format PhiliaGameplayData que produirait le dock —
## voir editor/philia_gameplay_dock.gd pour l'éditer à la main ensuite.
##
##   godot --headless --script res://addons/philia_engine/tools/generate_demo_gameplay_data.gd

const OUTPUT_PATH := "res://gameplay/demo.philiagameplay"


func _initialize() -> void:
	var data := PhiliaGameplayData.new()

	data.entity_templates["wolf"] = {
		"stats": {"hp": 6.0, "max_hp": 6.0, "force": 1.0, "speed": 1.0, "perception": 1.0},
		"inventory": [],
		"inventory_capacity": 0,
	}

	data.quests["hunt_wolves"] = PhiliaQuest.new("hunt_wolves", [
		{"id": "kill_wolf", "required": 1},
	]).to_dict()

	data.items["epee"] = {"stat_bonuses": {"force": 3.0}}

	## "action" du choix "accept" : convention propre à cette démo (§20 —
	## Philia ne l'interprète jamais), lue par
	## scenes/demo_playable/controller.gd pour démarrer la quête.
	data.dialogues["guard_talk"] = PhiliaDialogue.new("guard_talk", {
		"greet": {
			"speaker": "Garde", "text": "Un loup rôde près du village. Tu veux bien t'en occuper ?",
			"choices": [
				{"text": "Je m'en occupe", "action": "quest_start:hunt_wolves", "next": "accept"},
				{"text": "Pas le temps", "action": "", "next": "decline"},
			],
		},
		"accept": {"speaker": "Garde", "text": "Merci, sois prudent.", "choices": []},
		"decline": {"speaker": "Garde", "text": "Dommage.", "choices": []},
	}, "greet").to_dict()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var err := data.save(OUTPUT_PATH)
	if err != OK:
		push_error("Échec sauvegarde: %s" % error_string(err))
		quit(1)
		return

	print("OK: contenu gameplay (%s) généré." % OUTPUT_PATH)
	quit()
