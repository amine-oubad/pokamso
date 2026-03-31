extends Node
## Autoload minimal — données partagées entre scènes.

## Données de la rencontre en cours. Vide si aucune.
## Structure : { "species_id": "001", "name": "Bulbasaur", "level": 5 }
var pending_encounter: Dictionary = {}

## Position joueur sauvegardée avant transition de scène.
var player_tile_pos: Vector2i = Vector2i(10, 7)

## Monstre actif du joueur. Même format que les entrées du pool de rencontre.
var player_monster_data: Dictionary = { "species_id": "001", "name": "Bulbasaur", "level": 10 }

## Équipe du joueur — liste de MonsterInstance capturées.
var player_team: Array = []
