extends CharacterBody2D

# ===============================
# CONFIGURACIÓN
# ===============================
@export var speed: float = 250.0
@export var zigzag_amplitude: float = 120.0
@export var zigzag_frequency: float = 3.0
@export var fire_rate: float = 1.5
@export var bullet_scene: PackedScene

# ===============================
# VARIABLES
# ===============================
var time_passed: float = 0.0
var start_x: float
var screen_size: Vector2
var can_shoot: bool = true
var is_dying: bool = false 

# ===============================
# NODOS
# ===============================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")
	screen_size = get_viewport_rect().size
	# Posicionamiento inicial aleatorio
	var random_x = randf_range(60, screen_size.x - 60)
	global_position = Vector2(random_x, -100)
	start_x = global_position.x
	
	if animated_sprite:
		animated_sprite.play("default")

func _physics_process(delta):
	if is_dying:
		return

	time_passed += delta
	velocity.y = speed

	# Movimiento ZigZag
	var zigzag_offset = sin(time_passed * zigzag_frequency) * zigzag_amplitude
	global_position.x = start_x + zigzag_offset

	move_and_slide()

	# Colisión con el jugador
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage()
			take_damage() # Inicia secuencia de muerte

	shoot()

	if global_position.y > screen_size.y + 100:
		queue_free()

func shoot():
	if not can_shoot or bullet_scene == null or is_dying:
		return

	can_shoot = false
	var bullet = bullet_scene.instantiate()
	# Añadir al nivel, no al enemigo, para que la bala no siga el zigzag
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, 25)

	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

# ===============================
# MUERTE (CORREGIDA)
# ===============================
func take_damage(_damage: int = 1): # Aceptamos el argumento de la bala
	if is_dying:
		return
	
	is_dying = true
	
	# 1. Detener todo
	velocity = Vector2.ZERO
	# Importante: Desactivamos el proceso de físicas para que el zigzag se detenga
	set_physics_process(false) 
	
	# 2. Desactivar colisiones (evita múltiples impactos)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# 3. Animación de destrucción
	if animated_sprite.sprite_frames.has_animation("explosion"):
		animated_sprite.play("explosion")
		# Esperar a que los frames de explosión terminen
		await animated_sprite.animation_finished
	else:
		print("Error: Sin animación 'explosion'")
		await get_tree().process_frame

	# 4. Eliminar el nodo
	queue_free()
