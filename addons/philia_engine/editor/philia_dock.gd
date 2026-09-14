@tool
extends Control

const PALETTE: Array[String] = [
	"Sol", "Mur", "Coin", "Bord", "Terrain",
	"Porte", "Fenêtre", "Escalier", "Pilier", "Caisse", "Machine",
]
const DEFAULT_MAP_PATH := "res://maps/example.philiamap"

@onready var _palette_list: ItemList = %PaletteList
@onready var _canvas: PhiliaGridCanvas = %GridCanvas
@onready var _status_label: Label = %StatusLabel
@onready var _path_edit: LineEdit = %PathEdit
@onready var _new_button: Button = %NewMapButton
@onready var _save_button: Button = %SaveMapButton
@onready var _load_button: Button = %LoadMapButton


func _ready() -> void:
	for type in PALETTE:
		_palette_list.add_item(type)
	_palette_list.select(0)
	_palette_list.item_selected.connect(_on_palette_item_selected)

	_path_edit.text = DEFAULT_MAP_PATH
	_new_button.pressed.connect(_on_new_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_load_button.pressed.connect(_on_load_pressed)

	_canvas.tile_placed.connect(_on_map_changed)
	_canvas.tile_removed.connect(_on_map_changed)
	_canvas.tile_rotated.connect(_on_map_changed)

	_update_status()


func _on_palette_item_selected(index: int) -> void:
	_canvas.selected_type = PALETTE[index]


func _on_new_pressed() -> void:
	_canvas.set_map(PhiliaMap.new())
	_update_status()


func _on_save_pressed() -> void:
	var path := _path_edit.text.strip_edges()
	if path.is_empty():
		_status_label.text = "Chemin de sauvegarde vide"
		return
	if path.begins_with("res://"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := _canvas.map.save(path)
	if err != OK:
		_status_label.text = "Erreur de sauvegarde (%s)" % error_string(err)
	else:
		_update_status("Carte sauvegardée dans %s" % path)


func _on_load_pressed() -> void:
	var path := _path_edit.text.strip_edges()
	var loaded := PhiliaMap.load(path)
	if loaded == null:
		_status_label.text = "Impossible de charger %s" % path
		return
	_canvas.set_map(loaded)
	_update_status("Carte chargée depuis %s" % path)


func _on_map_changed(_a = null, _b = null, _c = null) -> void:
	_update_status()


func _update_status(message: String = "") -> void:
	var base := "%d tuiles, %d entités" % [_canvas.map.tiles.size(), _canvas.map.entities.size()]
	_status_label.text = message if not message.is_empty() else base
