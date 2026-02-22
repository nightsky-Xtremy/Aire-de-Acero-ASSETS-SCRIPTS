extends Node2D

@export_group("Rutas de Escena")
@export_file("*.tscn") var escena_final: String = "res://scenes/cinematics/InterludioFinal.tscn"

@onready var status_label = find_child("StatusLabel", true, false) as Label

func _ready():
	if status_label:
		status_label.hide()
	call_deferred("_conectar_spawner_seguro")

func _conectar_spawner_seguro():
	# Si al llamar diferido ya no estamos en el árbol, abortar
	if not is_inside_tree(): return
	
	var tree = get_tree()
	if not tree: return

	var spawner = tree.get_first_node_in_group("spawner")
	if is_instance_valid(spawner):
		if spawner.has_signal("nivel_completado_boss"):
			if not spawner.nivel_completado_boss.is_connected(_on_victoria_final):
				spawner.nivel_completado_boss.connect(_on_victoria_final)
				print("✅ Level6: Conectado")

func _on_victoria_final():
	# REGLA DE ORO: Siempre verificar después de cada 'await'
	if not _validar_estado_mundo(): return

	print("🏆 ¡EL BOSS AS (SK-X) HA CAÍDO!")
	
	Engine.time_scale = 0.5 
	
	# El timer debe ser del árbol actual
	var timer = get_tree().create_timer(2.0)
	await timer.timeout
	
	# --- SEGUNDA VERIFICACIÓN POST-AWAIT ---
	if not _validar_estado_mundo(): 
		Engine.time_scale = 1.0 # Reset por si acaso
		return
		
	Engine.time_scale = 1.0
	
	if is_instance_valid(status_label):
		status_label.text = "¡SK-X DESTRUIDO: LA LEYENDA HA TERMINADO!"
		status_label.show()
	
	# Otro await largo, otra verificación necesaria
	await get_tree().create_timer(5.0).timeout
	
	if _validar_estado_mundo() and is_player_alive():
		_terminar_juego()

# Función centralizada de seguridad para evitar repetición
func _validar_estado_mundo() -> bool:
	return is_inside_tree() and get_tree() != null

func is_player_alive() -> bool:
	if not _validar_estado_mundo(): return false
	
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.is_inside_tree():
		if "is_dead" in player:
			return not player.is_dead
		return true
	return false

func _terminar_juego():
	if not _validar_estado_mundo(): return
	
	if escena_final == "" or not ResourceLoader.exists(escena_final):
		push_error("❌ Error: Ruta inválida")
		return
		
	get_tree().change_scene_to_file(escena_final)
