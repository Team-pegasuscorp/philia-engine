@tool
class_name PhiliaMaterial
extends Resource

## Matériau générique, séparé de la géométrie (doc §6) : chaque canal est
## optionnel et indépendant du renderer final. La carte ne référence que le
## chemin vers ce .tres (champ optionnel "material" d'une tuile, voir
## PhiliaMap.material_for) — le .philiamap lui-même reste du JSON pur
## (§21.2), ce Resource est un asset séparé comme le TileSet de terrains.
##
## Aujourd'hui seul PhiliaImporter (2D) lit albedo_color pour l'aperçu ;
## roughness/metallic/normal_texture/height_texture sont prêts pour un
## import 3D futur (ex: construire un StandardMaterial3D à partir des
## mêmes champs) sans changer le format de la carte.

@export var albedo_color: Color = Color.WHITE
@export var albedo_texture: Texture2D
@export var normal_texture: Texture2D
@export_range(0.0, 1.0) var roughness: float = 1.0
@export_range(0.0, 1.0) var metallic: float = 0.0
@export var height_texture: Texture2D
