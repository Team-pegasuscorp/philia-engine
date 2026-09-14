@tool
class_name PhiliaImporter
extends RefCounted

## Construit une scène Godot générique à partir d'un PhiliaMap.
## Ne décide d'aucun comportement de jeu (voir docs/concept.md §11) : chaque
## tuile/entité devient un Node2D porteur de métadonnées ("philia_type",
## "philia_entity") que le jeu qui importe la carte interprète à sa façon.
## Le ColorRect ajouté aux tuiles n'est qu'un aperçu visuel de secours.

const CELL_SIZE := 32
const TILE_COLORS := PhiliaGridCanvas.TILE_COLORS


static func build_scene(map: PhiliaMap, cell_size: int = CELL_SIZE) -> Node2D:
	var root := Node2D.new()
	root.name = "PhiliaMap"
	root.set_meta("philia_format_version", map.format_version)
	root.set_meta("philia_seed", map.seed)

	var tiles_root := Node2D.new()
	tiles_root.name = "Tiles"
	root.add_child(tiles_root)
	tiles_root.owner = root
	for tile in map.tiles:
		tiles_root.add_child(_build_tile_node(tile, cell_size))

	var entities_root := Node2D.new()
	entities_root.name = "Entities"
	root.add_child(entities_root)
	entities_root.owner = root
	for entity in map.entities:
		entities_root.add_child(_build_entity_node(entity))

	_set_owner_recursive(tiles_root, root)
	_set_owner_recursive(entities_root, root)
	return root


static func _build_tile_node(tile: Dictionary, cell_size: int) -> Node2D:
	var x: int = tile.get("x", 0)
	var y: int = tile.get("y", 0)
	var type: String = tile.get("type", "Sol")
	var rotation_deg: int = tile.get("rotation", 0)

	var node := Node2D.new()
	node.name = "Tile_%d_%d" % [x, y]
	node.position = Vector2(x, y) * cell_size
	node.rotation_degrees = rotation_deg
	node.set_meta("philia_type", type)

	var preview := ColorRect.new()
	preview.name = "Preview"
	preview.size = Vector2(cell_size, cell_size)
	preview.position = Vector2(cell_size, cell_size) * -0.5
	preview.color = TILE_COLORS.get(type, Color.GRAY)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(preview)
	preview.owner = node

	return node


static func _build_entity_node(entity: Dictionary) -> Node2D:
	var pos: Array = entity.get("position", [0, 0, 0])
	var node := Node2D.new()
	node.name = String(entity.get("entity", "entity"))
	node.position = Vector2(pos[0] if pos.size() > 0 else 0, pos[2] if pos.size() > 2 else 0)
	node.rotation_degrees = entity.get("rotation", 0)
	node.set_meta("philia_entity", entity.get("entity", ""))
	node.set_meta("philia_entity_state", entity.get("state", ""))
	return node


static func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)
