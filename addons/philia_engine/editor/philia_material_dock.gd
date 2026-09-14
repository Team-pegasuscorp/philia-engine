@tool
extends Control

## Éditeur de PhiliaMaterial (§6) : parcourt/édite les .tres du dossier
## MATERIALS_DIR. Chaque champ texture prend un chemin res:// texte (pas
## de sélecteur de fichier graphique pour rester simple et testable
## headless) — colle le chemin d'une texture déjà importée dans le
## projet. roughness/metallic (scalaires) ne servent que si aucun
## orm_texture n'est renseigné (voir PhiliaImporter3D.build_standard_material).

const MATERIALS_DIR := "res://addons/philia_engine/assets/materials"

@onready var _material_list: ItemList = %MaterialList
@onready var _material_id_edit: LineEdit = %MaterialIdEdit
@onready var _albedo_color_picker: ColorPickerButton = %AlbedoColorPicker
@onready var _albedo_texture_edit: LineEdit = %AlbedoTextureEdit
@onready var _normal_texture_edit: LineEdit = %NormalTextureEdit
@onready var _orm_texture_edit: LineEdit = %OrmTextureEdit
@onready var _height_texture_edit: LineEdit = %HeightTextureEdit
@onready var _roughness_spin: SpinBox = %RoughnessSpin
@onready var _metallic_spin: SpinBox = %MetallicSpin
@onready var _new_button: Button = %NewMaterialButton
@onready var _delete_button: Button = %DeleteMaterialButton
@onready var _apply_button: Button = %ApplyMaterialButton
@onready var _status_label: Label = %MaterialStatusLabel

var _selected_material_id := ""  ## voir philia_gameplay_dock.gd pour le même principe (renommer vs dupliquer)


func _ready() -> void:
	_new_button.pressed.connect(_on_new_pressed)
	_delete_button.pressed.connect(_on_delete_pressed)
	_apply_button.pressed.connect(_on_apply_pressed)
	_material_list.item_selected.connect(_on_material_selected)
	_refresh_material_list()


func _refresh_material_list() -> void:
	_material_list.clear()
	var dir := DirAccess.open(MATERIALS_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var entries: Array[String] = []
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".tres"):
			entries.append(entry.get_basename())
		entry = dir.get_next()
	entries.sort()
	for material_id in entries:
		_material_list.add_item(material_id)


func _material_path(material_id: String) -> String:
	return "%s/%s.tres" % [MATERIALS_DIR, material_id]


func _on_material_selected(index: int) -> void:
	var material_id := _material_list.get_item_text(index)
	_selected_material_id = material_id
	var mat: PhiliaMaterial = load(_material_path(material_id))
	_material_id_edit.text = material_id
	_albedo_color_picker.color = mat.albedo_color
	_albedo_texture_edit.text = mat.albedo_texture.resource_path if mat.albedo_texture else ""
	_normal_texture_edit.text = mat.normal_texture.resource_path if mat.normal_texture else ""
	_orm_texture_edit.text = mat.orm_texture.resource_path if mat.orm_texture else ""
	_height_texture_edit.text = mat.height_texture.resource_path if mat.height_texture else ""
	_roughness_spin.value = mat.roughness
	_metallic_spin.value = mat.metallic


func _on_new_pressed() -> void:
	_clear_form()
	_material_id_edit.text = _unique_id("materiau")


func _clear_form() -> void:
	_selected_material_id = ""
	_material_id_edit.text = ""
	_albedo_color_picker.color = Color.WHITE
	_albedo_texture_edit.text = ""
	_normal_texture_edit.text = ""
	_orm_texture_edit.text = ""
	_height_texture_edit.text = ""
	_roughness_spin.value = 1.0
	_metallic_spin.value = 0.0


func _on_delete_pressed() -> void:
	var selected := _material_list.get_selected_items()
	if selected.is_empty():
		return
	var material_id := _material_list.get_item_text(selected[0])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_material_path(material_id)))
	var uid_path := _material_path(material_id) + ".uid"
	if FileAccess.file_exists(uid_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(uid_path))
	_refresh_material_list()
	_clear_form()
	_status_label.text = "Matériau \"%s\" supprimé" % material_id


## Charge un chemin de texture texte en Texture2D, ou null si vide/absent.
func _load_texture(path: String) -> Texture2D:
	path = path.strip_edges()
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path)


func _on_apply_pressed() -> void:
	var material_id := _material_id_edit.text.strip_edges()
	if material_id.is_empty():
		return
	## Renomme (retire l'ancien fichier) plutôt que de laisser un .tres
	## fantôme sous l'ancien id — même principe que philia_gameplay_dock.gd.
	if _selected_material_id != "" and _selected_material_id != material_id:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_material_path(_selected_material_id)))

	var mat := PhiliaMaterial.new()
	mat.albedo_color = _albedo_color_picker.color
	mat.albedo_texture = _load_texture(_albedo_texture_edit.text)
	mat.normal_texture = _load_texture(_normal_texture_edit.text)
	mat.orm_texture = _load_texture(_orm_texture_edit.text)
	mat.height_texture = _load_texture(_height_texture_edit.text)
	mat.roughness = _roughness_spin.value
	mat.metallic = _metallic_spin.value

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MATERIALS_DIR))
	var err := ResourceSaver.save(mat, _material_path(material_id))
	if err != OK:
		_status_label.text = "Erreur de sauvegarde (%s)" % error_string(err)
		return

	_selected_material_id = material_id
	_refresh_material_list()
	_select_item_by_text(material_id)
	_status_label.text = "Matériau \"%s\" appliqué" % material_id


func _unique_id(prefix: String) -> String:
	var n := 1
	var candidate := "%s_%d" % [prefix, n]
	while ResourceLoader.exists(_material_path(candidate)):
		n += 1
		candidate = "%s_%d" % [prefix, n]
	return candidate


func _select_item_by_text(text: String) -> void:
	for i in range(_material_list.item_count):
		if _material_list.get_item_text(i) == text:
			_material_list.select(i)
			return
