@tool
class_name PhiliaCombat
extends RefCounted

## Combat minimal (V6, §19) : calcule les dégâts entre deux PhiliaStats et
## orchestre les animations d'attaque/mort déjà définies par
## PhiliaCharacterAnimator (§15) — ne duplique aucune logique d'animation,
## décide seulement quand appeler trigger_attack()/die().

## Inflige des dégâts de attacker vers defender. base_damage < 0 (défaut)
## -> utilise la stat "force" de l'attaquant. Déclenche trigger_attack()
## sur attacker_animator si fourni, et die() sur defender_animator si la
## cible meurt de ce coup. Retourne les dégâts réellement appliqués (0 si
## l'un des deux est déjà mort ou amount <= 0).
static func attack(
	attacker_stats: PhiliaStats,
	defender_stats: PhiliaStats,
	base_damage: float = -1.0,
	attacker_animator: PhiliaCharacterAnimator = null,
	defender_animator: PhiliaCharacterAnimator = null,
) -> float:
	if attacker_stats.is_dead() or defender_stats.is_dead():
		return 0.0
	if attacker_animator:
		attacker_animator.trigger_attack()

	var amount := base_damage if base_damage >= 0.0 else attacker_stats.get_stat("force")
	var dealt := defender_stats.take_damage(amount)
	if defender_stats.is_dead() and defender_animator:
		defender_animator.die()
	return dealt
