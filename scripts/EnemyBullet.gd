extends Area2D

@export var speed: float = 500.0

@onready var shoot_sound_enemy = $ShootSoundEnemy

var screen_size: Vector2

func _ready():
	screen_size = get_viewport_rect().size
	body_entered.connect(_on_body_entered)
	
	# REFUERZO: Forzar el inicio del sonido
	if shoot_sound_enemy:
		shoot_sound_enemy.play()
	else:
		print("Error: No se encontró el nodo ShootSoundEnemy")

func _process(delta):
	position.y += speed * delta

	if position.y > screen_size.y + 50:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage()
		# Si hacemos queue_free() aquí, el sonido se corta de golpe.
		# Solo ocultamos la bala para que el sonido pueda terminar si es largo.
		hide()
		set_deferred("monitoring", false)
		# Esperamos un instante o borramos directamente si el sonido es corto
		queue_free()
