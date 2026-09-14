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
	_test_template_behavior()
	_test_quest_tab()
	_test_dialogue_tab()
	_test_rename_instead_of_duplicate()
	_test_dialogue_choice_removal_from_middle()
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


func _test_template_behavior() -> void:
	print("Onglet Gabarits : formulaire Comportement")
	_dock._on_new_template_pressed()
	_dock._template_id_edit.text = "ours"
	_dock._behavior_preset_option.select(_dock.BEHAVIOR_PRESETS.find("aggressive"))
	_dock._behavior_action_edit.text = "maul"
	_dock._behavior_detection_spin.value = 8.0
	_dock._behavior_action_radius_spin.value = 2.0
	_dock._on_apply_template_pressed()

	var behavior_cfg: Dictionary = _dock.data.entity_templates["ours"]["behavior"]
	_check(behavior_cfg["preset"] == "aggressive", "preset agressif appliqué")
	_check(behavior_cfg["action"] == "maul", "nom d'action appliqué")
	_check(behavior_cfg["detection_radius"] == 8.0, "rayon de détection appliqué")

	## Sélectionner une autre entrée puis revenir sur "ours" doit remettre
	## le formulaire dans le même état (round-trip formulaire <-> dict).
	_dock._on_new_template_pressed()
	_dock._on_template_selected(_index_of(_dock._template_list, "ours"))
	_check(_dock._behavior_preset_option.selected == _dock.BEHAVIOR_PRESETS.find("aggressive"), "preset rechargé dans le formulaire")
	_check(_dock._behavior_action_edit.text == "maul", "action rechargée dans le formulaire")

	## PhiliaGameplayData.instantiate_behavior_config() doit être directement
	## utilisable pour configurer un vrai PhiliaBehavior.
	var behavior := PhiliaBehavior.new()
	behavior.configure(_dock.data.instantiate_behavior_config("ours"))
	_check(behavior.preset == PhiliaBehavior.Preset.AGGRESSIVE and behavior.action_name == "maul", "config consommable par PhiliaBehavior.configure()")


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


func _test_rename_instead_of_duplicate() -> void:
	print("Renommage (id modifié + Appliquer) au lieu de dupliquer")

	## Gabarit : "loup" créé par _test_template_tab -> renommé "grand_loup".
	_dock._on_template_selected(_index_of(_dock._template_list, "loup"))
	_dock._template_id_edit.text = "grand_loup"
	_dock._on_apply_template_pressed()
	_check(not _dock.data.entity_templates.has("loup"), "ancien id \"loup\" retiré après renommage")
	_check(_dock.data.entity_templates.has("grand_loup"), "nouvel id \"grand_loup\" présent")

	## Quête : "hunt_wolves" -> "hunt_wolf".
	_dock._on_quest_selected(_index_of(_dock._quest_list, "hunt_wolves"))
	_dock._quest_id_edit.text = "hunt_wolf"
	_dock._on_apply_quest_pressed()
	_check(not _dock.data.quests.has("hunt_wolves"), "ancien id \"hunt_wolves\" retiré après renommage")
	_check(_dock.data.quests.has("hunt_wolf"), "nouvel id \"hunt_wolf\" présent")

	## Dialogue : "guard_talk" -> "guard_talk_v2".
	_dock._on_dialogue_selected(_index_of(_dock._dialogue_list, "guard_talk"))
	_dock._dialogue_id_edit.text = "guard_talk_v2"
	_dock._on_apply_dialogue_pressed()
	_check(not _dock.data.dialogues.has("guard_talk"), "ancien id \"guard_talk\" retiré après renommage")
	_check(_dock.data.dialogues.has("guard_talk_v2"), "nouvel id \"guard_talk_v2\" présent")

	## Appliquer sans changer l'id ne doit rien casser (pas de faux renommage).
	_dock._on_apply_template_pressed()
	_check(_dock.data.entity_templates.has("grand_loup"), "réappliquer sans changer l'id garde l'entrée")


