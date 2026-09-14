@tool
class_name PhiliaPopulationSpawner
extends RefCounted

## Peuple une carte par zone/densité plutôt qu'individu par individu (§12) :
##
##   FOREST
##   ├── Deer    density = 0.7
##   ├── Wolf    density = 0.15
##   └── Rabbit  density = 0.8
##
## `rules` associe un type de tuile (biome ou autre) à une table
## {espèce: densité 0..1}. Pour chaque case dont le type a des règles, un jet
## par espèce décide si elle y apparaît. Déterministe : le seed de chaque jet
## est dérivé de (seed_value, espèce, x, y), donc indépendant de l'ordre
## d'itération des tuiles ou des clés du dictionnaire de règles.

static func spawn(map: PhiliaMap, rules: Dictionary, seed_value: int, layer: String = "Terrain") -> void:
	for tile in map.tiles:
		if tile.get("layer", PhiliaMap.DEFAULT_LAYER) != layer:
			continue
		var zone_rules: Dictionary = rules.get(tile.get("type", ""), {})
		if zone_rules.is_empty():
			continue

		var x: int = tile.get("x", 0)
		var y: int = tile.get("y", 0)
		for species in zone_rules:
			var density: float = zone_rules[species]
			var roll_seed := hash("%d_%s_%d_%d" % [seed_value, species, x, y])
			var rng := RandomNumberGenerator.new()
			rng.seed = roll_seed
			if rng.randf() < density:
				map.entities.append({
					"entity": "%s_%d_%d" % [species, x, y],
					"position": [x, 0, y],
					"rotation": rng.randi_range(0, 359),
					"state": "idle",
				})
