extends Node2D

# --- SEÑALES ---
signal nivel_completado_boss

# --- CONFIGURACIÓN DE ESCENAS ---
@export_group("Escenas")
@export var boss_scene: PackedScene = preload("res://scenes/enemies/Plane/BossLv4.tscn")
@export var escort_scene: PackedScene = preload("res://scenes/enemies/Plane/EnemyKamikaze.tscn")

@export_group("Configuración de Escoltas")
@export var tiempo_spawn_escort: float = 3.0
@export var max_escoltas_simultaneos: int = 2

# --- VARIABLES DE ESTADO ---
var boss_instancia: CharacterBody2D = null
var timer_escort: Timer
var horda_activa: bool = true

func _ready():
	# Usamos call_deferred para esperar a que el nivel esté totalmente cargado
	call_deferred("_iniciar_combate")

func _iniciar_combate():
	_spawn_boss()
	_configurar_timer_escoltas()

func _spawn_boss():
	if not boss_scene: 
		print("❌ Error: No se ha asignado boss_scene en el Inspector")
		return
	
	boss_instancia = boss_scene.instantiate()
	
	# Usamos el tamaño del viewport actual de forma segura
	var sw = get_viewport_rect().size.x
	if sw <= 0: sw = 540 # Fallback por si acaso
	
	# Añadimos al boss a la escena actual para evitar problemas de herencia
	get_tree().current_scene.add_child(boss_instancia)
	
	# Posición: Centro horizontal, fuera de pantalla arriba (-100)
	boss_instancia.global_position = Vector2(sw / 2, -100)
	
	# Conectar la señal tree_exited (se activa cuando el boss hace queue_free)
	boss_instancia.tree_exited.connect(_on_boss_defeated)
	print("🛸 Boss Lv4 instanciado en: ", boss_instancia.global_position)

func _configurar_timer_escoltas():
	timer_escort = Timer.new()
	timer_escort.name = "TimerEscoltas"
	add_child(timer_escort)
	timer_escort.wait_time = tiempo_spawn_escort
	timer_escort.timeout.connect(_on_escort_timer_timeout)
	timer_escort.start()

func _on_escort_timer_timeout():
	if not horda_activa or not is_inside_tree(): return
	
	# Contamos enemigos en el grupo 'enemy'
	var enemigos_actuales = get_tree().get_nodes_in_group("enemy").size()
	
	# Límite: Max escoltas + 1 (el Boss)
	if enemigos_actuales < (max_escoltas_simultaneos + 1):
		spawn_escort()

func spawn_escort():
	if not escort_scene: return
	var escort = escort_scene.instantiate()
	
	var sw = get_viewport_rect().size.x
	var x_pos = [50, sw - 50].pick_random()
	
	escort.global_position = Vector2(x_pos, -80)
	get_tree().current_scene.add_child(escort)

func _on_boss_defeated():
	# Verificamos si el árbol existe
	if not is_inside_tree() or get_tree() == null:
		return
		
	horda_activa = false
	if timer_escort: timer_escort.stop()
	
	print("!!! EL BOSS HA MUERTO - EMITIENDO SEÑAL !!!")
	
	# Emitimos la señal normal
	nivel_completado_boss.emit()
	
	# OPCIONAL: Si la señal falla, buscamos al padre directamente y avisamos
	if get_parent().has_method("_on_victoria_boss"):
		get_parent()._on_victoria_boss()

func detener_spawner():
	horda_activa = false
	if timer_escort:
		timer_escort.stop()
