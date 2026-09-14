@tool
extends SceneTree

## Construit le TileSet de terrains Godot (TERRAIN_MODE_MATCH_SIDES) à partir
## de l'atlas généré par generate_terrain_atlas.gd. Le TileSet référence le
## PNG externe (pas d'image embarquée) pour rester un .tres léger et
## diffable. À lancer après un `--import` (l'atlas doit déjà être importé
## pour que `load()` le résolve) :
##
##   godot --headless --script res://addons/philia_engine/tools/generate_terrain_atlas.gd
##   godot --headless --import
##   godot --headless --script res://addons/philia_engine/tools/generate_terrain_tileset.gd
##
## Ou via le wrapper : addons/philia_engine/tools/regenerate_terrain_assets.sh

const TILE_SIZE := 32
const ATLAS_PATH := "res://addons/philia_engine/assets/terrain_atlas.png"
const TILESET_PATH := "res://addons/philia_engine/assets/philia_terrain_tileset.tres"

## Bits N/E/S/W identiques à PhiliaMap.NEIGHBOR_OFFSETS / PhiliaGridCanvas.
const SIDE_BITS := {
	1: TileSet.CELL_NEIGHBOR_TOP_SIDE,
	2: TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	4: TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	8: TileSet.CELL_NEIGHBOR_LEFT_SIDE,
}


func _initialize() -> void:
	var terrain_names: Array[String] = PhiliaMap.AUTOTILE_TYPES
	var terrain_colors: Dictionary = PhiliaGridCanvas.TILE_COLORS

	if not FileAccess.file_exists(ATLAS_PATH):
		push_error("Atlas introuvable (%s) : lance d'abord generate_terrain_atlas.gd puis --import." % ATLAS_PATH)
		quit(1)
		return

	var atlas_texture: Texture2D = load(ATLAS_PATH)
	if atlas_texture == null:
		push_error("Impossible de charger l'atlas (%s) : as-tu lancé --import entre les deux scripts ?" % ATLAS_PATH)
		quit(1)
		return

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	tileset.add_terrain_set()
	var terrain_set := tileset.get_terrain_sets_count() - 1
	tileset.set_terrain_set_mode(terrain_set, TileSet.TERRAIN_MODE_MATCH_SIDES)
	for terrain_index in range(terrain_names.size()):
		tileset.add_terrain(terrain_set)
		tileset.set_terrain_name(terrain_set, terrain_index, terrain_names[terrain_index])
		tileset.set_terrain_color(terrain_set, terrain_index, terrain_colors.get(terrain_names[terrain_index], Color.GRAY))

	tileset.add_physics_layer()
	var physics_layer := tileset.get_physics_layers_count() - 1
	var half := TILE_SIZE / 2.0
	var full_tile_polygon := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half),
	])

	var source := TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tileset.add_source(source)

	for row in range(terrain_names.size()):
		var solid: bool = PhiliaMap.DEFAULT_SOLID_TYPES.has(terrain_names[row])
		for bitmask in range(16):
			var coords := Vector2i(bitmask, row)
			source.create_tile(coords)
			var tile_data := source.get_tile_data(coords, 0)
			tile_data.terrain_set = terrain_set
			tile_data.terrain = row
			for bit in SIDE_BITS:
				if bitmask & bit != 0:
					tile_data.set_terrain_peering_bit(SIDE_BITS[bit], row)
			if solid:
				tile_data.add_collision_polygon(physics_layer)
				tile_data.set_collision_polygon_points(physics_layer, 0, full_tile_polygon)

	var err := ResourceSaver.save(tileset, TILESET_PATH)
	if err != OK:
		push_error("Échec sauvegarde TileSet: %s" % error_string(err))
		quit(1)
		return

	print("OK: TileSet généré (%s)." % TILESET_PATH)
	quit()
