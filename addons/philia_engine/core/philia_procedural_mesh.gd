@tool
class_name PhiliaProceduralMesh
extends RefCounted

## Génère une géométrie procédurale à partir de paramètres + seed (doc §4/§5).
## Principe unique, réutilisable pour plusieurs types d'objets (§4 : "Le même
## principe peut servir pour : rochers, piliers, murs, tuyaux, falaises,
## colonnes, poutres, structures diverses") : partir d'un maillage de base
## (sphère, cylindre…) et déplacer chaque sommet le long de sa normale d'une
## quantité aléatoire mais reproductible pour un même seed.

## Rocher : déformation sur les 3 axes à partir d'une sphère.
static func generate_rock(params: Dictionary = {}) -> ArrayMesh:
	var faces: int = int(params.get("faces", 6))
	var size: Vector3 = params.get("size", Vector3.ONE)
	var randomness: float = clampf(params.get("randomness", 0.5), 0.0, 1.0)
	var seed_value: int = int(params.get("seed", 0))

	var base := SphereMesh.new()
	base.radius = 0.5
	base.height = 1.0
	base.radial_segments = clampi(faces, 4, 32)
	base.rings = clampi(int(faces * 0.6), 3, 24)

	return _deform(base, size, randomness, seed_value, true)


## Pilier/colonne : déformation horizontale seulement (la hauteur reste
## intacte) à partir d'un cylindre, pour rester reconnaissable comme pilier.
static func generate_pillar(params: Dictionary = {}) -> ArrayMesh:
	var faces: int = int(params.get("faces", 8))
	var size: Vector3 = params.get("size", Vector3(0.4, 1.0, 0.4))
	var randomness: float = clampf(params.get("randomness", 0.15), 0.0, 1.0)
	var seed_value: int = int(params.get("seed", 0))

	var base := CylinderMesh.new()
	base.top_radius = 0.5
	base.bottom_radius = 0.5
	base.height = 1.0
	base.radial_segments = clampi(faces, 4, 32)
	base.rings = 4

	return _deform(base, size, randomness, seed_value, false)


## Déplace chaque sommet du maillage de base le long de sa normale d'une
## quantité aléatoire (seedée par RandomNumberGenerator, donc reproductible),
## puis applique une taille non-uniforme. deform_y=false annule la
## composante verticale de la normale avant déplacement, pour garder une
## silhouette régulière en hauteur (pilier).
static func _deform(base: PrimitiveMesh, size: Vector3, randomness: float, seed_value: int, deform_y: bool) -> ArrayMesh:
	var source := ArrayMesh.new()
	source.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, base.surface_get_arrays(0))

	var mdt := MeshDataTool.new()
	mdt.create_from_surface(source, 0)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	for i in range(mdt.get_vertex_count()):
		var vertex := mdt.get_vertex(i)
		var normal := mdt.get_vertex_normal(i)
		if not deform_y:
			normal.y = 0.0
			if normal.length() > 0.0001:
				normal = normal.normalized()
		var displacement := rng.randf_range(-randomness, randomness) * 0.5
		vertex += normal * displacement
		vertex *= size
		mdt.set_vertex(i, vertex)

	var deformed := ArrayMesh.new()
	mdt.commit_to_surface(deformed)

	var st := SurfaceTool.new()
	st.create_from(deformed, 0)
	st.generate_normals()
	return st.commit()
