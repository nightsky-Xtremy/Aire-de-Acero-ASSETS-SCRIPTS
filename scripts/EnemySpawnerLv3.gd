extends Node2D

# --- SEÑALES ---
signal spawn_finalizado 

# --- CONFIGURACIÓN DE ESCENAS (NIVEL 3) ---
@export_group("Escenas de Enemigos")
@export var hunter_scene: PackedScene = preload("res://scenes/enemies/Plane/EnemyBasic.tscn")
@export var tank_scene: PackedScene = preload("res://scenes/enemies/Ships/EnemyShip.tscn")

@export_group("Configuración de Horda")
@export var enemigos_totales: int = 50
@export var tiempo_inicial: float = 2.0
@export var tiempo_minimo: float = 1.6
@export var reduccion_dificultad: float = 0.05 

# --- VARIABLES DE ESTADO ---
var enemigos_generados: int = 0
var nivel_completado: bool = false
var screen_size: Vector2
var timer: Timer

func _ready():
	screen_size = get_viewport_rect().size
	_configurar_timer()

func _configurar_timer():
	timer = find_child("Timer", true, false)
	if not timer:
		timer = Timer.new()
		timer.name = "Timer"
		add_child(timer)
	
	timer.wait_time = tiempo_inicial
	if not timer.timeout.is_connected(_on_spawn_timer_timeout):
		timer.timeout.connect(_on_spawn_timer_timeout)
	
	timer.start()
	print("🔥 Horda Nivel 3 iniciada. Objetivo: ", enemigos_totales)

func _on_spawn_timer_timeout():
	if nivel_completado:
		return

	if enemigos_generados < enemigos_totales:
		# Lógica de ráfaga (opcional para el Nivel 3)
		if randf() < 0.20 and (enemigos_totales - enemigos_generados) >= 3:
			for i in range(3):
				spawn_enemy()
		else:
			spawn_enemy()
		
		# Aumentar dificultad
		if timer.wait_time > tiempo_minimo:
			timer.wait_time -= reduccion_dificultad
	else:
		_finalizar_horda()

func spawn_enemy():
	# --- LÓGICA DE CONTROL DE NAVE ÚNICA ---
	# Contamos cuántos barcos hay en el grupo "enemy_ship"
	var barcos_en_pantalla = get_tree().get_nodes_in_group("enemy_ship").size()
	
	var chosen_scene: PackedScene
	
	# Si ya hay un barco, forzamos a que salga un Hunter
	if barcos_en_pantalla >= 1:
		chosen_scene = hunter_scene
	else:
		# Si no hay barcos, usamos la probabilidad (70% Hunter, 30% Ship)
		chosen_scene = hunter_scene if randf() < 0.70 else tank_scene
	
	if not chosen_scene:
		return

	var enemy = chosen_scene.instantiate()
	
	# Posición aleatoria
	var x_pos = randf_range(50, screen_size.x - 50)
	enemy.global_position = Vector2(x_pos, -80)
	
	get_tree().current_scene.add_child(enemy)
	enemigos_generados += 1

func _finalizar_horda():
	nivel_completado = true
	timer.stop()
	print("📢 Emitiendo señal: spawn_finalizado")
	emit_signal("spawn_finalizado")

func detener_spawner():
	nivel_completado = true
	if timer:
		timer.stop()
