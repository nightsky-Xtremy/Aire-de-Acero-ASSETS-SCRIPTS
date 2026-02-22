extends CharacterBody2D

# ==================================================
# CONFIGURACIÓN
# ==================================================
@export_group("Movimiento")
@export var scroll_speed: float = 150.0 

@export_group("Combate")
@export var bullet_scene: PackedScene = preload("res://scenes/bullets/EnemyBullet.tscn")
@export var fire_rate: float = 2.5
@export var health: int = 2 

# ==================================================
# NODOS
# ==================================================
@onready var anim_sprite = $AnimatedSprite2D
@onready var shoot_timer = $ShootTimer
@onready var shoot_point = $ShootPoint

# ==================================================
# VARIABLES DE ESTADO
# ==================================================
var esta_muerto: bool = false

func _ready():
	# Añadir al grupo para que las balas del jugador lo detecten
	add_to_group("enemy")
	anim_sprite.play("default")
	
	# Configuración del temporizador de disparo
	shoot_timer.wait_time = fire_rate
	shoot_timer.one_shot = false
	shoot_timer.start()
	
	# Conexión de señales por código (por si no están en el editor)
	if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	if not anim_sprite.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		anim_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _physics_process(_delta):
	# El tanque siempre se mueve hacia abajo (efecto scroll)
	velocity.y = scroll_speed
	velocity.x = 0
	move_and_slide()
	
	# --- AUTODESTRUCCIÓN ---
	# Si sale por el borde inferior de la pantalla (con margen de 150px)
	if global_position.y > get_viewport_rect().size.y + 150:
		queue_free()

func _on_shoot_timer_timeout():
	if not esta_muerto:
		disparar()

func disparar():
	if bullet_scene == null: 
		return
		
	var bullet = bullet_scene.instantiate()
	# Añadimos la bala a la escena principal para que no se mueva con el tanque
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = shoot_point.global_position

# ==================================================
# SISTEMA DE DAÑO Y PARPADEO
# ==================================================
func take_damage(amount: int = 1):
	if esta_muerto: 
		return
	
	health -= amount
	flash_effect()
	
	if health <= 0:
		die()

func flash_effect():
	# Efecto de brillo blanco intenso (HDR)
	modulate = Color(10, 10, 10) 
	await get_tree().create_timer(0.05).timeout
	# Retorno al color original del sprite
	modulate = Color(1, 1, 1) 

# ==================================================
# LÓGICA DE MUERTE
# ==================================================
func die():
	if esta_muerto: 
		return 
	esta_muerto = true
	
	# 1. Detener ataques
	shoot_timer.stop()
	
	# 2. Desactivar colisiones (usando set_deferred para evitar errores de física)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	# 3. Iniciar animación de explosión
	if anim_sprite.sprite_frames.has_animation("destruido"):
		anim_sprite.play("destruido")
	else:
		# Si no hay animación, lo borramos de inmediato
		queue_free()
		
	print("Tanque destruido!")

func _on_animated_sprite_2d_animation_finished():
	# El nodo se elimina solo cuando termina de explotar
	if anim_sprite.animation == "destruido":
		queue_free()
