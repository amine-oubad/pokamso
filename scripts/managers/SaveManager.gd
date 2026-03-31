class_name SaveManager
## Sauvegarde/chargement — slot unique, format JSON.
## Étendre ici pour : multi-slot, quêtes, inventaire, etc.

const SAVE_PATH := "user://save.json"

# ─── Save ─────────────────────────────────────────────────────────────────────

static func save() -> void:
	var data := {
		"player_tile_pos": {
			"x": Global.player_tile_pos.x,
			"y": Global.player_tile_pos.y,
		},
		"player_team": _serialize_team(Global.player_team),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager : impossible d'écrire " + SAVE_PATH)
		return
	f.store_string(JSON.stringify(data, "\t"))

# ─── Load ─────────────────────────────────────────────────────────────────────

static func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if not data is Dictionary:
		push_error("SaveManager : fichier de sauvegarde corrompu.")
		return

	var pos: Dictionary = data.get("player_tile_pos", {"x": 10, "y": 7})
	Global.player_tile_pos = Vector2i(pos.get("x", 10), pos.get("y", 7))

	Global.player_team.clear()
	for entry in data.get("player_team", []):
		Global.player_team.append(_deserialize_monster(entry))

	# Évite les collisions d'uid après chargement
	for m in Global.player_team:
		if m.uid >= MonsterInstance._next_uid:
			MonsterInstance._next_uid = m.uid + 1

# ─── Sérialisation ────────────────────────────────────────────────────────────

static func _serialize_team(team: Array) -> Array:
	var result := []
	for m in team:
		result.append({
			"uid":        m.uid,
			"species_id": m.species_id,
			"name":       m.name,
			"level":      m.level,
			"max_hp":     m.max_hp,
			"current_hp": m.current_hp,
			"atk":        m.atk,
			"def":        m.def,
			"catch_rate": m.catch_rate,
			"moves":      m.moves,
		})
	return result

static func _deserialize_monster(data: Dictionary) -> MonsterInstance:
	var m := MonsterInstance.new()
	m.uid        = data.get("uid",        0)
	m.species_id = data.get("species_id", "")
	m.name       = data.get("name",       "???")
	m.level      = data.get("level",      1)
	m.max_hp     = data.get("max_hp",     1)
	m.current_hp = data.get("current_hp", 1)
	m.atk        = data.get("atk",        1)
	m.def        = data.get("def",        1)
	m.catch_rate = data.get("catch_rate", 45)
	m.moves      = data.get("moves",      [])
	return m
