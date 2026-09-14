@tool
class_name PhiliaImporter3D
extends RefCounted

## Construit une scène Godot 3D générique à partir d'un PhiliaMap — pendant
## 3D de PhiliaImporter (2D). Le .philiamap ne contient que des indices de
## grille (x, y, type, rotation, layer), aucune notion d'unité 2D ou 3D :
## c'est l'importeur qui projette vers un espace de rendu (§20 du concept).
##
## Convention : la case (x, y) de la carte devient la position 3D (x, 0, y)
## — le plan XZ est le plan du sol, Y est la hauteur.
##
## Les types autotile (PhiliaMap.AUTOTILE_TYPES) sont placés dans un GridMap
## (un par calque) via la MeshLibrary générée par
## tools/generate_terrain_meshlibrary.gd. Pas de logique de raccord à gérer
## ici : des blocs 3D pleins qui se touchent se connectent visuellement tout
## seuls, contrairement aux sprites 2D. Les autres tuiles (Coin/Bord posés à
## la main, modules) et les entités restent des Node3D + MeshInstance3D de
## secours, avec le même PhiliaMaterial que la version 2D (§6) — ici
## pleinement exploité via un vrai StandardMaterial3D (roughness/metallic/
## normal/height).

const CELL_SIZE := 1.0
const TILE_COLORS := PhiliaGridCanvas.TILE_COLORS
const TERRAIN_MESH_LIBRARY: MeshLibrary = preload("res://addons/philia_engine/assets/philia_terrain_meshlibrary.tres")


static func build_scene(map: PhiliaMap, cell_size: float = CELL_SIZE) -> Node3D:
	var root := Node3D.new()
	root.name = "PhiliaMap3D"
	root.set_meta("philia_format_version", map.format_version)
	root.set_meta("philia_seed", map.seed)

	var tiles_root := Node3D.new()
	tiles_root.name = "Tiles"
	root.add_child(tiles_root)

	var layer_nodes := {}
	var grid_maps := {} # layer_name -> GridMap

	var ensure_layer := func(layer_name: String) -> Node3D:
		if not layer_nodes.has(layer_name):
			var layer_node := Node3D.new()
			layer_node.name = layer_name
			tiles_root.add_child(layer_node)
			layer_nodes[layer_name] = layer_node
		return layer_nodes[layer_name]

	for layer_name in map.layers:
		ensure_layer.call(layer_name)

	for tile in map.tiles:
		var layer_name: String = tile.get("layer", PhiliaMap.DEFAULT_LAYER)
		var layer_node: Node3D = ensure_layer.call(layer_name)
		var type: String = tile.get("type", "Sol")

		if PhiliaMap.AUTOTILE_TYPES.has(type):
			if not grid_maps.has(layer_name):
				var grid_map := GridMap.new()
				grid_map.name = "Terrain"
				grid_map.mesh_library = TERRAIN_MESH_LIBRARY
				grid_map.cell_size = Vector3(cell_size, cell_size, cell_size)
				layer_node.add_child(grid_map)
				grid_maps[layer_name] = grid_map
			var item_id: int = PhiliaMap.AUTOTILE_TYPES.find(type)
			grid_maps[layer_name].set_cell_item(Vector3i(tile.get("x", 0), 0, tile.get("y", 0)), item_id)
		else:
			layer_node.add_child(_build_tile_node(tile, cell_size, map.seed))

	var entities_root := Node3D.new()
	entities_root.name = "Entities"
	root.add_child(entities_root)
	for entity in map.entities:
		entities_root.add_child(_build_entity_node(entity))

	_set_owner_recursive(tiles_root, root)
	tiles_root.owner = root
	_set_owner_recursive(entities_root, root)
	entities_root.owner = root
	return root


static func _build_tile_node(tile: Dictionary, cell_size: float, map_seed: int) -> Node3D:
	var x: int = tile.get("x", 0)
	var y: int = tile.get("y", 0)
	var w: int = tile.get("w", 1)
	var h: int = tile.get("h", 1)
	var type: String = tile.get("type", "Sol")
	var rotation_deg: int = tile.get("rotation", 0)
	var footprint_size := Vector3(w, 1, h) * cell_size
	## Centre de l'empreinte au sol (Y=0), même repère XZ que le GridMap
	## des terrains (case (0,0) -> origine monde).
	var position := Vector3(x, 0, y) * cell_size + Vector3(footprint_size.x, 0, footprint_size.z) * 0.5

	if type == "Spawn":
		return _build_spawn_node(tile, position, rotation_deg)
	if type == "Trigger":
		return _build_trigger_node(tile, position, rotation_deg, footprint_size)

	var solid := PhiliaMap.is_solid(tile)

	var node := Node3D.new()
	node.name = "Tile_%d_%d" % [x, y]
	node.position = position
	node.rotation_degrees.y = rotation_deg
	node.set_meta("philia_type", type)
	node.set_meta("philia_solid", solid)
	if w > 1 or h > 1:
		node.set_meta("philia_footprint", Vector2i(w, h))

	var material_path := PhiliaMap.material_for(tile)
	var material: PhiliaMaterial = null
	if material_path != "" and ResourceLoader.exists(material_path):
		material = load(material_path)
	if material:
		node.set_meta("philia_material", material_path)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"

	var procedural_kind: String = PhiliaMap.PROCEDURAL_TYPES.get(type, "")
	if procedural_kind != "":
		var gen_seed := PhiliaMap.seed_for(tile, map_seed)
		mesh_instance.mesh = _build_procedural_mesh(procedural_kind, footprint_size, gen_seed)
	else:
		var box := BoxMesh.new()
		box.size = footprint_size
		mesh_instance.mesh = box

	mesh_instance.position = Vector3(0, footprint_size.y * 0.5, 0)
	mesh_instance.material_override = build_standard_material(material) if material else _flat_color_material(TILE_COLORS.get(type, Color.GRAY))
	node.add_child(mesh_instance)

	if solid:
		node.add_child(_build_collision_body(footprint_size))

	return node


