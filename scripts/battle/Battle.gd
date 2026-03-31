extends Node2D
## Combat 1v1 minimal — machine à états simple.

enum State { PLAYER_TURN, WAITING, VICTORY, DEFEAT }

var state: State = State.PLAYER_TURN
var player_monster: MonsterInstance
var enemy_monster: MonsterInstance

var _lbl_enemy: Label
var _lbl_player: Label
var _lbl_message: Label
var _lbl_menu: Label

# ─── Initialisation ───────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ui()
	player_monster = _load_monster(Global.player_monster_data)
	enemy_monster  = _load_monster(Global.pending_encounter)
	_refresh_ui()
	_set_message("%s sauvage apparaît !" % enemy_monster.name)
	_set_state(State.PLAYER_TURN)

func _load_monster(data: Dictionary) -> MonsterInstance:
	var species_name: String = data.get("name", "Bulbasaur").to_lower()
	var lvl: int = data.get("level", 5)
	var f := FileAccess.open("res://data/species/%s.json" % species_name, FileAccess.READ)
	if f == null:
		push_error("Fichier espèce introuvable : " + species_name)
		return MonsterInstance.new()
	return MonsterInstance.from_species(JSON.parse_string(f.get_as_text()), lvl)

# ─── UI ───────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.size = Vector2(320, 240)
	add_child(bg)
	_lbl_enemy   = _make_label(Vector2(10, 10),  Vector2(300, 50))
	_lbl_player  = _make_label(Vector2(10, 100), Vector2(300, 50))
	_lbl_message = _make_label(Vector2(10, 160), Vector2(300, 40))
	_lbl_menu    = _make_label(Vector2(10, 205), Vector2(300, 30))

func _make_label(pos: Vector2, sz: Vector2) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl)
	return lbl

func _refresh_ui() -> void:
	_lbl_enemy.text  = "%s  Niv.%d\nPV : %d / %d" % [
		enemy_monster.name, enemy_monster.level,
		enemy_monster.current_hp, enemy_monster.max_hp,
	]
	_lbl_player.text = "%s  Niv.%d\nPV : %d / %d" % [
		player_monster.name, player_monster.level,
		player_monster.current_hp, player_monster.max_hp,
	]

func _set_message(msg: String) -> void:
	_lbl_message.text = msg

func _set_state(new_state: State) -> void:
	state = new_state
	match state:
		State.PLAYER_TURN:
			_lbl_menu.text = "[E] Attaquer   [Z] Capturer   [A] Fuir"
		State.WAITING:
			_lbl_menu.text = ""
		State.VICTORY, State.DEFEAT:
			_lbl_menu.text = "[E] Continuer"

# ─── Input ────────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	match state:
		State.PLAYER_TURN:
			if Input.is_action_just_pressed("ui_accept"):
				_do_player_attack()
			elif Input.is_action_just_pressed("move_up"):
				_try_capture()
			elif Input.is_action_just_pressed("ui_cancel"):
				_flee()
		State.VICTORY, State.DEFEAT:
			if Input.is_action_just_pressed("ui_accept"):
				_return_to_world()

# ─── Actions ──────────────────────────────────────────────────────────────────

func _do_player_attack() -> void:
	_set_state(State.WAITING)
	var dmg := BattleLogic.calc_damage(player_monster, enemy_monster)
	enemy_monster.take_damage(dmg)
	_set_message("%s attaque ! -%d PV" % [player_monster.name, dmg])
	_refresh_ui()
	if not enemy_monster.is_alive():
		await get_tree().create_timer(1.0).timeout
		_set_message("%s est K.O. !" % enemy_monster.name)
		_set_state(State.VICTORY)
		return
	await get_tree().create_timer(0.7).timeout
	_do_enemy_attack()

func _do_enemy_attack() -> void:
	var dmg := BattleLogic.calc_damage(enemy_monster, player_monster)
	player_monster.take_damage(dmg)
	_set_message("%s attaque ! -%d PV" % [enemy_monster.name, dmg])
	_refresh_ui()
	if not player_monster.is_alive():
		await get_tree().create_timer(1.0).timeout
		_set_message("%s est K.O. !" % player_monster.name)
		_set_state(State.DEFEAT)
		return
	_set_state(State.PLAYER_TURN)

func _try_capture() -> void:
	_set_state(State.WAITING)
	if BattleLogic.calc_catch_success(enemy_monster):
		Global.player_team.append(enemy_monster)
		_set_message("Capturé ! %s rejoint l'équipe ! (%d)" % [
			enemy_monster.name, Global.player_team.size()
		])
		await get_tree().create_timer(1.5).timeout
		_return_to_world()
	else:
		_set_message("%s résiste ! La Poké Ball rate…" % enemy_monster.name)
		await get_tree().create_timer(0.8).timeout
		_do_enemy_attack()

func _flee() -> void:
	_return_to_world()

func _return_to_world() -> void:
	SaveManager.save()
	Global.pending_encounter = {}
	get_tree().change_scene_to_file("res://scenes/world/World.tscn")
