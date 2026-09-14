@tool
extends SceneTree

## Génère l'atlas placeholder utilisé par le TileSet de terrains
## (voir generate_terrain_tileset.gd, à lancer après un `--import`).
## Une colonne par bitmask (0-15, convention N/E/S/W partagée avec
## PhiliaMap.NEIGHBOR_OFFSETS), une ligne par terrain de
## PhiliaMap.AUTOTILE_TYPES. Chaque tuile est remplie de la couleur du
## terrain, avec une marge transparente sur les côtés non connectés
## (aperçu Wang-tile simplifié, à remplacer par du vrai art plus tard).

const TILE_SIZE := 32
const MARGIN := 6
const ATLAS_PATH := "res://addons/philia_engine/assets/terrain_atlas.png"


func _initialize() -> void:
	var terrain_names: Array[String] = PhiliaMap.AUTOTILE_TYPES
	var terrain_colors: Dictionary = PhiliaGridCanvas.TILE_COLORS

	var width := TILE_SIZE * 16
	var height := TILE_SIZE * terrain_names.size()
	var atlas := Image.create(width, height, false, Image.FORMAT_RGBA8)

	for row in range(terrain_names.size()):
		var color: Color = terrain_colors.get(terrain_names[row], Color.GRAY)
		for bitmask in range(16):
			var tile := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
			tile.fill(color)
			if bitmask & 1 == 0: # N
				tile.fill_rect(Rect2i(0, 0, TILE_SIZE, MARGIN), Color(0, 0, 0, 0))
			if bitmask & 2 == 0: # E
				tile.fill_rect(Rect2i(TILE_SIZE - MARGIN, 0, MARGIN, TILE_SIZE), Color(0, 0, 0, 0))
			if bitmask & 4 == 0: # S
				tile.fill_rect(Rect2i(0, TILE_SIZE - MARGIN, TILE_SIZE, MARGIN), Color(0, 0, 0, 0))
			if bitmask & 8 == 0: # W
				tile.fill_rect(Rect2i(0, 0, MARGIN, TILE_SIZE), Color(0, 0, 0, 0))
			atlas.blit_rect(tile, Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Vector2i(bitmask * TILE_SIZE, row * TILE_SIZE))

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ATLAS_PATH.get_base_dir()))
	var err := atlas.save_png(ATLAS_PATH)
	if err != OK:
		push_error("Échec sauvegarde atlas: %s" % error_string(err))
		quit(1)
		return

	print("OK: atlas généré (%s)." % ATLAS_PATH)
	quit()
