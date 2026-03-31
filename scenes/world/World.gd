extends Node2D
## Map de test 20x15 — TileMapLayer procédurale + Player.

const TILE: int = 16
const W: int = 20
const H: int = 15

var _blocked: Dictionary = {}
var _grass: Dictionary = {}

func _ready() -> void:
	SaveManager.load()
	var tilemap := _create_tilemap()
	add_child(tilemap)
	_fill_map(tilemap)
	_spawn_player()

func _create_tilemap() -> TileMapLayer:
	# Texture placeholder 3 tiles : sol | mur | herbes hautes
	var img := Image.create(48, 16, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(0,  0, 16, 16), Color(0.18, 0.54, 0.18))  # sol
	img.fill_rect(Rect2i(16, 0, 16, 16), Color(0.10, 0.30, 0.10))  # mur
	img.fill_rect(Rect2i(32, 0, 16, 16), Color(0.55, 0.80, 0.15))  # herbes hautes
	var tex := ImageTexture.create_from_image(img)

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(TILE, TILE)
	atlas.create_tile(Vector2i(0, 0))  # sol
	atlas.create_tile(Vector2i(1, 0))  # mur
	atlas.create_tile(Vector2i(2, 0))  # herbes hautes
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
	var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
	add_child(player)
	player.blocked = _blocked
	player.grass_tiles = _grass
	player.encounter_table = _load_encounter_table()
	player.map_rect = Rect2i(0, 0, W, H)
	player.set_tile_pos(Global.player_tile_pos)

func _load_encounter_table() -> Dictionary:
	var f := FileAccess.open("res://data/encounters/test_map.json", FileAccess.READ)
	if f == null:
		return {}
	return JSON.parse_string(f.get_as_text())
