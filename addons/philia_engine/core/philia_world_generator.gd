@tool
class_name PhiliaWorldGenerator
extends RefCounted

## Génère une carte procédurale par bruit (doc §9) :
##
##   SEED -> Noise hauteur -> Heightmap -> Biomes -> Objets/végétation
##
## Godot fournit déjà Perlin/Simplex (FastNoiseLite) — pas la peine de
## réinventer un générateur de bruit (§20). Trois couches déterminent
## altitude/humidité/température par case (§9 : "Noise 1 → altitude, Noise 2
## → humidité, Noise 3 → température"), combinées en un biome ; une 4e
## couche "détail" à plus haute fréquence est mélangée à l'altitude pour
## éviter un relief trop lisse.
##
## Reproductible : même seed -> même carte (les 4 couches de bruit et le RNG
## de dispersion des objets sont tous dérivés du seed passé en paramètre).

const LAYER_NAME := "Terrain"
const DECOR_LAYER_NAME := "Décor"


static func generate(width: int, height: int, seed_value: int, params: Dictionary = {}) -> PhiliaMap:
	var frequency: float = params.get("frequency", 0.08)
	var detail_weight: float = clampf(params.get("detail_weight", 0.2), 0.0, 1.0)
	var vegetation_density: float = clampf(params.get("vegetation_density", 0.08), 0.0, 1.0)

	var elevation_noise := _make_noise(seed_value, frequency)
	var humidity_noise := _make_noise(seed_value + 1000, frequency * 0.8)
	var temperature_noise := _make_noise(seed_value + 2000, frequency * 0.6)
	var detail_noise := _make_noise(seed_value + 3000, frequency * 4.0)

	var map := PhiliaMap.new()
	map.seed = seed_value
	map.layers = [LAYER_NAME, DECOR_LAYER_NAME]

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	for x in range(width):
		for y in range(height):
			var elevation := elevation_noise.get_noise_2d(x, y) * (1.0 - detail_weight) \
				+ detail_noise.get_noise_2d(x, y) * detail_weight
			var humidity := humidity_noise.get_noise_2d(x, y)
			var temperature := temperature_noise.get_noise_2d(x, y)

			var biome := classify(elevation, humidity, temperature)
			map.set_tile(x, y, biome, 0, LAYER_NAME)

			if biome == "Montagne" and rng.randf() < vegetation_density:
				map.set_tile(x, y, "Rocher", 0, DECOR_LAYER_NAME)
			elif biome == "Forêt" and rng.randf() < vegetation_density * 2.0:
				map.entities.append({
					"entity": "arbre_%d_%d" % [x, y],
					"position": [x, 0, y],
					"rotation": rng.randi_range(0, 359),
					"state": "idle",
				})

	return map


static func _make_noise(seed_value: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	return noise


## Ordre important : eau/montagne d'abord (contraintes de relief), puis le
## climat (température/humidité) détermine le biome du terrain restant.
static func classify(elevation: float, humidity: float, temperature: float) -> String:
	if elevation > 0.55:
		return "Montagne"
	if elevation < -0.45:
		return "Eau"
	if elevation < -0.3:
		return "Marais"
	if temperature < -0.5:
		return "Neige"
	if humidity < -0.3 and temperature > 0.1:
		return "Désert"
	if humidity > 0.25:
		return "Forêt"
	if elevation < -0.1:
		return "Plage"
	return "Plaine"
