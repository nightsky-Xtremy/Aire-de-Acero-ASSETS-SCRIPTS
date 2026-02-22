extends Node

# Define oleadas simples: lista de dicionarios
@export var waves: Array = [
	{"enemy": preload("res://scenes/enemies/EnemyZigzag.tscn"), "count": 8, "gap": 1.2, "x_range": Vector2(50, 430)},
	{"enemy": preload("res://scenes/enemies/EnemyBasic.tscn"), "count": 12, "gap": 0.9, "x_range": Vector2(30, 470)}
]
@export var inter_wave_delay: float = 3.0

var _current_wave = 0
var _spawning = false

func start_waves():
	_current_wave = 0
	_spawn_next_wave()

func _spawn_next_wave():
	if _current_wave >= waves.size():
		emit_signal("waves_finished")
		return
	_spawning = true
	var w = waves[_current_wave]
	spawn_wave(w)
	_current_wave += 1

func spawn_wave(wave):
	var count = wave.get("count", 5)
	var gap = wave.get("gap", 1.0)
	var enemy_scene: PackedScene = wave.get("enemy")
	var x_min = wave.get("x_range").x
	var x_max = wave.get("x_range").y
	# coroutine-like spawning
	for i in range(count):
		var e = enemy_scene.instantiate()
		var x = randf_range(x_min, x_max)
		e.position = Vector2(x, -60 - i*20) # spawn por encima
		get_tree().current_scene.add_child(e)
		await get_tree().create_timer(gap).timeout
	# espera inter-wave
	await get_tree().create_timer(inter_wave_delay).timeout
	_spawn_next_wave()
