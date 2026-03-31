class_name MoveDB
## Registre d'attaques — lookup par move_id, scan auto, cache.
## Même pattern que SpeciesDB.

const MOVES_DIR := "res://data/moves/"

static var _cache: Dictionary = {}
static var _indexed: bool = false

## Retourne le dict d'attaque pour un move_id donné. {} si introuvable.
static func get_move(move_id: String) -> Dictionary:
	if not _indexed:
		_build_index()
	if _cache.has(move_id):
		return _cache[move_id]
	push_error("MoveDB : move inconnu " + move_id)
	return {}

## Scanne data/moves/ et charge tous les fichiers JSON en cache.
static func _build_index() -> void:
	_indexed = true
	var dir := DirAccess.open(MOVES_DIR)
	if dir == null:
		push_error("MoveDB : répertoire introuvable " + MOVES_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var f := FileAccess.open(MOVES_DIR + file_name, FileAccess.READ)
			if f:
				var data = JSON.parse_string(f.get_as_text())
				if data is Dictionary and data.has("id"):
					_cache[data["id"]] = data
		file_name = dir.get_next()
