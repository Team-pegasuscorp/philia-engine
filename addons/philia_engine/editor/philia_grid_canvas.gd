@tool
class_name PhiliaGridCanvas
extends Control

## Grille de placement : clic gauche pose la tuile sélectionnée sur le calque
## actif, clic droit supprime, touche R fait pivoter la tuile survolée.
## Les autres calques restent visibles en transparence pour le contexte.
## Écrit directement dans un PhiliaMap (voir core/philia_map.gd).

signal tile_placed(x: int, y: int, type: String)
signal tile_removed(x: int, y: int)
signal tile_rotated(x: int, y: int)

const CELL_SIZE := 32
const GRID_CELLS := 24
const GRID_COLOR := Color(1, 1, 1, 0.15)
const INACTIVE_LAYER_ALPHA := 0.35
const TILE_COLORS := {
	"Sol": Color(0.35, 0.55, 0.35),
	"Mur": Color(0.5, 0.5, 0.55),
	"Coin": Color(0.55, 0.5, 0.4),
	"Bord": Color(0.45, 0.45, 0.5),
	"Terrain": Color(0.4, 0.6, 0.3),
	"Porte": Color(0.6, 0.4, 0.2),
	"Fenêtre": Color(0.3, 0.5, 0.7),
	"Escalier": Color(0.55, 0.55, 0.3),
	"Pilier": Color(0.5, 0.35, 0.55),
	"Caisse": Color(0.6, 0.45, 0.25),
	"Machine": Color(0.3, 0.6, 0.6),
	"Rocher": Color(0.5, 0.48, 0.45),
}

var map: PhiliaMap = PhiliaMap.new()
var selected_type: String = "Sol"
var active_layer: String = PhiliaMap.DEFAULT_LAYER
var hovered_cell: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	custom_minimum_size = Vector2(GRID_CELLS * CELL_SIZE, GRID_CELLS * CELL_SIZE)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_map(new_map: PhiliaMap) -> void:
	map = new_map
	if not map.layers.has(active_layer):
		active_layer = map.layers[0]
	queue_redraw()


func set_active_layer(layer: String) -> void:
	active_layer = layer
	queue_redraw()


func _draw() -> void:
	for x in range(GRID_CELLS + 1):
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, GRID_CELLS * CELL_SIZE), GRID_COLOR)
	for y in range(GRID_CELLS + 1):
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(GRID_CELLS * CELL_SIZE, y * CELL_SIZE), GRID_COLOR)

	for tile in map.tiles:
		var is_active: bool = tile.get("layer", PhiliaMap.DEFAULT_LAYER) == active_layer
		_draw_tile(tile, 1.0 if is_active else INACTIVE_LAYER_ALPHA)

	if _is_in_bounds(hovered_cell):
		var rect := Rect2(hovered_cell.x * CELL_SIZE, hovered_cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		draw_rect(rect, Color(1, 1, 1, 0.25), true)


func _draw_tile(tile: Dictionary, alpha: float) -> void:
	var x: int = tile.get("x", 0)
	var y: int = tile.get("y", 0)
	var w: int = tile.get("w", 1)
	var h: int = tile.get("h", 1)
	var type: String = tile.get("type", "Sol")
	var rect := Rect2(x * CELL_SIZE + 1, y * CELL_SIZE + 1, w * CELL_SIZE - 2, h * CELL_SIZE - 2)
	var color: Color = TILE_COLORS.get(type, Color.GRAY)
	color.a = alpha
	draw_rect(rect, color, true)
	var center := rect.get_center()

	if PhiliaMap.AUTOTILE_TYPES.has(type):
		_draw_autotile_connectors(center, int(tile.get("variant", 0)), alpha)
	else:
		var rotation_deg: int = tile.get("rotation", 0)
		var dir := Vector2.UP.rotated(deg_to_rad(rotation_deg))
		draw_line(center, center + dir * (CELL_SIZE * 0.3), Color(1, 1, 1, alpha), 2.0)


## Trace un trait de centre vers chaque voisin connecté (N/E/S/W selon le
## bitmask de variante) — retour visuel de l'autotiling, pas un vrai tileset.
func _draw_autotile_connectors(center: Vector2, variant: int, alpha: float) -> void:
	var line_color := Color(1, 1, 1, alpha)
	for bit in PhiliaMap.NEIGHBOR_OFFSETS:
		if variant & bit == 0:
			continue
		var offset: Vector2i = PhiliaMap.NEIGHBOR_OFFSETS[bit]
		var dir := Vector2(offset.x, offset.y)
		draw_line(center, center + dir * (CELL_SIZE * 0.5), line_color, 2.0)
	if variant == 0:
		draw_circle(center, 2.5, line_color)


func _is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_CELLS and cell.y < GRID_CELLS


func _cell_at(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.y / CELL_SIZE))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell := _cell_at(event.position)
		if cell != hovered_cell:
			hovered_cell = cell
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		grab_focus()
		var cell := _cell_at(event.position)
		if not _is_in_bounds(cell):
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			map.set_tile(cell.x, cell.y, selected_type, 0, active_layer)
			tile_placed.emit(cell.x, cell.y, selected_type)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			map.remove_tile(cell.x, cell.y, active_layer)
			tile_removed.emit(cell.x, cell.y)
			queue_redraw()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if _is_in_bounds(hovered_cell):
			map.rotate_tile(hovered_cell.x, hovered_cell.y, active_layer)
			tile_rotated.emit(hovered_cell.x, hovered_cell.y)
			queue_redraw()
