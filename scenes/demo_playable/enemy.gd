extends Node3D

## Ennemi statique pour la scène jouable de démo (pas un composant
## réutilisable de l'addon) : porte un PhiliaStats et expose son
## PhiliaCharacterAnimator, ne connaît ni le joueur ni la quête —
## scenes/demo_playable/controller.gd relie stats.died à la progression
## de la quête (§20).

@onready var animator: PhiliaCharacterAnimator = $CharacterInstance/Animator

var stats: PhiliaStats


func setup(new_stats: PhiliaStats) -> void:
	stats = new_stats
