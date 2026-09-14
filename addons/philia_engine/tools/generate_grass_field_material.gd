@tool
extends SceneTree

## Assemble le PhiliaMaterial "grass_field" à partir des textures seamless
## générées par tile-gen (générateur de tuiles procédurales via Blender
## headless, hors de ce dépôt — voir docs/concept.md §6) et déjà copiées
## dans assets/materials/textures/grass_field/. Premier matériau du projet
## avec de vraies textures (albedo + normal + ORM + relief), plutôt qu'une
## couleur plate comme generate_materials.gd.
##
##   godot --headless --script res://addons/philia_engine/tools/generate_grass_field_material.gd

const TEXTURES_DIR := "res://addons/philia_engine/assets/materials/textures/grass_field"
const OUTPUT_PATH := "res://addons/philia_engine/assets/materials/grass_field.tres"


func _initialize() -> void:
	var mat := PhiliaMaterial.new()
	mat.albedo_texture = load("%s/grass_field_albedo.png" % TEXTURES_DIR)
	mat.normal_texture = load("%s/grass_field_normal.png" % TEXTURES_DIR)
	mat.orm_texture = load("%s/grass_field_orm.png" % TEXTURES_DIR)
	mat.height_texture = load("%s/grass_field_height.png" % TEXTURES_DIR)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var err := ResourceSaver.save(mat, OUTPUT_PATH)
	if err != OK:
		push_error("Échec sauvegarde %s: %s" % [OUTPUT_PATH, error_string(err)])
		quit(1)
		return

	print("OK: matériau grass_field (%s) généré." % OUTPUT_PATH)
	quit()
