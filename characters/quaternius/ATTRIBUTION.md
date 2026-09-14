# Quaternius — Universal Base Characters / Universal Animation Library

Assets tiers utilisés pour démontrer l'Animation State Machine (§13-15 du
concept), non créés par ce projet.

- **Base Characters** : `base_characters/Superhero_Male_FullBody.gltf` (+ textures)
  https://quaternius.com/packs/universalbasecharacters.html
- **Animation Library** : `animations/UAL1_Standard.glb` (variante sans root motion, 43 animations)
  https://quaternius.com/packs/universalanimationlibrary.html

**Licence : CC0 1.0 Universal** (domaine public, aucune attribution requise)
https://creativecommons.org/publicdomain/zero/1.0/

Les deux packs partagent le même squelette "Universal" (mêmes noms d'os) :
la bibliothèque d'animations s'attache directement sur le personnage sans
retargeting Godot.

`demo_character.tscn` (généré par
`addons/philia_engine/tools/generate_demo_character.gd`) assemble les deux
avec un `AnimationTree`/state machine piloté par `PhiliaCharacterAnimator`
(addon, réutilisable avec n'importe quel autre personnage/rig).