func _test_dialogue_choice_removal_from_middle() -> void:
	print("Dialogue : retrait d'un choix au milieu de la liste")
	_dock._on_new_dialogue_pressed()
	_dock._dialogue_id_edit.text = "three_way"

	_dock._on_add_node_pressed()
	var start_node: PhiliaDialogueGraphNode = null
	for child in _dock._dialogue_graph.get_children():
		if child is PhiliaDialogueGraphNode:
			start_node = child
	start_node.add_choice("Choix A")
	start_node.add_choice("Choix B")
	start_node.add_choice("Choix C")

	_dock._on_add_node_pressed()
	_dock._on_add_node_pressed()
	_dock._on_add_node_pressed()
	var targets: Array[PhiliaDialogueGraphNode] = []
	for child in _dock._dialogue_graph.get_children():
		if child is PhiliaDialogueGraphNode and child != start_node:
			targets.append(child)
	_check(targets.size() == 3, "3 nœuds cibles créés pour les 3 choix")

	## Choix 0 -> targets[0], choix 1 -> targets[1], choix 2 -> targets[2].
	_dock._on_connection_request(start_node.name, start_node.choice_port(0), targets[0].name, 0)
	_dock._on_connection_request(start_node.name, start_node.choice_port(1), targets[1].name, 0)
	_dock._on_connection_request(start_node.name, start_node.choice_port(2), targets[2].name, 0)

	## Retire le choix du MILIEU (index 1, vers targets[1]).
	_dock._on_choice_remove_requested(1, start_node)

	_check(start_node.choice_count() == 2, "2 choix restants après retrait du milieu")
	_check(start_node.get_choice_text(0) == "Choix A", "choix 0 inchangé")
	_check(start_node.get_choice_text(1) == "Choix C", "choix 2 devient choix 1 (décalage)")

	var connections: Array = _dock._dialogue_graph.get_connection_list()
	var to_target0 := false
	var to_target1 := false
	var to_target2 := false
	for conn in connections:
		if conn["from_node"] != start_node.name:
			continue
		if conn["to_node"] == targets[0].name and conn["from_port"] == start_node.choice_port(0):
			to_target0 = true
		if conn["to_node"] == targets[1].name:
			to_target1 = true  ## ne doit jamais être vrai : ce choix a été retiré
		if conn["to_node"] == targets[2].name and conn["from_port"] == start_node.choice_port(1):
			to_target2 = true
	_check(to_target0, "connexion vers targets[0] toujours sur le port 0")
	_check(not to_target1, "connexion vers le choix retiré (targets[1]) bien supprimée")
	_check(to_target2, "connexion vers targets[2] réindexée sur le port du nouveau choix 1")


func _test_save_load_round_trip() -> void:
	print("Aller-retour disque via les boutons du dock")
	_dock._path_edit.text = TEST_PATH
	_dock._on_save_pressed()
	_check(FileAccess.file_exists(TEST_PATH), "fichier .philiagameplay écrit sur disque")

	_dock._on_new_pressed()
	_check(_dock.data.entity_templates.is_empty(), "Nouveau vide bien le contenu en mémoire")

	_dock._on_load_pressed()
	_check(_dock.data.entity_templates.has("grand_loup"), "gabarit rechargé depuis le disque (id renommé)")
	_check(_dock.data.quests.has("hunt_wolf"), "quête rechargée depuis le disque (id renommé)")
	_check(_dock.data.dialogues.has("guard_talk_v2"), "dialogue rechargé depuis le disque (id renommé)")
	## "loup" a été renommé "grand_loup" sans laisser de fantôme ; "ours" et
	## le "gabarit_1" créé sans jamais être appliqué (juste sélectionné puis
	## abandonné) restent tels quels : 3 gabarits au total.
	_check(_dock._template_list.item_count == 3, "3 gabarits après renommage (grand_loup, ours, gabarit_1)")

	DirAccess.remove_absolute(TEST_PATH)


func _index_of(list: ItemList, text: String) -> int:
	for i in range(list.item_count):
		if list.get_item_text(i) == text:
			return i
	return -1
