# Arknoid Engine — Concept & Architecture

## Vision

Créer un **éditeur de niveaux / de mondes spécialisé au-dessus de Godot**, permettant de construire des environnements avec des tuiles, des modules 3D, des matériaux PBR, des objets, des êtres vivants et de la génération procédurale.

L'objectif n'est pas de remplacer Godot, mais de construire une couche spécialisée qui impose une manière simple et réutilisable de fabriquer des jeux.

---

# 1. Architecture générale

```text
                 ARKNOID ENGINE
        ┌─────────────────────────┐
        │ Éditeur de niveaux      │
        │ Génération procédurale  │
        │ Terrain / biomes        │
        │ Assets / matériaux      │
        │ Entités                 │
        │ Animations / IA         │
        │ Export / import         │
        └────────────┬────────────┘
                     ↓
                   GODOT
        ┌─────────────────────────┐
        │ Rendering               │
        │ Physique                │
        │ Audio                   │
        │ Animation               │
        │ GPU / shaders           │
        │ Scenes                  │
        └─────────────────────────┘
```

Godot reste le moteur technique. Arknoid Engine constitue la couche de création et d'abstraction.

---

# 2. Éditeur de niveau

L'éditeur permet de construire une carte en plaçant des éléments sur une grille ou dans un espace 3D.

## Types d'éléments

- Tuiles
- Murs
- Sols
- Portes
- Piliers
- Escaliers
- Rochers
- Caisses
- Machines
- Décors
- Personnages
- Créatures
- Points de spawn
- Triggers

Une carte peut être sauvegardée dans un format propriétaire, par exemple :

```text
MyWorld.arkmap
```

L'idée importante est que `.arkmap` ne soit pas une scène Godot. Le format décrit le monde de manière générique afin qu'il puisse être importé dans plusieurs jeux.

---

# 3. Séparation Forme / Matériau

Le système sépare la géométrie de son apparence.

## Formes

```text
Flat
Panel
Brick
Ribbed
Corrugated
Rock
Pillar
Pipe
Custom
```

## Matériaux

```text
Stone
Brick
Wood
Concrete
Rusty Metal
Clean Metal
Alien
Ice
etc.
```

Exemples :

```text
Ribbed + Rusty Metal
→ mur métallique nervuré

Pillar + Brick
→ colonne en brique

Rock + Stone
→ rocher

Wall + Stone + Relief
→ mur rocheux
```

Cette séparation permet de réutiliser une même géométrie avec de nombreux matériaux.

---

# 4. Géométrie procédurale

Les objets peuvent être générés à partir de paramètres.

Exemple : générateur de rocher.

```text
ROCK GENERATOR

Shape
[ Natural ]

Faces
[ 6 ]

Size
X [ 1.2 ]
Y [ 0.8 ]
Z [ 1.0 ]

Randomness
[ 60% ]

Material
[ Stone ]

Seed
[ 48192 ]
```

Le générateur produit une géométrie différente selon le seed et les paramètres.

## Niveaux de détail

- Rocher simple : ~6 faces
- Rocher moyen : 20–50 faces
- Rocher détaillé : 100–500 faces

Le même principe peut servir pour :

- Rochers
- Piliers
- Murs
- Tuyaux
- Falaises
- Colonnes
- Poutres
- Structures diverses

---

# 5. Relief personnalisé

Une interface de profil permet de définir une forme ou un relief.

```text
Hauteur
  ↑
  │          █
  │        ████
  │    █████████
  │  ████████████
  └────────────────→ largeur
```

Le profil est transformé en géométrie.

Paramètres possibles :

- largeur
- hauteur
- profondeur
- amplitude
- fréquence
- nombre de répétitions
- symétrie
- irrégularité
- lissage

La géométrie générée reçoit ensuite un matériau PBR.

---

# 6. Matériaux PBR

Un matériau peut contenir :

```text
Material
├── Albedo
├── Normal
├── Roughness
├── Metallic
└── éventuellement Height
```

Les packs d'assets peuvent donc être séparés des générateurs de géométrie.

Exemple :

```text
Capital Pirate
→ matériaux sci-fi métalliques

Fantasy Dungeon
→ pierre, brique, bois
```

