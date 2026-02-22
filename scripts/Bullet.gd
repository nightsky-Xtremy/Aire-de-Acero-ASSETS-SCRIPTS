extends Area2D

@export var speed: float = 600.0
@export var damage: int = 1

func _ready():
	# Forzamos la conexión por código para estar 100% seguros
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position.y -= speed * delta
	
	if position.y < -100:
		queue_free()

# Esta es la ÚNICA función que necesitas si todos son CharacterBody2D
func _on_body_entered(body: Node2D) -> void:
	# Debug para ver en consola con qué choca
	print("Bala impactó con: ", body.name)
	
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free() # Eliminar bala tras impacto
