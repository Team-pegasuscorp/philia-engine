@tool
class_name PhiliaUndoStack
extends RefCounted

## Pile d'annulation générique à base d'instantanés (snapshots) de
## dictionnaires JSON-compatibles — pas d'intégration avec
## EditorUndoRedoManager (celui-ci suit l'arbre de scène de l'éditeur, pas
## le contenu d'un PhiliaMap/PhiliaGameplayData ; un instantané complet
## avant chaque mutation est plus simple et robuste à maintenir qu'un
## suivi champ par champ). Utilisée par les docks éditeur
## (editor/philia_dock.gd via PhiliaGridCanvas, editor/philia_gameplay_dock.gd).

signal changed  ## émis après push/undo/redo/clear — pour réactiver/désactiver les boutons Annuler/Rétablir

const MAX_HISTORY := 100

var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []


## À appeler AVANT une mutation, avec l'état courant (ex: map.to_dict()).
## Vide la pile de rétablissement : une nouvelle action rend l'ancien futur
## caduc, comme n'importe quel undo/redo classique.
func push(snapshot: Dictionary) -> void:
	_undo_stack.append(snapshot.duplicate(true))
	if _undo_stack.size() > MAX_HISTORY:
		_undo_stack.pop_front()
	_redo_stack.clear()
	changed.emit()


func can_undo() -> bool:
	return not _undo_stack.is_empty()


func can_redo() -> bool:
	return not _redo_stack.is_empty()


## Retire et renvoie le dernier instantané annulable. `current_snapshot`
## (l'état actuel, avant restauration) est conservé pour permettre le redo.
## Sans effet (renvoie current_snapshot) si la pile est vide.
func undo(current_snapshot: Dictionary) -> Dictionary:
	if _undo_stack.is_empty():
		return current_snapshot
	_redo_stack.append(current_snapshot.duplicate(true))
	var snapshot: Dictionary = _undo_stack.pop_back()
	changed.emit()
	return snapshot


func redo(current_snapshot: Dictionary) -> Dictionary:
	if _redo_stack.is_empty():
		return current_snapshot
	_undo_stack.append(current_snapshot.duplicate(true))
	var snapshot: Dictionary = _redo_stack.pop_back()
	changed.emit()
	return snapshot


## À appeler sur "Nouveau"/"Charger" : un nouveau document n'a pas
## d'historique à annuler vers l'ancien.
func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	changed.emit()
