class_name MonsterInstance
## Instance individuelle d'un monstre.
## Séparée des données d'espèce (species JSON) et de la logique de combat.

static var _next_uid: int = 1

var uid: int = 0
var species_id: String = ""
var name: String = ""
var level: int = 1
var max_hp: int = 1
var current_hp: int = 1
var atk: int = 1
var def: int = 1
var catch_rate: int = 45  # issu des données d'espèce
var moves: Array = []     # liste de move_id — non utilisée encore

## Construit une instance depuis un dict d'espèce (chargé depuis JSON) et un niveau.
static func from_species(data: Dictionary, lvl: int) -> MonsterInstance:
	var m := MonsterInstance.new()
	m.uid        = _next_uid; _next_uid += 1
	m.species_id = data.get("id", "???")
	m.name       = data.get("name", "???")
	m.level      = lvl
	m.catch_rate = data.get("catch_rate", 45)
	var base: Dictionary = data.get("base_stats", {})
	m.max_hp     = maxi(1, int(base.get("hp",  10) * lvl / 20.0) + lvl)
	m.atk        = maxi(1, int(base.get("atk", 10) / 10.0) + lvl / 5)
	m.def        = maxi(1, int(base.get("def", 10) / 10.0) + lvl / 5)
	m.current_hp = m.max_hp
	return m

func is_alive() -> bool:
	return current_hp > 0

func take_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - amount)
