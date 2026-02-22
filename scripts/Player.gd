extends CharacterBody2D

# ===============================
# SEÑALES
# ===============================
signal player_died 

# ===============================
# CONFIGURACIÓN
# ===============================
@export var speed: float = 400.0
@export var fire_rate: float = 0.15
@export var entry_speed: float = 250.0

@export var bullet_scene: PackedScene = preload("res://scenes/bullets/Bullet.tscn")
@export var game_over_scene: PackedScene = preload("res://scenes/ui/GameOverScreen.tscn")

# ===============================
# VARIABLES
# ===============================
var screen_size: Vector2
var half_size: Vector2
var can_shoot: bool = false 
var is_dead: bool = false
var is_entering: bool = true
var target_position: Vector2

# ===============================
# NODOS
# ===============================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_point: Marker2D = $ShootPoint
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var engine_sound: AudioStreamPlayer2D = $EngineSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound

func _ready():
	add_to_group("player")
	screen_size = get_viewport_rect().size
	target_position = Vector2(screen_size.x / 2, screen_size.y - 120)
	global_position = Vector2(screen_size.x / 2, screen_size.y + 150)
	animated_sprite.play()
	engine_sound.play() 

	can_shoot = false
	Input.action_release("shoot")
	await get_tree().create_timer(0.2).timeout

	if animated_sprite.sprite_frames:
		var anim_name = animated_sprite.animation
		var texture = animated_sprite.sprite_frames.get_frame_texture(anim_name, 0)
		if texture:
			half_size = texture.get_size() * animated_sprite.scale / 2

func _physics_process(delta):
	if is_dead:
		return

	if is_entering:
		global_position.y -= entry_speed * delta
		if global_position.y <= target_position.y:
			global_position.y = target_position.y
			is_entering = false
			_activar_armas_tras_seguridad()
		return 

	handle_movement()
	handle_shooting()

func _activar_armas_tras_seguridad():
	await get_tree().create_timer(0.1).timeout
	if not is_dead:
		can_shoot = true

func handle_movement():
	var direction = Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = direction.normalized() * speed
	move_and_slide()
	clamp_to_screen()

	if velocity.length() > 0:
		if not engine_sound.playing: engine_sound.play()
	else:
		engine_sound.stop()

func clamp_to_screen():
	global_position.x = clamp(global_position.x, half_size.x, screen_size.x - half_size.x)
	global_position.y = clamp(global_position.y, half_size.y, screen_size.y - half_size.y)

func handle_shooting():
	if is_entering: return
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()

func shoot():
	if not can_shoot or is_entering or is_dead: return
	if bullet_scene == null: return

	can_shoot = false
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = shoot_point.global_position
	shoot_sound.stop()
	shoot_sound.play()

	await get_tree().create_timer(fire_rate).timeout
	if not is_dead:
		can_shoot = true

# ===============================
# DAÑO Y MUERTE (MODIFICADO)
# ===============================
func take_damage():
	if is_dead:
		return

	is_dead = true
	can_shoot = false 
	
	# --- PASO CLAVE PARA LOS ENEMYHUNTER ---
	# Quitamos al jugador del grupo inmediatamente para que los enemigos 
	# lo pierdan de vista mientras ocurre la animación de muerte.
	remove_from_group("player")
	
	emit_signal("player_died")
	
	velocity = Vector2.ZERO
	engine_sound.stop()
	
	# Desactivar colisiones físicas
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# Animación de explosión
	if animated_sprite.sprite_frames.has_animation("explosion"):
		animated_sprite.play("explosion")
	else:
		animated_sprite.hide()

	death_sound.play()

	# Esperar a que la explosión termine antes de borrar el nodo
	if animated_sprite.animation == "explosion":
		await animated_sprite.animation_finished
	
	if death_sound.playing:
		await death_sound.finished

	die()

func die():
	if game_over_scene:
		var game_over = game_over_scene.instantiate()
		get_tree().current_scene.add_child(game_over)
	
	queue_free()
