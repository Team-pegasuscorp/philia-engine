extends Node3D

## Ennemi de la scène jouable de démo (pas un composant réutilisable de
## l'addon) : porte un PhiliaStats, un PhiliaCharacterAnimator et un
## PhiliaBehavior (préréglé AGGRESSIVE dans le générateur de scène), ne
## connaît ni le joueur ni la quête — scenes/demo_playable/controller.gd
## relie stats.died à la progression de la quête et behavior.target /
## action_triggered au joueur (§20).

@onready var animator: PhiliaCharacterAnimator = $CharacterInstance/Animator
@onready var behavior: PhiliaBehavior = $Behavior

var stats: PhiliaStats


func setup(new_stats: PhiliaStats) -> void:
	stats = new_stats
	behavior.stats = new_stats  ## bascule en fuite automatique sous flee_hp_ratio