Les matériaux peuvent être appliqués à plusieurs types de formes.

---

# 7. Tuiles et modules

Le système peut distinguer deux catégories.

## Tiles

```text
Sol
Mur
Coin
Bord
Terrain
```

## Modules

```text
Porte
Fenêtre
Escalier
Pilier
Caisse
Machine
```

Un module peut occuper plusieurs cases.

Exemple :

```text
┌───────────┐
│           │
│   PORTE   │
│           │
└───────────┘
```

Cela permet de construire rapidement des environnements cohérents.

---

# 8. Autotiling / terrains

Le système peut utiliser les terrains de Godot ou un système équivalent pour choisir automatiquement les variantes.

Exemple :

```text
████████
████████
████████
```

devient automatiquement :

```text
╔══════╗
║      ║
║      ║
╚══════╝
```

Le moteur choisit les coins, bords et raccords appropriés.

---

# 9. Génération procédurale du monde

Le système peut utiliser du bruit de Perlin/Simplex ou d'autres fonctions de bruit.

## Chaîne de génération

```text
SEED
 ↓
Noise hauteur
 ↓
Heightmap
 ↓
Terrain / Mesh
 ↓
Biomes
 ↓
Matériaux
 ↓
Objets / végétation
 ↓
Entités
```

Plusieurs couches de bruit peuvent être combinées.

### Exemple

```text
Noise 1 → altitude
Noise 2 → humidité
Noise 3 → température
Noise 4 → détail
```

Ces valeurs servent à déterminer les biomes :

- Plage
- Plaine
- Forêt
- Désert
- Marais
- Montagne
- Neige

---

# 10. Génération + édition manuelle

Le monde doit pouvoir être généré puis modifié manuellement.

```text
Seed
 ↓
Génération
 ↓
Carte
 ↓
Modification manuelle
 ↓
Carte finale
```

Exemples :

- Ajouter une montagne
- Supprimer des arbres
- Creuser une rivière
- Ajouter une ville
- Poser un donjon
- Modifier un biome
- Ajouter des structures

Cela combine les avantages du procédural et de l'édition classique.

---

# 11. Êtres vivants / entités

L'éditeur ne doit pas forcément stocker directement le comportement spécifique au jeu.

Il décrit une entité générique.

```text
CREATURE
├── Apparence
│   ├── modèle
│   ├── texture
│   ├── animations
│   └── variantes
│
├── Physique
│   ├── taille
│   ├── poids
│   └── collision
│
├── Caractéristiques
│   ├── vie
│   ├── vitesse
│   ├── force
│   └── perception
│
├── Comportement
│   ├── passif
│   ├── neutre
│   ├── agressif
│   └── fuite
│
└── Écologie
    ├── habitat
    ├── nourriture
    ├── prédateurs
    └── reproduction
```

Le niveau peut contenir :

```json
{
  "entity": "wolf_01",
  "position": [12, 0, 8],
  "rotation": 90,
  "state": "idle"
}
```

Le jeu qui importe la carte décide ensuite du comportement réel.

---

# 12. Population et écosystème

Au lieu de placer chaque animal individuellement, une zone peut définir une densité.

Exemple :

```text
FOREST
├── Deer
│   └── density = 0.7
├── Wolf
│   └── density = 0.15
├── Rabbit
│   └── density = 0.8
└── Bear
    └── density = 0.03
```

Le générateur place automatiquement les individus dans les zones compatibles.

À terme, une simulation écologique peut être ajoutée :

```text
🐇 mange de l'herbe
 ↓
🐺 chasse 🐇
 ↓
population
 ↓
végétation
 ↓
équilibre de l'écosystème
```

Cette partie est optionnelle et peut venir beaucoup plus tard.

---

# 13. Animations

Il ne serait pas nécessaire de créer un système d'animation entièrement nouveau.

Godot peut gérer :

- squelettes
- AnimationPlayer
- AnimationTree
- blend
- retargeting
- bibliothèques d'animations

Arknoid Engine peut gérer la logique et les standards.

Exemple :

```text
PERSONNAGE
├── Modèle
├── Squelette
└── Animations
    ├── Idle
    ├── Walk
    ├── Run
    ├── Attack
    ├── Hit
    └── Death
```

