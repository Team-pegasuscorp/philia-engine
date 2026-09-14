@tool
extends SceneTree

## Vérifie le dock éditeur "Matériaux" (editor/philia_material_dock.gd)
## sans éditeur : création/aller-retour formulaire <-> .tres, renommage,
## suppression. Appelle directement les handlers _on_*_pressed(), comme
## tools/test_gameplay_dock.gd.
##
##   godot --headless --script res://addons/philia_engine/tools/test_material_dock.gd

const DOCK_SCENE := preload("res://addons/philia_engine/editor/philia_material_dock.tscn")
const TEXTURES_DIR := "res://addons/philia_engine/assets/materials/textures/grass_field"
const TEST_MATERIAL_PATH := "res://addons/philia_engine/assets/materials/test_dock_material.tres"
const TEST_MATERIAL_RENAMED_PATH := "res://addons/philia_engine/assets/materials/test_dock_material_v2.tres"

var _failures := 0
var _dock: Control


func _initialize() -> void:
	_dock = DOCK_SCENE.instantiate()
	root.add_child(_dock)
	await process_frame

	_test_create_material_with_textures()
	_test_rename_material()
	_test_delete_material()

	if _failures == 0:
		print("OK: dock Matériaux (0 échec).")
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


func _test_create_material_with_textures() -> void:
	print("Création d'un matériau avec textures ORM + relief")
	_dock._on_new_pressed()
	_dock._material_id_edit.text = "test_dock_material"
	_dock._albedo_color_picker.color = Color(0.8, 0.2, 0.2)
	_dock._albedo_texture_edit.text = "%s/grass_field_albedo.png" % TEXTURES_DIR
	_dock._normal_texture_edit.text = "%s/grass_field_normal.png" % TEXTURES_DIR
	_dock._orm_texture_edit.text = "%s/grass_field_orm.png" % TEXTURES_DIR
	_dock._height_texture_edit.text = "%s/grass_field_height.png" % TEXTURES_DIR
	_dock._on_apply_pressed()

	_check(ResourceLoader.exists(TEST_MATERIAL_PATH), "fichier .tres créé sur disque")
	var mat: PhiliaMaterial = load(TEST_MATERIAL_PATH)
	_check(mat.albedo_color.is_equal_approx(Color(0.8, 0.2, 0.2)), "couleur albédo sauvegardée")
	_check(mat.albedo_texture != null and mat.normal_texture != null, "textures albedo/normal sauvegardées")
	_check(mat.orm_texture != null and mat.height_texture != null, "textures ORM/relief sauvegardées")

	## Utilisable tel quel par le pipeline d'import 3D existant.
	var sm := PhiliaImporter3D.build_standard_material(mat)
	_check(sm.heightmap_enabled and sm.ao_enabled, "consommable directement par build_standard_material()")

	_check(_index_of(_dock._material_list, "test_dock_material") != -1, "matériau listé après création")


func _test_rename_material() -> void:
	print("Renommage d'un matériau (id modifié + Appliquer)")
	_dock._on_material_selected(_index_of(_dock._material_list, "test_dock_material"))
	_dock._material_id_edit.text = "test_dock_material_v2"
	_dock._on_apply_pressed()

	_check(not ResourceLoader.exists(TEST_MATERIAL_PATH), "ancien fichier .tres retiré après renommage")
	_check(ResourceLoader.exists(TEST_MATERIAL_RENAMED_PATH), "nouveau fichier .tres présent")
	_check(_index_of(_dock._material_list, "test_dock_material") == -1, "ancien id absent de la liste")
	_check(_index_of(_dock._material_list, "test_dock_material_v2") != -1, "nouvel id présent dans la liste")


func _test_delete_material() -> void:
	print("Suppression d'un matériau")
	_dock._on_material_selected(_index_of(_dock._material_list, "test_dock_material_v2"))
	_dock._on_delete_pressed()

	_check(not ResourceLoader.exists(TEST_MATERIAL_RENAMED_PATH), "fichier .tres supprimé du disque")
	_check(_index_of(_dock._material_list, "test_dock_material_v2") == -1, "matériau retiré de la liste")


func _index_of(list: ItemList, text: String) -> int:
	for i in range(list.item_count):
		if list.get_item_text(i) == text:
			return i
	return -1
