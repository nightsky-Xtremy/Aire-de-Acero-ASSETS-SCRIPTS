extends CharacterBody2D

# ==================================================
# CONFIGURACIÓN
# ==================================================
@export_group("Movimiento")
@export var scroll_speed: float = 150.0 

@export_group("Combate")
@export var bullet_scene: PackedScene = preload("res://scenes/bullets/EnemyBullet.tscn")
@export var fire_rate: float = 1.5
@export var health: int = 6 

# ==================================================
# NODOS
# ==================================================
@onready var anim_sprite = $AnimatedSprite2D
@onready var shoot_timer = $ShootTimer
# Referenciamos ambos puntos de disparo
@onready var shoot_point = $ShootPoint
@onready var shoot_point_2 = $ShootPoint2

# ==================================================
# VARIABLES DE ESTADO
# ==================================================
var esta_muerto: bool = false

func _ready():
	# IMPORTANTE: Añadir al grupo para el Spawner del Nivel 3
	add_to_group("enemy")
	add_to_group("enemy_ship") # Para que el Spawner sepa que hay un barco activo
	
	anim_sprite.play("default")
	
	shoot_timer.wait_time = fire_rate
	shoot_timer.one_shot = false
	shoot_timer.start()
	
	if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	if not anim_sprite.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		anim_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func _physics_process(_delta):
	velocity.y = scroll_speed
	velocity.x = 0
	move_and_slide()
	
	if global_position.y > get_viewport_rect().size.y + 150:
		queue_free()

func _on_shoot_timer_timeout():
	if not esta_muerto:
		disparar()

# ==================================================
# LÓGICA DE DISPARO DOBLE
# ==================================================
func disparar():
	if bullet_scene == null: 
		return
	
	# Creamos una lista con los puntos de disparo para iterar
	var puntos = [shoot_point, shoot_point_2]
	
	for p in puntos:
		if p: # Verificamos que el nodo exista
			var bullet = bullet_scene.instantiate()
			get_tree().current_scene.add_child(bullet)
			bullet.global_position = p.global_position

# ==================================================
# SISTEMA DE DAÑO Y MUERTE
# ==================================================
func take_damage(amount: int = 1):
	if esta_muerto: 
		return
	
	health -= amount
	flash_effect()
	
	if health <= 0:
		die()

func flash_effect():
	modulate = Color(10, 10, 10) 
	await get_tree().create_timer(0.05).timeout
	modulate = Color(1, 1, 1) 

func die():
	if esta_muerto: 
		return 
	esta_muerto = true
	
	shoot_timer.stop()
	
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	if anim_sprite.sprite_frames.has_animation("destruido"):
		anim_sprite.play("destruido")
	else:
		queue_free()
		
	print("Nave Enemiga destruida!")

func _on_animated_sprite_2d_animation_finished():
	if anim_sprite.animation == "destruido":
		queue_free()
