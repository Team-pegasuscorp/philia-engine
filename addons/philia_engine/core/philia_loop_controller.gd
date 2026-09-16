@tool
class_name PhiliaLoopController
extends Node

## Mécanique générique "avancer puis revenir" (concept Le Couloir, §4-5) :
## le joueur avance en accumulant une distance, puis doit revenir en
## parcourant EXACTEMENT cette même distance en sens inverse pour terminer
## la boucle. Ce contrôleur ne connaît rien du couloir, des portes ou de
## l'histoire — il ne fait que suivre une distance signée et exposer des
## signaux ; le jeu qui l'utilise décide ce que "avancer"/"reculer" veut
## dire concrètement (déplacement sur une grille, le long d'un couloir,
## autre chose). Réutilisable pour toute mécanique à base de boucle+retour,
## pas seulement Le Couloir.

signal phase_changed(phase: Phase)
## Émis quand le jeu déclenche la fin d'une traversée (mort, bout du
## couloir atteint, §12). `forward_distance` est la distance accumulée
## pendant CETTE traversée : c'est au jeu de la conserver (ex: dans un
## PhiliaJournal) s'il veut en faire quelque chose après reset().
signal loop_reset(forward_distance: float)
signal loop_completed()

enum Phase { FORWARD, RETURN, COMPLETE }

var phase: Phase = Phase.FORWARD
var forward_distance: float = 0.0
var _return_progress: float = 0.0


## À appeler quand le joueur avance de `amount` (positif). En phase
## FORWARD, cumule la distance parcourue (§5 : "le nombre de déplacements
## vers l'arrière peut être lié au nombre total de déplacements effectués
## auparavant"). Sans effet dans les autres phases.
func advance(amount: float) -> void:
	if phase != Phase.FORWARD or amount <= 0.0:
		return
	forward_distance += amount


## Fin de traversée (mort/fin du couloir atteinte, §12) : remet le
## contrôleur à l'état initial mais laisse le jeu récupérer
## `forward_distance` via le signal avant qu'elle ne soit remise à zéro.
func reset_loop() -> void:
	loop_reset.emit(forward_distance)
	phase = Phase.FORWARD
	forward_distance = 0.0
	_return_progress = 0.0
	phase_changed.emit(phase)


## Bascule explicitement en phase de retour (§4 Phase D : "le joueur
## comprend qu'il doit revenir en arrière") — décision narrative du jeu,
## ce contrôleur ne la déclenche jamais de lui-même.
func start_return() -> void:
	if phase != Phase.FORWARD:
		return
	_return_progress = 0.0
	phase = Phase.RETURN
	phase_changed.emit(phase)


## À appeler quand le joueur recule de `amount` en phase RETURN. Termine la
## boucle une fois `forward_distance` parcourue en sens inverse (§5).
func retreat(amount: float) -> void:
	if phase != Phase.RETURN or amount <= 0.0:
		return
	_return_progress += amount
	if _return_progress >= forward_distance:
		phase = Phase.COMPLETE
		phase_changed.emit(phase)
		loop_completed.emit()


## Distance qu'il reste à parcourir en arrière pour terminer la boucle. Le
## jeu décide s'il l'affiche : la règle doit rester mystérieuse au début
## (§5 : "Le joueur ne doit pas recevoir immédiatement un compteur").
func remaining_return_distance() -> float:
	return max(0.0, forward_distance - _return_progress)
