@tool
class_name PhiliaMaterial
extends Resource

## Matériau générique, séparé de la géométrie (doc §6) : chaque canal est
## optionnel et indépendant du renderer final. La carte ne référence que le
## chemin vers ce .tres (champ optionnel "material" d'une tuile, voir
## PhiliaMap.material_for) — le .philiamap lui-même reste du JSON pur
## (§21.2), ce Resource est un asset séparé comme le TileSet de terrains.
##
## PhiliaImporter (2D) lit albedo_color pour l'aperçu ; PhiliaImporter3D
## (build_standard_material) construit un vrai StandardMaterial3D à partir
## de tous les champs pour le rendu 3D.
##
## orm_texture suit la convention "packée" de tools/tile-gen (générateur de
## tuiles procédurales seamless, Blender headless, hors de ce dépôt) :
## R = roughness, G = metallic, B = ambient occlusion, un seul fichier
## plutôt que trois textures séparées. roughness/metallic (scalaires)
## restent les valeurs utilisées si orm_texture est absent.

@export var albedo_color: Color = Color.WHITE
@export var albedo_texture: Texture2D
@export var normal_texture: Texture2D
@export_range(0.0, 1.0) var roughness: float = 1.0
@export_range(0.0, 1.0) var metallic: float = 0.0
@export var orm_texture: Texture2D  ## R=roughness, G=metallic, B=AO (convention tile-gen)
@export var height_texture: Texture2D
