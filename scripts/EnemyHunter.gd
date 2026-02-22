extends CharacterBody2D

# ==================================================
# CONFIGURACIÓN
# ==================================================
@export var speed: float = 280.0
@export var max_health: int = 1
@export var death_fall_speed: float = 250.0
@export var shrink_speed: float = 2.0

# ==================================================
# VARIABLES DE ESTADO
# ==================================================
var health: int
var player: Node2D = null
var is_dying: bool = false
var last_move_direction: Vector2 = Vector2.DOWN # Dirección por defecto

# ==================================================
# NODOS
# ==================================================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")
	health = max_health
	_find_player()

func _find_player():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if is_dying:
		handle_death_animation(delta)
		return

	var move_direction: Vector2 = Vector2.DOWN

	# 1. LÓGICA DE SEGUIMIENTO
	if is_instance_valid(player) and player.is_inside_tree():
		move_direction = (player.global_position - global_position).normalized()
		last_move_direction = move_direction
		rotation = move_direction.angle() + deg_to_rad(90)
	else:
		# 2. LÓGICA DE ESCAPE
		move_direction = last_move_direction
		rotation = lerp_angle(rotation, move_direction.angle() + deg_to_rad(90), 0.05)
		
		if Engine.get_frames_drawn() % 60 == 0:
			_find_player()

	# Aplicar movimiento
	velocity = move_direction * speed
	move_and_slide()

	# --- AUTODESTRUCCIÓN ---
	var viewport_size = get_viewport_rect().size
	if global_position.y > viewport_size.y + 200 or \
	   global_position.x < -200 or \
	   global_position.x > viewport_size.x + 200:
		queue_free()

	check_player_collision()

func check_player_collision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage()
			start_death()

# ==================================================
# RECIBIR DAÑO
# ==================================================
func take_damage(damage: int = 1):
	if is_dying: return
	
	health -= damage
	flash_effect()

	if health <= 0:
		start_death()

func flash_effect():
	modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.05).timeout
	modulate = Color(1, 1, 1)

# ==================================================
# PROCESO DE MUERTE
# ==================================================
func start_death():
	if is_dying: return
	is_dying = true

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	velocity = Vector2.ZERO
	rotation = 0

	if animated_sprite.sprite_frames.has_animation("explosion"):
		animated_sprite.play("explosion")

func handle_death_animation(delta):
	global_position.y += death_fall_speed * delta
	animated_sprite.scale -= Vector2.ONE * shrink_speed * delta

	if animated_sprite.scale.x <= 0.01:
		queue_free()
		
	if animated_sprite.animation == "explosion" and not animated_sprite.is_playing():
		queue_free()