---

# 14. Bibliothèques d'animations existantes

Des solutions existantes permettent d'éviter de produire toutes les animations à la main.

## Mixamo

Bibliothèque d'animations humanoïdes prêtes à l'emploi :

- Idle
- Walk
- Run
- Jump
- Attack
- Dodge
- Hit
- Death
- etc.

Les animations peuvent être retargetées vers différents personnages compatibles.

## Quaternius

La Universal Animation Library propose une grande bibliothèque d'animations humanoïdes et un rig universel, avec une licence CC0 annoncée pour cet asset.

## Principe

```text
Personnage
 ↓
Squelette compatible
 ↓
Animation library
 ↓
Retargeting
 ↓
Personnage animé
```

Arknoid Engine pourrait définir des standards :

```text
Humanoid
Quadruped
Bird
Creature
```

---

# 15. Animation State Machine

Le moteur peut gérer les états :

```text
IDLE
 ↓ déplacement
WALK
 ↓ vitesse élevée
RUN
 ↓ attaque
ATTACK
 ↓ fin
IDLE
```

Et :

```text
HP = 0
 ↓
DEATH
```

Les animations sont choisies automatiquement selon l'état de l'entité.

Exemple :

```text
velocity = 0
→ Idle

velocity = 2
→ Walk

velocity = 6
→ Run
```

Le moteur orchestre le comportement, tandis que Godot réalise l'animation.

---

# 16. Réutilisation entre plusieurs jeux

Le but principal du format `.arkmap` est de permettre de réutiliser une même carte dans différents projets.

```text
             .ARKMAP
                 │
        ┌────────┼────────┐
        ↓        ↓        ↓
       RPG    Survival    RTS
        │        │        │
       IA       IA        IA
```

La carte décrit le monde.

Le jeu fournit les règles.

Ainsi :

> **L'éditeur construit le monde. Le jeu donne vie au monde.**

---

# 17. Exemple de structure d'asset

Un asset pourrait être organisé ainsi :

```text
capital_pirate/
│
├── textures/
│   ├── metal_01_albedo.png
│   ├── metal_01_normal.png
│   └── metal_01_orm.png
│
├── shapes/
│   └── wall_ribbed.arkshape
│
├── materials/
│   └── rusty_metal.arkmaterial
│
├── tiles/
│   └── tileset.json
│
└── preview.png
```

Un générateur de forme peut être décrit par des paramètres :

```json
{
  "type": "procedural_mesh",
  "width": 2,
  "height": 3,
  "depth": 0.25,
  "amplitude": 0.18,
  "frequency": 6,
  "smoothness": 0.7
}
```

---

# 18. Écosystème commercial potentiel

Les assets produits pour itch.io peuvent également servir de contenu natif pour l'éditeur.

Exemples :

```text
Capital Pirate
→ Sci-Fi / métal / rouille

Fantasy Dungeon
→ pierre / brique / bois
```

Puis :

```text
Capital Pirate Environment Kit
→ matériaux
→ formes
→ portes
→ panneaux
→ objets
→ exemples de scènes
```

Le catalogue d'assets peut donc alimenter directement le logiciel.

---

# 19. Roadmap proposée

## V1 — World Editor minimal

- Grille
- Palette d'assets
- Placement
- Suppression
- Rotation
- Sauvegarde `.arkmap`
- Export JSON
- Import dans Godot

## V2 — Construction

- Calques
- Autotiling
- Terrains
- Modules
- Objets
- Collisions
- Matériaux PBR

## V3 — 3D procédural

- Générateur de rochers
- Générateur de murs
- Générateur de piliers
- Relief personnalisé
- Mesh procédural
- Paramètres de génération
- Seeds

## V4 — World Generator

- Perlin/Simplex noise
- Heightmap
- Biomes
- Végétation
- Rochers
- Structures
- Génération par seed

## V5 — Vie

- Entités
- Spawn points
- Population
- Animations
- Animation State Machine
- IA de base

## V6 — Gameplay

- Quêtes
- Inventaire
- Statistiques
- Combat
- Dialogues
- Triggers
- Sauvegarde

---

# 20. Principe directeur

Ne pas recréer ce que Godot fait déjà très bien.

