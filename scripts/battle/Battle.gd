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
	# Premier monstre de l'équipe comme actif, fallback sur player_monster_data si équipe vide.
	if Global.player_team.size() > 0:
		var first_alive: MonsterInstance = null
		for m in Global.player_team:
			if m.is_alive():
				first_alive = m
				break
		player_monster = first_alive if first_alive != null else Global.player_team[0]
	else:
		player_monster = _load_monster(Global.player_monster_data)
		Global.player_team.append(player_monster)  # intègre le starter à l'équipe
	enemy_monster  = _load_monster(Global.pending_encounter)
	_refresh_ui()
	_set_message("%s sauvage apparaît !" % enemy_monster.name)
	_set_state(State.PLAYER_TURN)

func _load_monster(data: Dictionary) -> MonsterInstance:
	var species_id: String = data.get("species_id", "001")
	var lvl: int = data.get("level", 5)
	var species_data := SpeciesDB.get_species(species_id)
	if species_data.is_empty():
		return MonsterInstance.new()
	return MonsterInstance.from_species(species_data, lvl)

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
			_lbl_menu.text = _build_menu_text()
		State.WAITING:
			_lbl_menu.text = ""
		State.VICTORY, State.DEFEAT:
			_lbl_menu.text = "[E] Continuer"

# ─── Input ────────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	match state:
		State.PLAYER_TURN:
			if Input.is_action_just_pressed("ui_accept"):
				_do_player_attack(0)
			elif Input.is_action_just_pressed("move_down") and player_monster.moves.size() > 1:
				_do_player_attack(1)
			elif Input.is_action_just_pressed("move_up"):
				_try_capture()
			elif Input.is_action_just_pressed("ui_cancel"):
				_flee()
		State.VICTORY, State.DEFEAT:
			if Input.is_action_just_pressed("ui_accept"):
				_return_to_world()

# ─── Actions ──────────────────────────────────────────────────────────────────

func _build_menu_text() -> String:
	var moves := player_monster.moves
	var m1: String = moves[0].get("name", "Attaque") if moves.size() > 0 else "Attaque"
	var m2: String = moves[1].get("name", "") if moves.size() > 1 else ""
	var text := "[E] %s" % m1
	if m2 != "":
		text += "  [S] %s" % m2
	return text + "  [Z] Capturer  [A] Fuir"

func _do_player_attack(move_index: int = 0) -> void:
	_set_state(State.WAITING)
	var moves := player_monster.moves
	var move: Dictionary = moves[move_index] if move_index < moves.size() else {}
	var move_name: String = move.get("name", "Attaque")
	var move_power: int = move.get("power", 40)
	var dmg := BattleLogic.calc_damage(player_monster, enemy_monster, move_power)
	enemy_monster.take_damage(dmg)
	_set_message("%s utilise %s ! -%d PV" % [player_monster.name, move_name, dmg])
	_refresh_ui()
	if not enemy_monster.is_alive():
		await get_tree().create_timer(1.0).timeout
		_set_message("%s est K.O. !" % enemy_monster.name)
		_set_state(State.VICTORY)
		return
	await get_tree().create_timer(0.7).timeout
	_do_enemy_attack()

func _do_enemy_attack() -> void:
	var moves := enemy_monster.moves
	var move: Dictionary = moves[randi() % moves.size()] if not moves.is_empty() else {}
	var move_name: String = move.get("name", "Attaque")
	var move_power: int = move.get("power", 40)
	var dmg := BattleLogic.calc_damage(enemy_monster, player_monster, move_power)
	player_monster.take_damage(dmg)
	_set_message("%s utilise %s ! -%d PV" % [enemy_monster.name, move_name, dmg])
	_refresh_ui()
	if not player_monster.is_alive():
		_set_message("%s est K.O. !" % player_monster.name)
		await get_tree().create_timer(1.0).timeout
		var next := _find_next_alive()
		if next == null:
			_set_state(State.DEFEAT)
			return
		player_monster = next
		_set_message("%s entre en combat !" % player_monster.name)
		_refresh_ui()
		await get_tree().create_timer(0.8).timeout
		_set_state(State.PLAYER_TURN)
		return
	_set_state(State.PLAYER_TURN)

func _try_capture() -> void:
	_set_state(State.WAITING)
	if Global.player_team.size() >= Global.TEAM_MAX:
		_set_message("Équipe pleine ! (%d/%d)" % [Global.player_team.size(), Global.TEAM_MAX])
		await get_tree().create_timer(0.8).timeout
		_do_enemy_attack()
		return
	if BattleLogic.calc_catch_success(enemy_monster):
		Global.player_team.append(enemy_monster)
		_set_message("Capturé ! %s rejoint l'équipe ! (%d/%d)" % [
			enemy_monster.name, Global.player_team.size(), Global.TEAM_MAX
		])
		await get_tree().create_timer(1.5).timeout
		_return_to_world()
	else:
		_set_message("%s résiste ! La Poké Ball rate…" % enemy_monster.name)
		await get_tree().create_timer(0.8).timeout
		_do_enemy_attack()

func _find_next_alive() -> MonsterInstance:
	var current_index := Global.player_team.find(player_monster)
	if current_index == -1:
		return null
	for i in range(current_index + 1, Global.player_team.size()):
		var m: MonsterInstance = Global.player_team[i]
		if m.is_alive():
			return m
	return null

func _flee() -> void:
	_return_to_world()

func _return_to_world() -> void:
	SaveManager.save()
	Global.pending_encounter = {}
	get_tree().change_scene_to_file("res://scenes/world/World.tscn")
