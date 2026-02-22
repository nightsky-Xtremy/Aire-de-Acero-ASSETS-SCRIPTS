extends CharacterBody2D

# --- CONFIGURACIÓN ---
@export_group("Estadísticas")
@export var salud_max: int = 100
@export var velocidad_acecho: float = 150.0 
@export var velocidad_dash_f1: float = 1000.0 
@export var velocidad_dash_f2: float = 1400.0 

# --- VARIABLES DE ESTADO ---
enum { ACECHANDO, PREPARANDO, EMBESTIDA, REGRESANDO, MUERTO }
var estado_actual = ACECHANDO
var salud_actual: int
var fase_2: bool = false
var esta_muerto: bool = false
var direccion_embestida: Vector2

@onready var sprite = $AnimatedSprite2D
@onready var timer_fases = $TimerFases 
@onready var collision = $CollisionShape2D

func _ready():
	# CORRECCIÓN 1: Asegurar que sea visible y esté en el grupo correcto
	add_to_group("enemy")
	add_to_group("boss") # Útil para identificarlo
	salud_actual = salud_max
	
	# Si el spawner lo pone en -100, forzamos a que sea visible procesando el primer frame
	visible = true 
	sprite.play("default")
	
	timer_fases.timeout.connect(_on_timer_fases_timeout)
	anim_sprite_conexion()
	
	# Iniciamos el timer con un poco de tiempo para que baje primero
	timer_fases.start(3.0) 

func anim_sprite_conexion():
	if sprite.sprite_frames.has_signal("animation_finished"):
		sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	if esta_muerto: return

	match estado_actual:
		ACECHANDO:
			_movimiento_acecho(delta)
			_comprobar_colision_letal()
		EMBESTIDA:
			_logica_embestida(delta)
			_comprobar_colision_letal()
		REGRESANDO:
			_logica_regreso(delta)

func _comprobar_colision_letal():
	for i in get_slide_collision_count():
		var colision = get_slide_collision(i)
		var objeto = colision.get_collider()
		if objeto.is_in_group("player"):
			if objeto.has_method("take_damage"):
				objeto.take_damage() 
			elif objeto.has_method("die"):
				objeto.die()

func _movimiento_acecho(delta):
	var player = get_tree().get_first_node_in_group("player")
	# CORRECCIÓN 2: Movimiento más fluido para entrar a escena
	if player:
		var target_x = player.global_position.x
		global_position.x = lerp(global_position.x, target_x, 0.05)
	
	# Esto lo hace bajar desde el -100 donde lo pone el spawner hasta el 150 visible
	global_position.y = lerp(global_position.y, 150.0, 0.02)

func _iniciar_preparacion():
	if esta_muerto: return
	estado_actual = PREPARANDO
	timer_fases.stop()
	
	var tween = create_tween().set_loops(12)
	tween.tween_property(sprite, "position:x", 5.0, 0.04)
	tween.tween_property(sprite, "position:x", -5.0, 0.04)
	sprite.modulate = Color.RED
	
	await get_tree().create_timer(1.0).timeout
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		direccion_embestida = (player.global_position - global_position).normalized()
	else:
		direccion_embestida = Vector2.DOWN
	
	sprite.modulate = Color.WHITE if not fase_2 else Color(2, 0.5, 0.5)
	sprite.position.x = 0
	estado_actual = EMBESTIDA

func _logica_embestida(delta):
	var speed = velocidad_dash_f2 if fase_2 else velocidad_dash_f1
	velocity = direccion_embestida * speed
	move_and_slide()
	
	var margin = 400
	var viewport = get_viewport_rect().size
	# CORRECCIÓN 3: Si sale por arriba también debe regresar
	if global_position.y > viewport.y + margin or global_position.x > viewport.x + margin or global_position.x < -margin or global_position.y < -margin:
		_iniciar_regreso()

func _iniciar_regreso():
	estado_actual = REGRESANDO
	global_position.y = -250
	global_position.x = get_viewport_rect().size.x / 2

func _logica_regreso(delta):
	var destino = Vector2(get_viewport_rect().size.x / 2, 150)
	global_position = global_position.lerp(destino, 0.05)
	
	if global_position.distance_to(destino) < 30:
		estado_actual = ACECHANDO
		timer_fases.start(1.2 if fase_2 else 2.5)

func take_damage(amount: int = 1):
	if esta_muerto: return
	salud_actual -= amount
	_flash_daño()
	if salud_actual <= salud_max / 2 and not fase_2:
		fase_2 = true
		sprite.modulate = Color(2, 0.5, 0.5)
	if salud_actual <= 0:
		_morir()

func _flash_daño():
	var original_mod = sprite.modulate
	sprite.modulate = Color(10, 10, 10)
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = original_mod

func _morir():
	if esta_muerto: return
	esta_muerto = true
	
	# Detenemos todo movimiento y colisiones
	set_physics_process(false) 
	timer_fases.stop()
	collision.set_deferred("disabled", true)
	
	# Efecto de parpadeo simple
	var tween_muerte = create_tween()
	tween_muerte.tween_property(sprite, "modulate:a", 0, 0.8) # Se desvanece en 0.8 seg
	
	# Si tienes animación de destrucción, la ponemos
	if sprite.sprite_frames.has_animation("destruido"):
		sprite.play("destruido")
		# Esperamos a que termine la animación o máximo 1.5 segundos
		await sprite.animation_finished
	else:
		# Si no hay animación, esperamos al desvanecimiento del tween
		await tween_muerte.finished
	
	print("💀 Boss liberado de la memoria")
	queue_free() # AL FIN: Esto activa tree_exited y el Spawner lo detecta

func _on_timer_fases_timeout():
	if estado_actual == ACECHANDO:
		_iniciar_preparacion()

func _on_animation_finished():
	if sprite.animation == "destruido":
		queue_free()
