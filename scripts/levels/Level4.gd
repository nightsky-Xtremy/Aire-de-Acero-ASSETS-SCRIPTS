extends Node2D

@export_file("*.tscn") var siguiente_nivel: String = "res://scenes/cinematics/Interludio5.tscn"
@onready var status_label = find_child("StatusLabel", true, false) as Label

func _ready():
	
	var spawner = find_child("EnemySpawnerLv4", true, false)
	
	if spawner:
		
		if not spawner.nivel_completado_boss.is_connected(_on_victoria_boss):
			spawner.nivel_completado_boss.connect(_on_victoria_boss)
		print("✅ Conexión establecida con SpawnerLv4")
	else:
		push_error("❌ ERROR: No se encontró el nodo EnemySpawnerLv4")
	
	if status_label:
		status_label.hide()


func _on_victoria_boss():

	if not is_player_alive():
		return

	print("🏆 Señal de victoria recibida. Iniciando transición...")
	
	await get_tree().create_timer(1.5).timeout
	
	if status_label:
		status_label.text = "¡JEFE DERROTADO!"
		status_label.show()
	

	await get_tree().create_timer(4.0).timeout
	

	if is_player_alive():
		_cambiar_a_nivel_5()

func is_player_alive() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and not player.is_queued_for_deletion():
		if "is_dead" in player:
			return not player.is_dead
		return true
	return false

func _cambiar_a_nivel_5():
	
	if siguiente_nivel == "":
		push_error("❌ Error: Ruta de nivel vacía en el Inspector de Level 4")
		return
		

	if not ResourceLoader.exists(siguiente_nivel):
		push_error("❌ Error: No se encuentra la escena en el paquete: " + siguiente_nivel)
		return
		
	print("🚀 Cargando Interludio 5...")
	var error = get_tree().change_scene_to_file(siguiente_nivel)
	
	if error != OK:
		push_error("❌ Error al cambiar de escena. Código: " + str(error))
