@tool
extends SceneTree

## Vérifie PhiliaImporter3D.build_standard_material() (§6) : le canal ORM
## packé (convention tile-gen) est correctement dispatché vers
## roughness/metallic/ao_texture avec les bons channels, et le
## comportement scalaire (sans orm_texture) reste inchangé.
##
##   godot --headless --script res://addons/philia_engine/tools/test_material_orm.gd

var _failures := 0


func _initialize() -> void:
	_test_orm_texture_wiring()
	_test_scalar_fallback_without_orm()
	_test_height_texture()

	if _failures == 0:
		print("OK: PhiliaMaterial ORM/relief (0 échec).")
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


func _test_orm_texture_wiring() -> void:
	print("build_standard_material: orm_texture -> roughness/metallic/ao")
	var mat := PhiliaMaterial.new()
	var orm := load("res://addons/philia_engine/assets/materials/textures/grass_field/grass_field_orm.png")
	mat.orm_texture = orm

	var sm := PhiliaImporter3D.build_standard_material(mat)
	_check(sm.roughness_texture == orm and sm.roughness_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_RED, "roughness sur le canal R")
	_check(sm.metallic_texture == orm and sm.metallic_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_GREEN, "metallic sur le canal G")
	_check(sm.ao_enabled and sm.ao_texture == orm and sm.ao_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_BLUE, "AO sur le canal B")
	_check(sm.roughness == 1.0 and sm.metallic == 1.0, "facteurs scalaires à 1.0 pour laisser la texture piloter")


func _test_scalar_fallback_without_orm() -> void:
	print("build_standard_material: sans orm_texture -> scalaires seuls")
	var mat := PhiliaMaterial.new()
	mat.roughness = 0.4
	mat.metallic = 0.2
	var sm := PhiliaImporter3D.build_standard_material(mat)
	_check(sm.roughness_texture == null and sm.metallic_texture == null, "aucune texture roughness/metallic")
	## is_equal_approx() : StandardMaterial3D stocke roughness/metallic en
	## float32, une comparaison exacte avec le double GDScript échoue.
	_check(is_equal_approx(sm.roughness, 0.4) and is_equal_approx(sm.metallic, 0.2), "valeurs scalaires reprises telles quelles")


func _test_height_texture() -> void:
	print("build_standard_material: height_texture -> heightmap")
	var mat := PhiliaMaterial.new()
	var height := load("res://addons/philia_engine/assets/materials/textures/grass_field/grass_field_height.png")
	mat.height_texture = height
	var sm := PhiliaImporter3D.build_standard_material(mat)
	_check(sm.heightmap_enabled and sm.heightmap_texture == height, "heightmap activé avec la bonne texture")
