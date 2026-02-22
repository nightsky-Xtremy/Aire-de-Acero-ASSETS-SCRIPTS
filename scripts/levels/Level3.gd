extends Node2D

@export_file("*.tscn") var siguiente_nivel: String = "res://scenes/cinematics/Interludio4.tscn"


@onready var status_label = find_child("StatusLabel", true, false) as Label

func _ready():
	
	var spawner = get_node_or_null("EnemySpawner")
	if spawner:
		if not spawner.spawn_finalizado.is_connected(_on_horda_terminada):
			spawner.spawn_finalizado.connect(_on_horda_terminada)
	else:
		push_warning("Advertencia: No se encontró EnemySpawner en Level3")
	
	
	if status_label:
		status_label.hide()
	else:
		push_warning("Advertencia: No se encontró StatusLabel en Level3")

func _on_horda_terminada():
	
	if not is_player_alive():
		return

	
	await get_tree().create_timer(3.0).timeout
	
	if status_label:
		status_label.text = "¡MISIÓN CUMPLIDA!"
		status_label.show()
	
	
	await get_tree().create_timer(4.0).timeout
	
	_cambiar_a_nivel_4()


func is_player_alive() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and not player.is_queued_for_deletion():
		if "is_dead" in player:
			return not player.is_dead
		return true
	return false

func _cambiar_a_nivel_4():
	
	if siguiente_nivel == "":
		push_error("❌ Error: La ruta del siguiente nivel está vacía en Level3.")
		return
		
	
	if not ResourceLoader.exists(siguiente_nivel):
		push_error("❌ Error: No se puede encontrar la escena en el paquete: " + siguiente_nivel)
		return
		
	print("🚀 Cargando Interludio 4...")
	var error = get_tree().change_scene_to_file(siguiente_nivel)
	
	if error != OK:
		push_error("❌ Error al cambiar de escena. Código: " + str(error))
