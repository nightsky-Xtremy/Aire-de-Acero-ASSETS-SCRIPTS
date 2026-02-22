extends Node2D

# Escenas de los enemigos que ya tenemos
@export var enemy_basic: PackedScene
@export var enemy_hunter: PackedScene
@export var boss_as: PackedScene

@onready var spawn_timer = $SpawnTimer

var wave_number = 1
var enemies_spawned_in_wave = 0

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	spawn_enemy()

func spawn_enemy():
	var enemy_to_spawn: CharacterBody2D
	
	# LÓGICA DE OLEADAS (NIVEL 1)
	if wave_number == 1:
		# Solo enemigos básicos al principio
		enemy_to_spawn = enemy_basic.instantiate()
		enemies_spawned_in_wave += 1
		
		if enemies_spawned_in_wave >= 10: # Al llegar a 10 enemigos, pasamos a wave 2
			wave_number = 2
			enemies_spawned_in_wave = 0
			spawn_timer.wait_time = 1.5 # Más rápido
			
	elif wave_number == 2:
		# Mezclamos básicos y Hunters
		var chance = randf()
		if chance > 0.7:
			enemy_to_spawn = enemy_hunter.instantiate()
		else:
			enemy_to_spawn = enemy_basic.instantiate()
		
		enemies_spawned_in_wave += 1
		if enemies_spawned_in_wave >= 15:
			wave_number = 3 # ¡Llega el jefe!
			enemies_spawned_in_wave = 0
			spawn_boss()
			return # Salimos para no spawnear enemigos normales ahora

	# Posición aleatoria en la parte superior de la pantalla
	if enemy_to_spawn:
		var screen_width = get_viewport_rect().size.x
		enemy_to_spawn.global_position = Vector2(randf_range(50, screen_width - 50), -50)
		get_parent().add_child(enemy_to_spawn)

func spawn_boss():
	spawn_timer.stop() # Paramos enemigos pequeños
	var boss = boss_as.instantiate()
	var screen_width = get_viewport_rect().size.x
	boss.global_position = Vector2(screen_width / 2, -100)
	get_parent().add_child(boss)
	print("¡ALERTA: BOSS AS HA LLEGADO!")
