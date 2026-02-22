extends Node2D

@export_group("Rutas de Escena")
@export_file("*.tscn") var siguiente_nivel: String = "res://scenes/cinematics/Interludio6.tscn"

@onready var status_label = find_child("StatusLabel", true, false) as Label

func _ready():
	if status_label:
		status_label.hide()
	
	# Usamos call_deferred para conectar el spawner cuando el árbol esté estable
	call_deferred("_conectar_spawner")

func _conectar_spawner():
	# Verificación de seguridad: ¿Sigue el nodo en el árbol?
	if not is_inside_tree(): return
	
	var spawner = get_tree().get_first_node_in_group("spawner")
	
	if is_instance_valid(spawner):
		if spawner.has_signal("nivel_completado_boss"):
			if not spawner.nivel_completado_boss.is_connected(_on_victoria_boss):
				spawner.nivel_completado_boss.connect(_on_victoria_boss)
				print("✅ Level5: Conectado exitosamente al Spawner")
	else:
		# Intento por nombre si el grupo falla
		var spawner_nombre = find_child("EnemySpawnerLv5", true, false)
		if is_instance_valid(spawner_nombre):
			if not spawner_nombre.nivel_completado_boss.is_connected(_on_victoria_boss):
				spawner_nombre.nivel_completado_boss.connect(_on_victoria_boss)
				print("⚠️ Level5: Conectado por nombre")

func _on_victoria_boss():
	# Si estamos en GameOver o el árbol no existe, ignorar
	if not is_inside_tree() or get_tree() == null: return
	if not is_player_alive(): return

	print("🏆 Victoria confirmada en Nivel 5.")
	
	await get_tree().create_timer(1.5).timeout
	
	if is_instance_valid(status_label):
		status_label.text = "¡BOMBARDERO DESTRUIDO!"
		status_label.show()
	
	await get_tree().create_timer(4.0).timeout
	
	if is_player_alive():
		_cambiar_escena_seguro()

func is_player_alive() -> bool:
	# 1. Verificamos si el SceneTree existe para evitar el error "on a null value"
	var tree = get_tree()
	if tree == null: 
		return false
		
	# 2. Buscamos al jugador
	var player = tree.get_first_node_in_group("player")
	
	# 3. Verificaciones de validez
	if is_instance_valid(player) and player.is_inside_tree():
		if "is_dead" in player:
			return not player.is_dead
		return true
	return false

func _cambiar_escena_seguro():
	if not is_inside_tree() or get_tree() == null: return
	
	if siguiente_nivel == "" or not ResourceLoader.exists(siguiente_nivel):
		push_error("❌ Error: Ruta de escena inválida")
		return
		
	print("🚀 Cargando Interludio 6...")
	get_tree().change_scene_to_file(siguiente_nivel)