Godot fournit :

- rendu
- physique
- audio
- animation
- shaders
- scènes
- GPU
- navigation
- ressources

Arknoid Engine fournit :

- workflow
- format de monde
- éditeur
- génération procédurale
- bibliothèque d'assets
- générateurs de formes
- standards d'entités
- orchestration des systèmes
- export/import

**Conclusion :**

Le projet peut commencer comme un simple **éditeur de niveaux Godot**, puis évoluer progressivement vers un véritable **framework/moteur spécialisé de création de mondes et de jeux**.

Le premier objectif raisonnable reste :

> **Créer une carte → sauvegarder `.arkmap` → l'importer dans un jeu Godot.**

Tout le reste peut être ajouté progressivement autour de cette base.

---

# 21. Contraintes transversales (multiplateforme, base partagée, pilotage IA)

Trois exigences structurantes à intégrer dès la V1, car elles influencent le format de données et l'architecture, pas seulement l'UI.

## 21.1 Linux + Windows

Godot 4 est déjà nativement cross-platform, donc le choix le plus sûr est de développer l'éditeur **comme un plugin/module Godot** (GDScript ou C#/GDExtension) plutôt que comme une appli externe séparée :

```text
Éditeur = addon Godot
 → même binaire Godot sur Linux et Windows
 → pas de dépendance shell spécifique à un OS
 → pas de chemin en dur, pas d'appel système propre à une plateforme
```

Points de vigilance :

- Aucune dépendance à des outils uniquement disponibles sur un OS (pas de script `.bat`/`.sh` non miroité).
- Chemins de fichiers toujours via `OS`/`ProjectSettings` de Godot (`user://`, `res://`), jamais de chemin absolu codé en dur.
- Tester l'export du plugin sur les deux OS avant chaque release, pas seulement le runtime du jeu final.

## 21.2 Base de données facilement partageable

Le format `.arkmap` (et les assets `.arkshape` / `.arkmaterial`) doivent rester des **fichiers texte structurés (JSON ou équivalent lisible)**, pas des blobs binaires :

```text
.arkmap, .arkshape, .arkmaterial
 → JSON / texte
 → diffable et mergeable dans un système de version
 → pas de format propriétaire opaque
```

Ça permet deux modes de partage complémentaires, sans lock-in :

- **Partage via dépôt Git** (comme CollabMD ou les autres projets) : chaque carte/asset versionné, historique lisible, merge possible entre contributeurs.
- **Partage via un dossier synchronisé** (Drive, Syncthing…) pour un usage plus léger, en solo ou petite équipe, sans notion de conflit à gérer.

Une base binaire type SQLite peut venir plus tard en couche d'indexation/cache local (recherche rapide dans une grosse bibliothèque d'assets), mais ne doit jamais être la source de vérité — les fichiers texte le restent.

## 21.3 Pilotable facilement par un agent IA

C'est l'exigence qui doit le plus influencer l'architecture : **toute action possible dans l'éditeur doit exister sous forme de commande, pas seulement de clic GUI.**

```text
GUI (humain)  ─┐
                ├─→  API / CLI interne  →  moteur Arknoid
Agent IA      ─┘
```

Concrètement :

- Un mode `--headless` (comme dans SpaceRPG) qui expose les mêmes opérations que l'UI : créer une tuile, placer une entité, générer un rocher, exporter une carte — en ligne de commande ou via un petit serveur local (JSON-RPC/HTTP).
- Chaque commande a une sortie structurée (JSON) et un code de retour exploitable par un script, pas seulement du texte pour humain.
- Le format `.arkmap` étant déjà du JSON lisible (§21.2), un agent peut le lire/modifier directement sans passer par l'éditeur — mais l'API reste préférable dès qu'il y a de la génération procédurale (seeds, validation) à respecter.
- Éviter toute fonctionnalité qui n'existerait *que* dans un menu GUI : chaque nouvelle feature de l'éditeur doit être pensée "commande d'abord, bouton ensuite".

Cette approche évite l'écueil déjà rencontré ailleurs (SpaceRPG) où un contrôle headless ne peut pas cliquer sur des boutons d'UI — ici l'agent n'a jamais besoin de cliquer, il appelle directement la commande.
