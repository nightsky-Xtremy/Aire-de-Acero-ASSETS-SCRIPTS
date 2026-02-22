extends CharacterBody2D

# ==================================================
# CONFIGURACIÓN DEL JEFE FINAL
# ==================================================
@export_group("Estadísticas")
@export var max_health: int = 100
@export var speed_hunter: float = 200.0     # Velocidad mientras te persigue
@export var speed_dash_initial: float = 600.0 # Velocidad inicial del ataque Kamikaze
@export var dash_acceleration: float = 800.0 # Aceleración durante el dash

@export_group("Combate")
@export var enemy_bullet_scene: PackedScene
@export var fire_rate: float = 1.8
@export var burst_count: int = 5
@export var burst_delay: float = 0.1

# ==================================================
# VARIABLES DE ESTADO
# ==================================================
enum { PERSECUCION, PREPARANDO_DASH, DASH_KAMIKAZE, MUERTO }
var estado_actual = PERSECUCION

var health: int
var player: Node2D = null
var is_dying: bool = false
var velocity_dash: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")
	add_to_group("boss")
	health = max_health
	_find_player()
	
	# Iniciar el ciclo de combate
	_ciclo_de_ataque()

func _find_player():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if is_dying:
		_handle_death_animation(delta)
		return

	match estado_actual:
		PERSECUCION:
			_logica_persecucion(delta)
		PREPARANDO_DASH:
			_logica_preparacion(delta)
		DASH_KAMIKAZE:
			_logica_embestida(delta)

	check_player_collision()

# ==================================================
# LÓGICA DE MOVIMIENTO ( HUNTER + KAMIKAZE )
# ==================================================

@warning_ignore("unused_parameter")
func _logica_persecucion(delta):
	if is_instance_valid(player):
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed_hunter
		# Rotación suave hacia el jugador
		var target_angle = direction.angle() + deg_to_rad(90)
		rotation = lerp_angle(rotation, target_angle, 0.1)
	move_and_slide()

@warning_ignore("unused_parameter")
func _logica_preparacion(delta):
	# Frenado y vibración (Efecto Kamikaze)
	velocity = velocity.lerp(Vector2.ZERO, 0.1)
	move_and_slide()
	# Seguir apuntando ligeramente antes de salir disparado
	if is_instance_valid(player):
		var target_angle = (player.global_position - global_position).angle() + deg_to_rad(90)
		rotation = lerp_angle(rotation, target_angle, 0.2)

func _logica_embestida(delta):
	# Movimiento lineal acelerado
	velocity_dash += dash_acceleration * delta
	velocity = dash_direction * velocity_dash
	move_and_slide()

# ==================================================
# INTELIGENCIA DE COMBATE
# ==================================================

func _ciclo_de_ataque():
	while not is_dying:
		# 1. FASE HUNTER: Persigue y dispara ráfagas
		estado_actual = PERSECUCION
		for r in range(3): # Realiza 3 ráfagas antes de cambiar a dash
			if is_dying: return
			await _disparar_rafaga()
			await get_tree().create_timer(fire_rate).timeout
		
		# 2. FASE KAMIKAZE: Carga y embiste
		if is_dying: return
		await _preparar_y_embestir()

func _disparar_rafaga():
	for i in range(burst_count):
		if is_dying or !is_instance_valid(player): break
		_fire_bullet()
		await get_tree().create_timer(burst_delay).timeout

func _fire_bullet():
	if !enemy_bullet_scene: return
	var bullet = enemy_bullet_scene.instantiate()
	get_parent().add_child(bullet)
	
	bullet.global_position = global_position + Vector2(0, 40).rotated(rotation)
	if bullet.has_method("set_direction"):
		var shoot_dir = (player.global_position - global_position).normalized()
		bullet.set_direction(shoot_dir)

func _preparar_y_embestir():
	estado_actual = PREPARANDO_DASH
	
	# Efecto visual de carga
	var tween = create_tween().set_loops(4)
	tween.tween_property(animated_sprite, "modulate", Color(5, 0, 0), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
	
	# Vibración física
	var pos_tween = create_tween().set_loops(10)
	pos_tween.tween_property(animated_sprite, "position", Vector2(4, 0), 0.04)
	pos_tween.tween_property(animated_sprite, "position", Vector2(-4, 0), 0.04)
	
	await get_tree().create_timer(0.8).timeout
	
	# Fijar dirección y salir disparado
	if is_instance_valid(player):
		dash_direction = (player.global_position - global_position).normalized()
	else:
		dash_direction = Vector2.DOWN
		
	velocity_dash = speed_dash_initial
	estado_actual = DASH_KAMIKAZE
	animated_sprite.position = Vector2.ZERO
	
	# Duración del dash
	await get_tree().create_timer(1.2).timeout
	
	# Volver a persecución
	if not is_dying:
		estado_actual = PERSECUCION

# ==================================================
# DAÑO Y MUERTE
# ==================================================

func take_damage(damage: int = 1):
	if is_dying: return
	health -= damage
	_flash_effect()
	if health <= 0:
		_start_death()

func _flash_effect():
	modulate = Color(15, 15, 15)
	await get_tree().create_timer(0.06).timeout
	modulate = Color.WHITE

func check_player_collision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage()
			# Si el jefe está en modo DASH, el choque es más peligroso o letal
			if estado_actual == DASH_KAMIKAZE:
				print("¡Impacto sónico del SK-X!")

func _start_death():
	is_dying = true
	estado_actual = MUERTO
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	
	# Notificar al spawner para terminar el juego
	var spawner = get_tree().get_first_node_in_group("spawner")
	if spawner and spawner.has_method("_on_boss_muerto"):
		spawner._on_boss_muerto()

	if animated_sprite.sprite_frames.has_animation("explosion"):
		animated_sprite.play("explosion")

func _handle_death_animation(delta):
	global_position.y += 150 * delta
	animated_sprite.scale -= Vector2.ONE * 0.8 * delta
	if animated_sprite.scale.x <= 0.01:
		queue_free()
