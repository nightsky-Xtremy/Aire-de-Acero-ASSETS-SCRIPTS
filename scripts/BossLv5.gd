extends CharacterBody2D

# --- CONFIGURACIÓN ---
@export_group("Estadísticas")
@export var salud_max: int = 120
@export var velocidad_patrulla: float = 180.0
@export var altura_vuelo: float = 200.0

@export_group("Ataque")
@export var bullet_scene: PackedScene
@export var cadencia_f1: float = 1.2
@export var cadencia_f2: float = 0.6

# --- VARIABLES DE ESTADO ---
var salud_actual: int
var fase_2: bool = false
var esta_muerto: bool = false
var direccion_x: int = 1

# --- NODOS ---
@onready var sprite = $AnimatedSprite2D
@onready var shoot_timer = $ShootTimer
var shoot_points: Array = []

func _ready():
	add_to_group("enemy")
	add_to_group("boss")
	
	salud_actual = salud_max
	sprite.play("default")
	
	# Búsqueda dinámica de puntos de disparo
	for i in range(1, 5):
		var p = find_child("ShootPoint" + str(i), true, false)
		if p: shoot_points.append(p)
	
	if shoot_timer:
		shoot_timer.timeout.connect(_on_disparo_timeout)
		shoot_timer.wait_time = cadencia_f1
		shoot_timer.start()
	
	global_position.y = -100 

func _physics_process(delta):
	if esta_muerto: return
	
	_logica_patrulla(delta)
	# IMPORTANTE: Llamamos a la colisión aquí
	_comprobar_colision_con_jugador()

func _logica_patrulla(delta):
	velocity.x = direccion_x * velocidad_patrulla
	global_position.y = lerp(global_position.y, altura_vuelo, 0.02)
	
	# Balanceo visual según dirección
	sprite.rotation = lerp_angle(sprite.rotation, deg_to_rad(direccion_x * 5), 0.1)
	
	move_and_slide()
	
	var viewport_x = get_viewport_rect().size.x
	if global_position.x > viewport_x - 120:
		direccion_x = -1
	elif global_position.x < 120:
		direccion_x = 1

func _comprobar_colision_con_jugador():
	# Verifica si el jefe choca físicamente con el jugador
	for i in get_slide_collision_count():
		var colision = get_slide_collision(i)
		var objeto = colision.get_collider()
		if is_instance_valid(objeto) and objeto.is_in_group("player"):
			if objeto.has_method("take_damage"):
				objeto.take_damage()

func _on_disparo_timeout():
	if esta_muerto: return
	_disparar_andana()

func _disparar_andana():
	for point in shoot_points:
		if is_instance_valid(point) and bullet_scene:
			var bullet = bullet_scene.instantiate()
			bullet.global_position = point.global_position
			if bullet.has_method("set_direction"):
				bullet.set_direction(Vector2.DOWN)
			get_tree().current_scene.add_child(bullet)
	
	if fase_2:
		_shake_efecto(0.2, 5.0)

func take_damage(amount: int = 1):
	if esta_muerto: return
	
	salud_actual -= amount
	_flash_daño()
	
	if salud_actual <= salud_max / 2 and not fase_2:
		_activar_fase_2()
	
	if salud_actual <= 0:
		_morir()

func _activar_fase_2():
	fase_2 = true
	velocidad_patrulla *= 1.4
	if shoot_timer:
		shoot_timer.wait_time = cadencia_f2
	
	var tween = create_tween()
	# Color rojizo y aumento de tamaño para intimidar
	tween.tween_property(sprite, "modulate", Color(1.5, 0.4, 0.4), 0.5) 
	tween.parallel().tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.5)

func _flash_daño():
	var color_original = Color(1.5, 0.4, 0.4) if fase_2 else Color(1, 1, 1)
	sprite.modulate = Color(3, 3, 3) 
	
	# Usamos un timer del árbol de forma segura
	await get_tree().create_timer(0.05).timeout
	
	if is_instance_valid(sprite):
		sprite.modulate = color_original

func _shake_efecto(duracion: float, intensidad: float):
	var original_pos = sprite.position
	var t = create_tween()
	for i in range(5):
		var offset = Vector2(randf_range(-intensidad, intensidad), randf_range(-intensidad, intensidad))
		t.tween_property(sprite, "position", original_pos + offset, duracion / 5)
	t.tween_property(sprite, "position", original_pos, 0.05)

func _morir():
	if esta_muerto: return
	esta_muerto = true
	
	set_physics_process(false)
	if is_instance_valid(shoot_timer):
		shoot_timer.stop()
	
	# Desactivar colisiones (Capa 0)
	collision_layer = 0
	collision_mask = 0
	
	if is_inside_tree():
		var spawner = get_tree().get_first_node_in_group("spawner")
		if is_instance_valid(spawner) and spawner.has_method("_on_boss_muerto"):
			spawner._on_boss_muerto()
	
	# Animación de muerte con Tweens
	var tw = create_tween().set_parallel(true)
	tw.tween_property(sprite, "modulate:a", 0.0, 1.2)
	tw.tween_property(self, "global_position:y", global_position.y + 400, 1.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "rotation", deg_to_rad(180 * direccion_x), 1.5)
	
	await tw.finished
	queue_free()
