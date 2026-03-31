extends Node2D
## Joueur overworld — déplacement grille 16x16.

const TILE: int = 16
const MOVE_DURATION: float = 0.12

enum Dir { DOWN, UP, LEFT, RIGHT }

const DIR_VEC: Dictionary = {
	Dir.DOWN:  Vector2i(0, 1),
	Dir.UP:    Vector2i(0, -1),
	Dir.LEFT:  Vector2i(-1, 0),
	Dir.RIGHT: Vector2i(1, 0),
}

## Rempli par la map : blocked[Vector2i(x,y)] = true
var blocked: Dictionary = {}
## Rempli par la map : grass_tiles[Vector2i(x,y)] = true
var grass_tiles: Dictionary = {}
## Rempli par la map : heal_tiles[Vector2i(x,y)] = true
var heal_tiles: Dictionary = {}

signal healed
## Table de rencontre du tile courant. Format : { encounter_rate, pool[] }
var encounter_table: Dictionary = {}
## Limites de la map (en tiles)
var map_rect: Rect2i = Rect2i(0, 0, 20, 15)
## Position tile courante
var tile_pos: Vector2i = Vector2i.ZERO
## Direction regardée
var facing: Dir = Dir.DOWN
## Verrou pendant le mouvement
var _moving: bool = false

func _ready() -> void:
	# Placeholder visuel — carré bleu 14x14 centré dans le tile
	var rect := ColorRect.new()
	rect.color = Color(0.2, 0.4, 0.9)
	rect.size = Vector2(14, 14)
	rect.position = Vector2(1, 1)
	add_child(rect)
	_snap()

func set_tile_pos(tp: Vector2i) -> void:
	tile_pos = tp
	_snap()

func _snap() -> void:
	position = Vector2(tile_pos.x * TILE, tile_pos.y * TILE)

func _process(_delta: float) -> void:
	if _moving:
		return
	var dir: Dir = Dir.DOWN
	var pressed: bool = false
	if Input.is_action_pressed("move_up"):
		dir = Dir.UP; pressed = true
	elif Input.is_action_pressed("move_down"):
		dir = Dir.DOWN; pressed = true
	elif Input.is_action_pressed("move_left"):
		dir = Dir.LEFT; pressed = true
	elif Input.is_action_pressed("move_right"):
		dir = Dir.RIGHT; pressed = true
	if not pressed:
		return
	facing = dir
	var target: Vector2i = tile_pos + DIR_VEC[dir]
	if not map_rect.has_point(target) or blocked.has(target):
		return
	_moving = true
	tile_pos = target
	var tw: Tween = create_tween()
	tw.tween_property(self, "position", Vector2(target.x * TILE, target.y * TILE), MOVE_DURATION)
	tw.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	_moving = false
	if heal_tiles.has(tile_pos):
		healed.emit()
		return
	_check_encounter()

func _check_encounter() -> void:
	if not grass_tiles.has(tile_pos):
		return
	if encounter_table.is_empty():
		return
	if randf() >= encounter_table.get("encounter_rate", 0.25):
		return
	var pool: Array = encounter_table.get("pool", [])
	if pool.is_empty():
		return
	Global.pending_encounter = pool[randi() % pool.size()]
	Global.player_tile_pos = tile_pos
	get_tree().change_scene_to_file("res://scenes/battle/Battle.tscn")
