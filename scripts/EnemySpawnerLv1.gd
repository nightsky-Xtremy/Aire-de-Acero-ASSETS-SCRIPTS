extends Node2D

# --- SEÑALES ---
signal spawn_finalizado # Se emite cuando se alcanza el límite de enemigos

# --- CONFIGURACIÓN ---
@export_group("Configuración de Horda")
@export var enemy_scene: PackedScene = preload("res://scenes/enemies/Plane/EnemyBasic.tscn")
@export var enemigos_totales: int = 40    # Cuántos enemigos saldrán en el Nivel 1
@export var tiempo_inicial: float = 2.0   # Segundos entre enemigos al empezar
@export var tiempo_minimo: float = 0.5    # El límite de velocidad (frenético)
@export var reduccion_dificultad: float = 0.08 # Cuánto acelera por cada spawn

# --- VARIABLES DE ESTADO ---
var enemigos_generados: int = 0
var nivel_completado: bool = false
var screen_size: Vector2
var timer: Timer

func _ready():
	screen_size = get_viewport_rect().size
	_configurar_timer()

func _configurar_timer():
	# Buscar el nodo Timer o crearlo si no existe
	timer = find_child("Timer", true, false)
	if not timer:
		timer = Timer.new()
		add_child(timer)
	
	timer.wait_time = tiempo_inicial
	timer.autostart = true
	timer.timeout.connect(_on_spawn_timer_timeout)
	timer.start()
	print("🔥 Horda iniciada. Objetivo: ", enemigos_totales, " enemigos.")

func _on_spawn_timer_timeout():
	if nivel_completado:
		return

	# Verificar si aún debemos spawnear
	if enemigos_generados < enemigos_totales:
		# LÓGICA AGRESIVA: 20% de probabilidad de mini-oleada (3 enemigos)
		if randf() < 0.20 and (enemigos_totales - enemigos_generados) >= 3:
			for i in range(3):
				spawn_enemy()
		else:
			spawn_enemy()
		
		# Aumentar dificultad bajando el tiempo del timer
		if timer.wait_time > tiempo_minimo:
			timer.wait_time -= reduccion_dificultad
	else:
		# Finalizar spawn
		nivel_completado = true
		timer.stop()
		emit_signal("spawn_finalizado")
		print("✅ Todos los enemigos han sido desplegados.")

func spawn_enemy():
	if not enemy_scene:
		push_error("Error: No has asignado la escena del enemigo en el Spawner.")
		return

	var enemy = enemy_scene.instantiate()
	
	# Calcular posición X aleatoria con margen de seguridad
	var x_pos = randf_range(50, screen_size.x - 50)
	var y_pos = -80 # Empieza fuera de cámara por arriba
	
	enemy.global_position = Vector2(x_pos, y_pos)
	
	# Añadirlo a la escena principal (no al spawner)
	get_tree().current_scene.add_child(enemy)
	enemigos_generados += 1

# Función de utilidad para detener el caos si el jugador muere
func detener_spawner():
	nivel_completado = true
	if timer:
		timer.stop()
	print("🛑 Spawner desactivado.")
