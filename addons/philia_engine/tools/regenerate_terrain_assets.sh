#!/usr/bin/env bash
# Régénère l'atlas placeholder + le TileSet de terrains Godot.
# À lancer depuis la racine du projet (ou en passant son chemin en $1).
set -euo pipefail

PROJECT_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
cd "$PROJECT_DIR"

godot --headless --script res://addons/philia_engine/tools/generate_terrain_atlas.gd
godot --headless --import
godot --headless --script res://addons/philia_engine/tools/generate_terrain_tileset.gd
