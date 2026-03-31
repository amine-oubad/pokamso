class_name BattleLogic
## Logique de combat isolée. Aucun état, aucune UI.
## Extensible : ajouter types, crit, statuts ici sans toucher à Battle.gd.

## Formule minimale. move_power : puissance du move utilisé (défaut 40).
## Compatible avec future extension (types, STAB, crit…).
static func calc_damage(attacker: MonsterInstance, defender: MonsterInstance, move_power: int = 40) -> int:
	return maxi(1, attacker.atk * move_power / 50 - defender.def / 2)

## Chance de capture : base (catch_rate/255) doublée à 1 PV.
## Extensible : ajouter objets, statuts, badges ici.
static func calc_catch_success(enemy: MonsterInstance) -> bool:
	var hp_ratio: float = float(enemy.current_hp) / float(enemy.max_hp)
	var chance: float = (enemy.catch_rate / 255.0) * (2.0 - hp_ratio)
	return randf() < chance
