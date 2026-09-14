@tool
extends Control

signal import_requested(map: PhiliaMap)

const PALETTE: Array[String] = [
	"Sol", "Mur", "Coin", "Bord", "Terrain",
	"Porte", "Fenêtre", "Escalier", "Pilier", "Caisse", "Machine", "Rocher",
	"Plaine", "Forêt", "Désert", "Plage", "Neige", "Marais", "Montagne", "Eau",
]
const DEFAULT_MAP_PATH := "res://maps/example.philiamap"

@onready var _palette_list: ItemList = %PaletteList
@onready var _canvas: PhiliaGridCanvas = %GridCanvas
@onready var _status_label: Label = %StatusLabel
@onready var _path_edit: LineEdit = %PathEdit
@onready var _new_button: Button = %NewMapButton
@onready var _save_button: Button = %SaveMapButton
@onready var _load_button: Button = %LoadMapButton
@onready var _import_button: Button = %ImportSceneButton
@onready var _layer_option: OptionButton = %LayerOption
@onready var _new_layer_edit: LineEdit = %NewLayerEdit
@onready var _add_layer_button: Button = %AddLayerButton


func _ready() -> void:
	for type in PALETTE:
		_palette_list.add_item(type)
	_palette_list.select(0)
	_palette_list.item_selected.connect(_on_palette_item_selected)

	_path_edit.text = DEFAULT_MAP_PATH
	_new_button.pressed.connect(_on_new_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	_import_button.pressed.connect(_on_import_pressed)
	_add_layer_button.pressed.connect(_on_add_layer_pressed)
	_layer_option.item_selected.connect(_on_layer_selected)

	_canvas.tile_placed.connect(_on_map_changed)
	_canvas.tile_removed.connect(_on_map_changed)
	_canvas.tile_rotated.connect(_on_map_changed)

	_refresh_layers()
	_update_status()


func set_status(text: String) -> void:
	_status_label.text = text


func _on_import_pressed() -> void:
	import_requested.emit(_canvas.map)


func _on_palette_item_selected(index: int) -> void:
	_canvas.selected_type = PALETTE[index]


func _on_layer_selected(index: int) -> void:
	_canvas.set_active_layer(_layer_option.get_item_text(index))


func _on_add_layer_pressed() -> void:
	var layer_name := _new_layer_edit.text.strip_edges()
	if layer_name.is_empty():
		return
	_canvas.map.add_layer(layer_name)
	_new_layer_edit.text = ""
	_refresh_layers()
	_canvas.set_active_layer(layer_name)
	_select_layer_in_option(layer_name)


func _refresh_layers() -> void:
	_layer_option.clear()
	for layer_name in _canvas.map.layers:
		_layer_option.add_item(layer_name)
	_select_layer_in_option(_canvas.active_layer)


func _select_layer_in_option(layer_name: String) -> void:
	for i in range(_layer_option.item_count):
		if _layer_option.get_item_text(i) == layer_name:
			_layer_option.select(i)
			return


func _on_new_pressed() -> void:
	_canvas.set_map(PhiliaMap.new())
	_refresh_layers()
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
	_refresh_layers()
	_update_status("Carte chargée depuis %s" % path)


func _on_map_changed(_a = null, _b = null, _c = null) -> void:
	_update_status()


func _update_status(message: String = "") -> void:
	var base := "%d tuiles, %d entités — calque actif : %s" % [
		_canvas.map.tiles.size(), _canvas.map.entities.size(), _canvas.active_layer
	]
	_status_label.text = message if not message.is_empty() else base
