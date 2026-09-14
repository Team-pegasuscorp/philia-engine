@tool
class_name PhiliaImporter
extends RefCounted

## Construit une scène Godot générique à partir d'un PhiliaMap.
## Ne décide d'aucun comportement de jeu (voir docs/concept.md §11) : chaque
## tuile/entité devient un node porteur de métadonnées ("philia_type",
## "philia_entity") que le jeu qui importe la carte interprète à sa façon.
##
## Les types autotile (PhiliaMap.AUTOTILE_TYPES) sont peints dans un vrai
## TileMapLayer via le TileSet de terrains généré par
## tools/generate_terrain_tileset.gd (§8/§20 du concept : ne pas
## réinventer ce que Godot fait déjà bien). Les autres tuiles (Coin/Bord
## posés à la main, modules) restent des Node2D + ColorRect de secours.

const CELL_SIZE := 32
const TILE_COLORS := PhiliaGridCanvas.TILE_COLORS
const TERRAIN_SET_INDEX := 0
const TERRAIN_TILESET: TileSet = preload("res://addons/philia_engine/assets/philia_terrain_tileset.tres")


static func build_scene(map: PhiliaMap, cell_size: int = CELL_SIZE) -> Node2D:
	var root := Node2D.new()
	root.name = "PhiliaMap"
	root.set_meta("philia_format_version", map.format_version)
	root.set_meta("philia_seed", map.seed)

	var tiles_root := Node2D.new()
	tiles_root.name = "Tiles"
	root.add_child(tiles_root)

	var layer_nodes := {}
	var autotile_cells := {} # layer_name -> { type: Array[Vector2i] }

	var ensure_layer := func(layer_name: String) -> Node2D:
		if not layer_nodes.has(layer_name):
			var layer_node := Node2D.new()
			layer_node.name = layer_name
			tiles_root.add_child(layer_node)
			layer_nodes[layer_name] = layer_node
			autotile_cells[layer_name] = {}
		return layer_nodes[layer_name]

	for layer_name in map.layers:
		ensure_layer.call(layer_name)

	for tile in map.tiles:
		var layer_name: String = tile.get("layer", PhiliaMap.DEFAULT_LAYER)
		var layer_node: Node2D = ensure_layer.call(layer_name)
		var type: String = tile.get("type", "Sol")

		if PhiliaMap.AUTOTILE_TYPES.has(type):
			var by_type: Dictionary = autotile_cells[layer_name]
			if not by_type.has(type):
				by_type[type] = []
			by_type[type].append(Vector2i(tile.get("x", 0), tile.get("y", 0)))
		else:
			layer_node.add_child(_build_tile_node(tile, cell_size))

	for layer_name in autotile_cells:
		var by_type: Dictionary = autotile_cells[layer_name]
		if by_type.is_empty():
			continue
		var tile_map := TileMapLayer.new()
		tile_map.name = "Terrain"
		tile_map.tile_set = TERRAIN_TILESET
		layer_nodes[layer_name].add_child(tile_map)
		for type in by_type:
			var terrain_index: int = PhiliaMap.AUTOTILE_TYPES.find(type)
			tile_map.set_cells_terrain_connect(by_type[type], TERRAIN_SET_INDEX, terrain_index, true)

	var entities_root := Node2D.new()
	entities_root.name = "Entities"
	root.add_child(entities_root)
	for entity in map.entities:
		entities_root.add_child(_build_entity_node(entity))

	_set_owner_recursive(tiles_root, root)
	tiles_root.owner = root
	_set_owner_recursive(entities_root, root)
	entities_root.owner = root
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
