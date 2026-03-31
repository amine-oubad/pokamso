extends Node2D
## Map de test 20x15 — TileMapLayer procédurale + Player.

const TILE: int = 16
const W: int = 20
const H: int = 15

var _blocked: Dictionary = {}
var _grass: Dictionary = {}
var _heal: Dictionary = {}
var _player: Node2D
var _team_overlay: CanvasLayer
var _team_label: Label
var _team_open: bool = false
var _heal_label: Label

func _ready() -> void:
	SaveManager.load()
	var tilemap := _create_tilemap()
	add_child(tilemap)
	_fill_map(tilemap)
	_spawn_player()
	_build_team_overlay()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_team_open = not _team_open
		_team_overlay.visible = _team_open
		_player.set_process(not _team_open)
		if _team_open:
			_refresh_team_overlay()

func _create_tilemap() -> TileMapLayer:
	# Texture placeholder 3 tiles : sol | mur | herbes hautes
	var img := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(0,  0, 16, 16), Color(0.18, 0.54, 0.18))  # sol
	img.fill_rect(Rect2i(16, 0, 16, 16), Color(0.10, 0.30, 0.10))  # mur
	img.fill_rect(Rect2i(32, 0, 16, 16), Color(0.55, 0.80, 0.15))  # herbes hautes
	img.fill_rect(Rect2i(48, 0, 16, 16), Color(0.40, 0.70, 1.00))  # soin
	var tex := ImageTexture.create_from_image(img)

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(TILE, TILE)
	atlas.create_tile(Vector2i(0, 0))  # sol
	atlas.create_tile(Vector2i(1, 0))  # mur
	atlas.create_tile(Vector2i(2, 0))  # herbes hautes
	atlas.create_tile(Vector2i(3, 0))  # soin
	ts.add_source(atlas, 0)

	var tm := TileMapLayer.new()
	tm.tile_set = ts
	tm.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return tm

func _fill_map(tm: TileMapLayer) -> void:
	var grass      := Vector2i(0, 0)
	var wall       := Vector2i(1, 0)
	var tall_grass := Vector2i(2, 0)

	# Sol herbe partout
	for y in H:
		for x in W:
			tm.set_cell(Vector2i(x, y), 0, grass)

	# Bordure arbres — passage nord colonnes 9-10
	for x in W:
		if x < 9 or x > 10:
			_wall(tm, x, 0, wall)
		_wall(tm, x, H - 1, wall)
	for y in range(1, H - 1):
		_wall(tm, 0, y, wall)
		_wall(tm, W - 1, y, wall)

	# Zone d'herbes hautes — cols 11-14, rows 2-5
	for y in range(2, 6):
		for x in range(11, 15):
			tm.set_cell(Vector2i(x, y), 0, tall_grass)
			_grass[Vector2i(x, y)] = true

	# Tuile de soin — col 10, row 12
	var heal := Vector2i(3, 0)
	tm.set_cell(Vector2i(10, 12), 0, heal)
	_heal[Vector2i(10, 12)] = true

	# Obstacles au milieu
	_wall(tm, 5, 5, wall); _wall(tm, 6, 5, wall)
	_wall(tm, 5, 6, wall); _wall(tm, 6, 6, wall)
	_wall(tm, 13, 5, wall); _wall(tm, 14, 5, wall)
	_wall(tm, 13, 6, wall); _wall(tm, 14, 6, wall)
	for x in range(7, 13):
		_wall(tm, x, 10, wall)

func _wall(tm: TileMapLayer, x: int, y: int, coord: Vector2i) -> void:
	tm.set_cell(Vector2i(x, y), 0, coord)
	_blocked[Vector2i(x, y)] = true

func _spawn_player() -> void:
	_player = load("res://scenes/player/Player.tscn").instantiate()
	add_child(_player)
	_player.blocked = _blocked
	_player.grass_tiles = _grass
	_player.heal_tiles = _heal
	_player.healed.connect(_heal_team)
	_player.encounter_table = _load_encounter_table()
	_player.map_rect = Rect2i(0, 0, W, H)
	_player.set_tile_pos(Global.player_tile_pos)

func _build_team_overlay() -> void:
	_team_overlay = CanvasLayer.new()
	_team_overlay.visible = false
	add_child(_team_overlay)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.88)
	bg.size = Vector2(320, 240)
	_team_overlay.add_child(bg)
	_team_label = Label.new()
	_team_label.position = Vector2(20, 16)
	_team_label.size = Vector2(280, 200)
	_team_label.add_theme_color_override("font_color", Color.WHITE)
	_team_overlay.add_child(_team_label)
	var hint := Label.new()
	hint.text = "[A] Fermer"
	hint.position = Vector2(20, 220)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_team_overlay.add_child(hint)

func _refresh_team_overlay() -> void:
	var lines: Array = ["── ÉQUIPE ──────────────────────"]
	for i in Global.TEAM_MAX:
		if i < Global.player_team.size():
			var m: MonsterInstance = Global.player_team[i]
			var marker := " >" if i == 0 else "  "
			lines.append("%s%d. %-12s Niv.%d  PV:%d/%d" % [
				marker, i + 1, m.name, m.level, m.current_hp, m.max_hp
			])
		else:
			lines.append("   %d. (vide)" % (i + 1))
	_team_label.text = "\n".join(lines)

func _heal_team() -> void:
	for m in Global.player_team:
		m.current_hp = m.max_hp
	Global.player_tile_pos = _player.tile_pos
	SaveManager.save()
	_show_heal_message()

func _show_heal_message() -> void:
	if _heal_label == null:
		_heal_label = Label.new()
		_heal_label.position = Vector2(60, 110)
		_heal_label.size = Vector2(200, 20)
		_heal_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
		add_child(_heal_label)
	_heal_label.text = "Équipe soignée !"
	_heal_label.visible = true
	await get_tree().create_timer(2.0).timeout
	_heal_label.visible = false

func _load_encounter_table() -> Dictionary:
	var f := FileAccess.open("res://data/encounters/test_map.json", FileAccess.READ)
	if f == null:
		return {}
	return JSON.parse_string(f.get_as_text())