## Spawn (§7) : simple repère de position, sans géométrie ni collision — le
## jeu qui importe la carte décide quoi instancier à cet endroit. Regroupé
## dans "philia_spawns" pour être retrouvé via get_nodes_in_group().
static func _build_spawn_node(tile: Dictionary, position: Vector3, rotation_deg: int) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = "Spawn_%d_%d" % [tile.get("x", 0), tile.get("y", 0)]
	marker.position = position
	marker.rotation_degrees.y = rotation_deg
	marker.set_meta("philia_type", "Spawn")
	if tile.has("id"):
		marker.set_meta("philia_spawn_id", tile["id"])
	marker.add_to_group("philia_spawns")
	return marker


## Trigger (§7, V6) : zone de détection fonctionnelle (PhiliaTriggerArea3D),
## sans comportement propre — le jeu se connecte à triggered/body_entered
## (§20). Regroupé dans "philia_triggers".
static func _build_trigger_node(tile: Dictionary, position: Vector3, rotation_deg: int, footprint_size: Vector3) -> PhiliaTriggerArea3D:
	var area := PhiliaTriggerArea3D.new()
	area.name = "Trigger_%d_%d" % [tile.get("x", 0), tile.get("y", 0)]
	area.position = position
	area.rotation_degrees.y = rotation_deg
	area.set_meta("philia_type", "Trigger")
	if tile.has("id"):
		area.set_meta("philia_trigger_id", tile["id"])
	area.add_to_group("philia_triggers")

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = footprint_size
	shape.shape = box
	shape.position = Vector3(0, footprint_size.y * 0.5, 0)
	area.add_child(shape)

	return area


static func _build_procedural_mesh(kind: String, size: Vector3, gen_seed: int) -> ArrayMesh:
	var params := {"size": size, "seed": gen_seed}
	match kind:
		"rock":
			return PhiliaProceduralMesh.generate_rock(params)
		"pillar":
			return PhiliaProceduralMesh.generate_pillar(params)
	return PhiliaProceduralMesh.generate_rock(params)


## Construit un StandardMaterial3D à partir d'un PhiliaMaterial (§6) —
## public : réutilisé aussi par les scènes de démo (voir
## tools/generate_demo_playable_scene.gd) pour ne pas dupliquer ce mapping.
static func build_standard_material(mat: PhiliaMaterial) -> StandardMaterial3D:
	var sm := StandardMaterial3D.new()
	sm.albedo_color = mat.albedo_color
	if mat.albedo_texture:
		sm.albedo_texture = mat.albedo_texture
	if mat.normal_texture:
		sm.normal_enabled = true
		sm.normal_texture = mat.normal_texture
	if mat.orm_texture:
		## Convention tile-gen : R=roughness, G=metallic, B=AO packés dans
		## une seule texture — Godot multiplie chaque canal par le
		## scalaire correspondant, donc 1.0 comme facteur pour laisser la
		## texture piloter entièrement roughness/metallic.
		sm.roughness = 1.0
		sm.roughness_texture = mat.orm_texture
		sm.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		sm.metallic = 1.0
		sm.metallic_texture = mat.orm_texture
		sm.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		sm.ao_enabled = true
		sm.ao_texture = mat.orm_texture
		sm.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	else:
		sm.roughness = mat.roughness
		sm.metallic = mat.metallic
	if mat.height_texture:
		sm.heightmap_enabled = true
		sm.heightmap_texture = mat.height_texture
	return sm


static func _flat_color_material(color: Color) -> StandardMaterial3D:
	var sm := StandardMaterial3D.new()
	sm.albedo_color = color
	return sm


static func _build_collision_body(size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Collision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(shape)
	return body


static func _build_entity_node(entity: Dictionary) -> Node3D:
	var pos: Array = entity.get("position", [0, 0, 0])
	var node := Node3D.new()
	node.name = String(entity.get("entity", "entity"))
	node.position = Vector3(
		pos[0] if pos.size() > 0 else 0,
		pos[1] if pos.size() > 1 else 0,
		pos[2] if pos.size() > 2 else 0
	)
	node.rotation_degrees.y = entity.get("rotation", 0)
	node.set_meta("philia_entity", entity.get("entity", ""))
	node.set_meta("philia_entity_state", entity.get("state", ""))
	return node


static func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)
