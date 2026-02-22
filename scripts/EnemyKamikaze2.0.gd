extends CharacterBody2D

# ==================================================
# CONFIGURACIÓN (VALORES AGRESIVOS)
# ==================================================
@export_group("Movimiento")
@export var velocidad_preparacion: float = 280.0
@export var velocidad_embestida_inicial: float = 750.0 
@export var aceleracion_embestida: float = 1200.0
@export var agilidad_giro: float = 0.20

@export_group("Estadísticas")
@export var max_health: int = 5
@export var tiempo_fijado: float = 0.1

# ==================================================
# VARIABLES DE ESTADO
# ==================================================
enum { BUSCANDO, PREPARANDO, EMBESTIDA, MUERTO }
var estado_actual = BUSCANDO

var health: int
var player: Node2D = null
var is_dying: bool = false
var direccion_fijada: Vector2 = Vector2.DOWN
var velocidad_actual_embestida: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")
	health = max_health
	_find_player()
	# Tiempo de espera aleatorio para que no todos ataquen al mismo segundo
	get_tree().create_timer(randf_range(0.3, 0.7)).timeout.connect(_iniciar_preparacion)

func _find_player():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if is_dying:
		handle_death_animation(delta)
		return

	match estado_actual:
		BUSCANDO:
			_logica_busqueda(delta)
		PREPARANDO:
			_logica_preparacion(delta)
		EMBESTIDA:
			_logica_embestida(delta)

	_comprobar_fuera_de_pantalla()
	check_player_collision()

# --- LÓGICA DE ESTADOS ---

func _logica_busqueda(delta):
	var dir_to_player = Vector2.DOWN
	if is_instance_valid(player):
		dir_to_player = (player.global_position - global_position).normalized()
		# Rotación agresiva
		var target_angle = dir_to_player.angle() + deg_to_rad(90)
		rotation = lerp_angle(rotation, target_angle, agilidad_giro)
	
	velocity = Vector2.DOWN * velocidad_preparacion
	move_and_slide()

func _iniciar_preparacion():
	if is_dying or estado_actual != BUSCANDO: return
	
	estado_actual = PREPARANDO
	
	# Efecto de carga violento: Vibración y parpadeo rápido
	var tween = create_tween().set_loops(5)
	tween.tween_property(animated_sprite, "position", Vector2(3, 0), 0.05)
	tween.tween_property(animated_sprite, "position", Vector2(-3, 0), 0.05)
	animated_sprite.modulate = Color(2, 0.5, 0.5) # Brillo rojizo
	
	await get_tree().create_timer(tiempo_fijado).timeout
	
	if is_instance_valid(player):
		direccion_fijada = (player.global_position - global_position).normalized()
	else:
		direccion_fijada = Vector2.DOWN
		
	estado_actual = EMBESTIDA
	velocidad_actual_embestida = velocidad_embestida_inicial
	animated_sprite.position = Vector2.ZERO
	animated_sprite.modulate = Color.WHITE
	rotation = direccion_fijada.angle() + deg_to_rad(90)

func _logica_preparacion(delta):
	velocity = velocity.lerp(Vector2.ZERO, 0.2)
	move_and_slide()
	
	if is_instance_valid(player):
		var target_angle = (player.global_position - global_position).angle() + deg_to_rad(90)
		rotation = lerp_angle(rotation, target_angle, 0.15)

func _logica_embestida(delta):
	# Aceleración progresiva: empieza rápido y termina volando
	velocidad_actual_embestida += aceleracion_embestida * delta
	velocity = direccion_fijada * velocidad_actual_embestida
	move_and_slide()

# --- UTILIDADES ---

func _comprobar_fuera_de_pantalla():
	var viewport_size = get_viewport_rect().size
	var margin = 300 
	if global_position.y > viewport_size.y + margin or \
	   global_position.y < -margin or \
	   global_position.x < -margin or \
	   global_position.x > viewport_size.x + margin:
		queue_free()

func check_player_collision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage()
			start_death()

func take_damage(damage: int = 1):
	if is_dying: return
	health -= damage
	_flash_effect()
	if health <= 0: start_death()

func _flash_effect():
	animated_sprite.modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.05).timeout
	animated_sprite.modulate = Color.WHITE

func start_death():
	if is_dying: return
	is_dying = true
	estado_actual = MUERTO
	collision_layer = 0
	collision_mask = 0
	if animated_sprite.sprite_frames.has_animation("explosion"):
		animated_sprite.play("explosion")

func handle_death_animation(delta):
	global_position.y += 300 * delta 
	animated_sprite.scale -= Vector2.ONE * 2.5 * delta
	if animated_sprite.scale.x <= 0.01:
		queue_free()
