@tool
extends SceneTree

## Génère la MeshLibrary placeholder utilisée par PhiliaImporter3D pour les
## types autotile (PhiliaMap.AUTOTILE_TYPES). Contrairement au TileSet 2D,
## pas besoin de 16 variantes par bitmask : en 3D, des blocs pleins qui se
## touchent se raccordent visuellement tout seuls (pas de sprite de bord/coin
## à choisir) — GridMap place directement un item par cellule.
##
##   godot --headless --script res://addons/philia_engine/tools/generate_terrain_meshlibrary.gd

const MESHLIB_PATH := "res://addons/philia_engine/assets/philia_terrain_meshlibrary.tres"
const WALL_HEIGHT := 1.0
const FLOOR_THICKNESS := 0.1


func _initialize() -> void:
	var terrain_names: Array[String] = PhiliaMap.AUTOTILE_TYPES
	var terrain_colors: Dictionary = PhiliaGridCanvas.TILE_COLORS

	var lib := MeshLibrary.new()
	for i in range(terrain_names.size()):
		var terrain_name: String = terrain_names[i]
		var is_wall := terrain_name == "Mur"
		var height := WALL_HEIGHT if is_wall else FLOOR_THICKNESS

		var mesh := BoxMesh.new()
		mesh.size = Vector3(1, height, 1)
		var material := StandardMaterial3D.new()
		material.albedo_color = terrain_colors.get(terrain_name, Color.GRAY)
		mesh.material = material

		var offset := Transform3D(Basis(), Vector3(0, height * 0.5, 0))

		lib.create_item(i)
		lib.set_item_name(i, terrain_name)
		lib.set_item_mesh(i, mesh)
		lib.set_item_mesh_transform(i, offset)

		var shape := BoxShape3D.new()
		shape.size = mesh.size
		lib.set_item_shapes(i, [shape, offset])

	var err := ResourceSaver.save(lib, MESHLIB_PATH)
	if err != OK:
		push_error("Échec sauvegarde MeshLibrary: %s" % error_string(err))
		quit(1)
		return

	print("OK: MeshLibrary générée (%s)." % MESHLIB_PATH)
	quit()
