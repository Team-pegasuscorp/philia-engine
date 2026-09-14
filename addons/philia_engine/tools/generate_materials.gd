@tool
extends SceneTree

## Génère les matériaux placeholder référencés par PhiliaMap.DEFAULT_MATERIALS
## (couleur + roughness/metallic seulement, pas de textures — à remplacer par
## du vrai art plus tard, même chemins de fichiers).
##
##   godot --headless --script res://addons/philia_engine/tools/generate_materials.gd

const MATERIALS_DIR := "res://addons/philia_engine/assets/materials"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MATERIALS_DIR))

	var ok := true
	ok = _save("stone", Color(0.55, 0.53, 0.5), 0.9, 0.0) and ok
	ok = _save("wood", Color(0.45, 0.3, 0.18), 0.7, 0.0) and ok
	ok = _save("rusty_metal", Color(0.45, 0.25, 0.15), 0.6, 0.7) and ok

	if not ok:
		quit(1)
		return

	print("OK: matériaux placeholder générés dans %s" % MATERIALS_DIR)
	quit()


func _save(material_name: String, color: Color, roughness: float, metallic: float) -> bool:
	var mat := PhiliaMaterial.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	var path := "%s/%s.tres" % [MATERIALS_DIR, material_name]
	var err := ResourceSaver.save(mat, path)
	if err != OK:
		push_error("Échec sauvegarde %s: %s" % [material_name, error_string(err)])
		return false
	return true
