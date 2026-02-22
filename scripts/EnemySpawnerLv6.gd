extends Node2D

# --- SEÑALES ---
signal nivel_completado_boss

# --- CONFIGURACIÓN DE ESCENAS ---
@export_group("Escenas")
@export var boss_scene: PackedScene = preload("res://scenes/enemies/Plane/BossAS.tscn")
@export var escort_scene_1: PackedScene = preload("res://scenes/enemies/Plane/EnemyBasic.tscn")
@export var escort_scene_2: PackedScene = preload("res://scenes/enemies/Plane/EnemyKamikaze2.0.tscn")

@export_group("Configuración de Escoltas")
@export var tiempo_spawn_escort: float = 1.5 
@export var max_escoltas_simultaneos: int = 6

# --- VARIABLES DE ESTADO ---
var boss_instancia: CharacterBody2D = null
var timer_escort: Timer
var horda_activa: bool = true

func _ready():
	add_to_group("spawner")
	call_deferred("_iniciar_combate")

func _iniciar_combate():
	if not is_inside_tree(): return
	_spawn_boss()
	_configurar_timer_escoltas()

func _spawn_boss():
	if not boss_scene: return
	
	boss_instancia = boss_scene.instantiate()
	var sw = get_viewport_rect().size.x
	if sw <= 0: sw = 540 
	
	get_tree().current_scene.add_child(boss_instancia)
	boss_instancia.global_position = Vector2(sw / 2, -100)
	
	# Conexión segura usando CONNECT_DEFERRED para evitar colisiones de hilos
	if not boss_instancia.tree_exited.is_connected(_on_boss_defeated):
		boss_instancia.tree_exited.connect(_on_boss_defeated, CONNECT_DEFERRED)
		
	print("🚀 EL BOSS AS (SK-X) HA ENTRADO EN COMBATE")

func _configurar_timer_escoltas():
	timer_escort = Timer.new()
	timer_escort.name = "TimerEscoltas"
	add_child(timer_escort)
	timer_escort.wait_time = tiempo_spawn_escort
	timer_escort.timeout.connect(_on_escort_timer_timeout)
	timer_escort.start()

func _on_escort_timer_timeout():
	# Verificación de seguridad ANTES de cualquier lógica de grupo
	if not horda_activa or not is_inside_tree() or get_tree() == null: 
		return
	
	var enemigos = get_tree().get_nodes_in_group("enemy")
	var conteo = 0
	for e in enemigos:
		if is_instance_valid(e) and e != boss_instancia:
			conteo += 1
	
	if conteo < max_escoltas_simultaneos:
		_spawn_random_escort()

func _spawn_random_escort():
	if not is_inside_tree(): return
	
	var escena_a_instanciar: PackedScene
	if escort_scene_1 and escort_scene_2:
		escena_a_instanciar = [escort_scene_1, escort_scene_2].pick_random()
	else:
		escena_a_instanciar = escort_scene_1 if escort_scene_1 else escort_scene_2

	if not escena_a_instanciar: return
	
	var escort = escena_a_instanciar.instantiate()
	var sw = get_viewport_rect().size.x
	var x_pos = randf_range(60, sw - 60)
	
	escort.global_position = Vector2(x_pos, -80)
	get_tree().current_scene.add_child(escort)

# --- LLAMADAS DE FINALIZACIÓN ---

func _on_boss_muerto():
	_finalizar_nivel()

func _on_boss_defeated():
	_finalizar_nivel()

func _finalizar_nivel():
	# CLÁUSULA DE GUARDA CRÍTICA
	# Si el árbol ya no existe o el nodo está fuera, abortamos inmediatamente
	var tree = get_tree()
	if tree == null or not is_inside_tree():
		return
	
	if not horda_activa: 
		return
	
	horda_activa = false
	
	if is_instance_valid(timer_escort):
		timer_escort.stop()
	
	print("🏆 VICTORIA FINAL: EMITIENDO SEÑAL")
	nivel_completado_boss.emit()
	
	# Limpieza segura utilizando el 'tree' validado
	var escoltas = tree.get_nodes_in_group("enemy")
	for e in escoltas:
		if is_instance_valid(e) and e != boss_instancia:
			if e.has_method("start_death"):
				e.start_death()
			else:
				e.queue_free()

func detener_spawner():
	horda_activa = false
	if is_instance_valid(timer_escort):
		timer_escort.stop()
