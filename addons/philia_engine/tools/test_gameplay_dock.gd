@tool
extends SceneTree

## Vérifie le dock éditeur "Philia Gameplay" (V6 UI) sans éditeur : les
## onglets Gabarits/Quêtes/Dialogues, et un aller-retour disque complet.
## Appelle directement les handlers _on_*_pressed() au lieu de simuler des
## clics (headless, pas d'affichage) — c'est le même code que les boutons
## appellent réellement.
##
##   godot --headless --script res://addons/philia_engine/tools/test_gameplay_dock.gd

const DOCK_SCENE := preload("res://addons/philia_engine/editor/philia_gameplay_dock.tscn")
const TEST_PATH := "/tmp/philia_gameplay_dock_test.philiagameplay"

var _failures := 0
var _dock: Control


func _initialize() -> void:
	_dock = DOCK_SCENE.instantiate()
	root.add_child(_dock)
	await process_frame

	_test_template_tab()
	_test_quest_tab()
	_test_dialogue_tab()
	_test_save_load_round_trip()

	if _failures == 0:
		print("OK: dock Philia Gameplay (0 échec).")
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


func _test_template_tab() -> void:
	print("Onglet Gabarits")
	_dock._on_new_template_pressed()
	_dock._template_id_edit.text = "loup"
	_dock._hp_spin.value = 8.0
	_dock._max_hp_spin.value = 8.0
	_dock._force_spin.value = 3.0
	_dock._capacity_spin.value = 4.0
	_dock._item_name_edit.text = "pelt"
	_dock._item_qty_spin.value = 1.0
	_dock._on_add_item_pressed()
	_dock._on_apply_template_pressed()

	_check(_dock.data.entity_templates.has("loup"), "gabarit \"loup\" présent après Appliquer")
	var tmpl: Dictionary = _dock.data.entity_templates["loup"]
	_check(tmpl["stats"]["hp"] == 8.0 and tmpl["stats"]["force"] == 3.0, "stats du gabarit correctes")
	_check(tmpl["inventory"][0]["item"] == "pelt", "objet d'inventaire de départ correct")
	_check(tmpl["inventory_capacity"] == 4, "capacité correcte")

	var stats: PhiliaStats = _dock.data.instantiate_stats("loup")
	_check(stats.get_stat("hp") == 8.0, "PhiliaGameplayData.instantiate_stats() utilisable directement")


func _test_quest_tab() -> void:
	print("Onglet Quêtes")
	_dock._on_new_quest_pressed()
	_dock._quest_id_edit.text = "hunt_wolves"
	_dock._objective_id_edit.text = "kill_wolves"
	_dock._objective_required_spin.value = 3.0
	_dock._on_add_objective_pressed()
	_dock._on_apply_quest_pressed()

	_check(_dock.data.quests.has("hunt_wolves"), "quête présente après Appliquer")
	var quest: PhiliaQuest = _dock.data.get_quest("hunt_wolves")
	_check(quest.objectives[0]["id"] == "kill_wolves" and quest.objectives[0]["required"] == 3, "objectif correct")


func _test_dialogue_tab() -> void:
	print("Onglet Dialogues")
	_dock._on_new_dialogue_pressed()
	_dock._dialogue_id_edit.text = "guard_talk"

	_dock._on_add_node_pressed()  ## -> node_1
	_dock._on_add_node_pressed()  ## -> node_2
	var node1 := _dock._dialogue_graph.get_node(NodePath("node_1")) as PhiliaDialogueGraphNode
	var node2 := _dock._dialogue_graph.get_node(NodePath("node_2")) as PhiliaDialogueGraphNode
	node1.set_speaker("Garde")
	node1.set_text("Halte !")
	node1.add_choice("Je viens en paix", "quest:reach_door:talk_guard")
	node2.set_speaker("Garde")
	node2.set_text("Bien, passe.")

	_dock._on_connection_request(&"node_1", 3, &"node_2", 0)
	_dock._start_node_edit.text = "node_1"
	_dock._on_apply_dialogue_pressed()

	_check(_dock.data.dialogues.has("guard_talk"), "dialogue présent après Appliquer")
	var d: Dictionary = _dock.data.dialogues["guard_talk"]
	_check(d["start"] == "node_1", "nœud de départ correct")
	_check(d["nodes"]["node_1"]["choices"][0]["next"] == "node_2", "connexion graphique traduite en \"next\"")
	_check(d["nodes"]["node_1"]["choices"][0]["action"] == "quest:reach_door:talk_guard", "action du choix préservée")

	var dialogue: PhiliaDialogue = _dock.data.get_dialogue("guard_talk")
	dialogue.start()
	_check(dialogue.current_node == "node_1", "PhiliaDialogue reconstruit démarre bien sur node_1")
	dialogue.choose(0)
	_check(dialogue.current_node == "node_2", "PhiliaDialogue reconstruit suit la connexion vers node_2")

	## Recharge le graphe depuis le dict pour vérifier l'aller-retour visuel.
	_dock.load_dialogue_into_graph(d)
	var reloaded_connections: Array = _dock._dialogue_graph.get_connection_list()
	var found := false
	for conn in reloaded_connections:
		if conn["from_node"] == &"node_1" and conn["to_node"] == &"node_2":
			found = true
	_check(found, "load_dialogue_into_graph() recrée la connexion visuelle")


func _test_save_load_round_trip() -> void:
	print("Aller-retour disque via les boutons du dock")
	_dock._path_edit.text = TEST_PATH
	_dock._on_save_pressed()
	_check(FileAccess.file_exists(TEST_PATH), "fichier .philiagameplay écrit sur disque")

	_dock._on_new_pressed()
	_check(_dock.data.entity_templates.is_empty(), "Nouveau vide bien le contenu en mémoire")

	_dock._on_load_pressed()
	_check(_dock.data.entity_templates.has("loup"), "gabarit rechargé depuis le disque")
	_check(_dock.data.quests.has("hunt_wolves"), "quête rechargée depuis le disque")
	_check(_dock.data.dialogues.has("guard_talk"), "dialogue rechargé depuis le disque")
	## _on_new_template_pressed() crée "gabarit_1", puis Appliquer sous l'id
	## "loup" crée une entrée séparée sans supprimer "gabarit_1" (éditer
	## l'id + Appliquer = nouvelle entrée, pas un renommage — limitation
	## assumée de cette première version) : la liste doit refléter les deux.
	_check(_dock._template_list.item_count == 2, "liste de gabarits réaffichée après chargement (gabarit_1 + loup)")

	DirAccess.remove_absolute(TEST_PATH)
