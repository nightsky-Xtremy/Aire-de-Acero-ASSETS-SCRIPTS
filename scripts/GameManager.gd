extends Node

signal level_completed(score:int)

@export var score: int = 0

func _ready():
	# conectar señal de WaveSpawner
	pass

func enemy_destroyed(points:int):
	score += points

func check_level_clear():
	# si no hay enemigos en pantalla y el spawner terminó
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.empty():
		emit_signal("level_completed", score)
