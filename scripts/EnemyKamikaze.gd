extends CharacterBody2D

# ==================================================
# CONFIGURACIÓN
# ==================================================
@export_group("Movimiento")
@export var velocidad_preparacion: float = 100.0
@export var velocidad_embestida: float = 600.0 # Mucho más rápido que el Hunter
@export var tiempo_fijado: float = 0.8 # Tiempo que tarda en "apuntar" antes de salir disparado

@export_group("Estadísticas")
@export var max_health: int = 1
@export var death_fall_speed: float = 250.0
@export var shrink_speed: float = 2.0 

# ==================================================
# VARIABLES DE ESTADO
# ==================================================
enum { BUSCANDO, PREPARANDO, EMBESTIDA, MUERTO }
var estado_actual = BUSCANDO

var health: int
var player: Node2D = null
var is_dying: bool = false
var direccion_fijada: Vector2 = Vector2.DOWN

# ==================================================
# NODOS
# ==================================================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")
	health = max_health
	_find_player()
	# Iniciamos la lógica de preparación poco después de aparecer
	get_tree().create_timer(0.5).timeout.connect(_iniciar_preparacion)

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
	# Se mueve lentamente hacia abajo mientras busca al jugador
	velocity = Vector2.DOWN * velocidad_preparacion
	move_and_slide()
	
	if is_instance_valid(player):
		rotation = lerp_angle(rotation, (player.global_position - global_position).angle() + deg_to_rad(90), 0.1)

func _iniciar_preparacion():
	if is_dying or estado_actual != BUSCANDO: return
	
	estado_actual = PREPARANDO
	
	# Efecto visual de carga (parpadeo rojo)
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, tiempo_fijado / 2)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, tiempo_fijado / 2)
	
	await get_tree().create_timer(tiempo_fijado).timeout
	
	if is_instance_valid(player):
		direccion_fijada = (player.global_position - global_position).normalized()
	else:
		direccion_fijada = Vector2.DOWN
		
	estado_actual = EMBESTIDA
	# Girar hacia la dirección final del ataque
	rotation = direccion_fijada.angle() + deg_to_rad(90)

func _logica_preparacion(delta):
	# Se queda casi quieto vibrando o moviéndose muy lento
	velocity = velocity.lerp(Vector2.ZERO, 0.1)
	move_and_slide()

func _logica_embestida(delta):
	# Movimiento en línea recta a alta velocidad
	velocity = direccion_fijada * velocidad_embestida
	move_and_slide()

# --- UTILIDADES ---

func _comprobar_fuera_de_pantalla():
	var viewport_size = get_viewport_rect().size
	var margin = 250
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

# ==================================================
# DAÑO Y MUERTE (Basado en Hunter)
# ==================================================
func take_damage(damage: int = 1):
	if is_dying: return
	health -= damage
	_flash_effect()
	if health <= 0: start_death()

func _flash_effect():
	var prev_mod = modulate
	modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.05).timeout
	modulate = prev_mod

func start_death():
	if is_dying: return
	is_dying = true
	estado_actual = MUERTO
	
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	if animated_sprite.sprite_frames.has_animation("explosion"):
		animated_sprite.play("explosion")

func handle_death_animation(delta):
	global_position.y += death_fall_speed * delta
	animated_sprite.scale -= Vector2.ONE * shrink_speed * delta
	if animated_sprite.scale.x <= 0.01:
		queue_free()
