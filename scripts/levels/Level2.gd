extends Node2D

@export_file("*.tscn") var siguiente_nivel: String = "res://scenes/cinematics/Interludio3.tscn"
@onready var status_label = $CanvasLayer/StatusLabel 

func _ready():
	
	var spawner = get_node_or_null("EnemySpawner")
	if spawner:
		
		if not spawner.spawn_finalizado.is_connected(_on_horda_terminada):
			spawner.spawn_finalizado.connect(_on_horda_terminada)
	
	if status_label:
		status_label.hide()

func _on_horda_terminada():
	
	if not is_player_alive():
		return

	
	await get_tree().create_timer(3.0).timeout
	
	
	if not is_player_alive():
		return
	
	if status_label:
		status_label.text = "¡MISIÓN CUMPLIDA!"
		status_label.show()
	
	
	await get_tree().create_timer(3.0).timeout
	
	if is_player_alive():
		_cambiar_a_nivel_3()


func is_player_alive() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and not player.is_queued_for_deletion():
		if "is_dead" in player:
			return not player.is_dead
		return true
	return false

func _cambiar_a_nivel_3():
	
	if siguiente_nivel == "":
		push_error("❌ Error: La ruta del siguiente nivel está vacía en Level 2.")
		return
		
	
	if not ResourceLoader.exists(siguiente_nivel):
		push_error("❌ Error: No se encuentra la escena: " + siguiente_nivel)
		return
		
	print("🚀 Cargando Interludio 3...")
	var error = get_tree().change_scene_to_file(siguiente_nivel)
	
	if error != OK:
		push_error("❌ Error al cambiar de escena: " + str(error))
