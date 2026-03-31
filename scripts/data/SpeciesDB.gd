class_name SpeciesDB
## Registre d'espèces — lookup par species_id, scan auto, cache.
## Point unique pour récupérer les données d'une espèce.

const SPECIES_DIR := "res://data/species/"

static var _id_to_file: Dictionary = {}
static var _cache: Dictionary = {}
static var _indexed: bool = false

## Retourne le dict d'espèce pour un species_id donné. {} si introuvable.
static func get_species(species_id: String) -> Dictionary:
	if not _indexed:
		_build_index()
	if _cache.has(species_id):
		return _cache[species_id]
	if not _id_to_file.has(species_id):
		push_error("SpeciesDB : espèce inconnue " + species_id)
		return {}
	var f := FileAccess.open(_id_to_file[species_id], FileAccess.READ)
	if f == null:
		push_error("SpeciesDB : impossible de lire " + _id_to_file[species_id])
		return {}
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	_cache[species_id] = data
	return data

## Scanne data/species/ et construit l'index id → fichier.
static func _build_index() -> void:
	_indexed = true
	var dir := DirAccess.open(SPECIES_DIR)
	if dir == null:
		push_error("SpeciesDB : répertoire introuvable " + SPECIES_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var path := SPECIES_DIR + file_name
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				var data = JSON.parse_string(f.get_as_text())
				if data is Dictionary and data.has("id"):
					_id_to_file[data["id"]] = path
		file_name = dir.get_next()
