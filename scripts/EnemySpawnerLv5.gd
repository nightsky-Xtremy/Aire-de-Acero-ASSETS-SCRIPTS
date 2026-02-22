extends Node2D

# --- SEÑALES ---
signal nivel_completado_boss

# --- CONFIGURACIÓN DE ESCENAS ---
@export_group("Escenas")
@export var boss_scene: PackedScene = preload("res://scenes/enemies/Plane/BossLv5.tscn")
@export var escort_scene: PackedScene = preload("res://scenes/enemies/Plane/EnemyKamikaze2.0.tscn")

@export_group("Configuración de Escoltas")
@export var tiempo_spawn_escort: float = 2.0
@export var max_escoltas_simultaneos: int = 5

# --- VARIABLES DE ESTADO ---
var boss_instancia: CharacterBody2D = null
var timer_escort: Timer
var horda_activa: bool = true

func _ready():
	# IMPORTANTE: Aseguramos que el Spawner esté en el grupo para que el Boss lo encuentre
	add_to_group("spawner")
	
	# Esperar a que el nivel esté listo
	call_deferred("_iniciar_combate")

func _iniciar_combate():
	_spawn_boss()
	_configurar_timer_escoltas()

func _spawn_boss():
	if not boss_scene: 
		print("❌ Error: No se ha asignado boss_scene en el Inspector")
		return
	
	boss_instancia = boss_scene.instantiate()
	
	var sw = get_viewport_rect().size.x
	if sw <= 0: sw = 540 
	
	# Añadimos al boss a la escena actual
	get_tree().current_scene.add_child(boss_instancia)
	
	# Posición inicial
	boss_instancia.global_position = Vector2(sw / 2, -100)
	
	# CONEXIÓN DE SEGURIDAD: 
	# Si el boss se libera de memoria por cualquier razón, disparamos la victoria
	if not boss_instancia.tree_exited.is_connected(_on_boss_defeated):
		boss_instancia.tree_exited.connect(_on_boss_defeated)
		
	print("🛸 Boss Lv5 instanciado y monitoreado")

func _configurar_timer_escoltas():
	timer_escort = Timer.new()
	timer_escort.name = "TimerEscoltas"
	add_child(timer_escort)
	timer_escort.wait_time = tiempo_spawn_escort
	timer_escort.timeout.connect(_on_escort_timer_timeout)
	timer_escort.start()

func _on_escort_timer_timeout():
	if not horda_activa or not is_inside_tree(): return
	
	# Contamos enemigos (sin contar al Boss)
	var enemigos = get_tree().get_nodes_in_group("enemy")
	var conteo = 0
	for e in enemigos:
		if e != boss_instancia:
			conteo += 1
	
	if conteo < max_escoltas_simultaneos:
		spawn_escort()

func spawn_escort():
	if not escort_scene: return
	var escort = escort_scene.instantiate()
	
	var sw = get_viewport_rect().size.x
	var x_pos = randf_range(50, sw - 50) # Más variedad que solo los dos lados
	
	escort.global_position = Vector2(x_pos, -80)
	get_tree().current_scene.add_child(escort)

# --- FUNCIÓN LLAMADA POR EL BOSS AL MORIR ---
func _on_boss_muerto():
	print("🎯 El Boss ha notificado su destrucción")
	_finalizar_nivel()

# --- LÓGICA DE FINALIZACIÓN ---
func _on_boss_defeated():
	# Verificamos si el nodo aún es parte del árbol activo
	if is_inside_tree():
		_finalizar_nivel()

func _finalizar_nivel():
	# Si ya no hay árbol (porque estamos cambiando de escena), abortamos
	var tree = get_tree()
	if tree == null:
		return
		
	if not horda_activa: 
		return
	
	horda_activa = false
	if is_instance_valid(timer_escort): 
		timer_escort.stop()
	
	print("🏆 Nivel finalizado con éxito.")
	nivel_completado_boss.emit()
	
	# Limpieza segura de enemigos
	var enemigos = tree.get_nodes_in_group("enemy")
	for e in enemigos:
		if is_instance_valid(e) and e != boss_instancia:
			e.queue_free()
