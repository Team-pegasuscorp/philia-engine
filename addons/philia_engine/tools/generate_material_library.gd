@tool
extends SceneTree

## Assemble une bibliothèque de PhiliaMaterial (§6) à partir de textures
## seamless générées par tile-gen (générateur de tuiles procédurales via
## Blender headless, hors de ce dépôt) et déjà copiées dans
## assets/materials/textures/<dossier>/. Chaque entrée suppose 4 fichiers :
## <id>_albedo.png, _normal.png, _orm.png (R=roughness/G=metal/B=AO),
## _height.png.
##
## Les ids "stone"/"wood"/"rusty_metal" remplacent volontairement les
## placeholders couleur plate de generate_materials.gd — ce sont les
## chemins déjà référencés par PhiliaMap.DEFAULT_MATERIALS (Pilier/Rocher,
## Caisse, Machine), donc tout ce qui les utilise gagne de vraies textures
## sans changer une ligne de code.
##
##   godot --headless --script res://addons/philia_engine/tools/generate_material_library.gd

const TEXTURES_ROOT := "res://addons/philia_engine/assets/materials/textures"
const MATERIALS_DIR := "res://addons/philia_engine/assets/materials"

## id du matériau (nom du .tres) -> dossier de textures correspondant.
const ENTRIES := {
	"stone": "stone_floor",
	"wood": "wood_planks",
	"rusty_metal": "rusty_metal",
	"brick_wall": "brick_wall",
	"dirt_ground": "dirt_ground",
	"rock_wall": "rock_wall",
	"clean_hull": "clean_hull",
	"concrete_wall": "concrete_wall",
	"sand_ground": "sand_ground",
	"grass_field": "grass_field",
}


func _initialize() -> void:
	var ok := true
	for material_id in ENTRIES:
		ok = _build(material_id, ENTRIES[material_id]) and ok

	if not ok:
		quit(1)
		return
	print("OK: %d matériau(x) générés dans %s" % [ENTRIES.size(), MATERIALS_DIR])
	quit()


func _build(material_id: String, texture_dir: String) -> bool:
	var base := "%s/%s/%s" % [TEXTURES_ROOT, texture_dir, texture_dir]
	var mat := PhiliaMaterial.new()
	mat.albedo_texture = load("%s_albedo.png" % base)
	mat.normal_texture = load("%s_normal.png" % base)
	mat.orm_texture = load("%s_orm.png" % base)
	mat.height_texture = load("%s_height.png" % base)

	if mat.albedo_texture == null:
		push_error("Texture introuvable pour \"%s\" (%s_albedo.png)" % [material_id, base])
		return false

	var path := "%s/%s.tres" % [MATERIALS_DIR, material_id]
	var err := ResourceSaver.save(mat, path)
	if err != OK:
		push_error("Échec sauvegarde %s: %s" % [path, error_string(err)])
		return false
	return true
