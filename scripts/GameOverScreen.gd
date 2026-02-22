extends CanvasLayer

@export_file("*.tscn") var ruta_mision_1: String = "res://scenes/cinematics/Interludio1.tscn"
@export_file("*.tscn") var ruta_menu_principal: String = "res://scenes/ui/MainMenu.tscn"

func _ready():
	# 1. FORZAR MODO SIEMPRE
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# 2. CONEXIÓN SEGURA
	_conectar_boton("Menu", _on_menu_pressed)
	_conectar_boton("Reintentar", _on_reintentar_pressed)

func _conectar_boton(nombre_nodo: String, metodo: Callable):
	var btn = find_child(nombre_nodo, true, false)
	if btn:
		if not btn.pressed.is_connected(metodo):
			btn.pressed.connect(metodo)
	else:
		push_error("ERROR: No se encontró el botón: " + nombre_nodo)

func _on_reintentar_pressed():
	_cambiar_escena(ruta_mision_1)

func _on_menu_pressed():
	_cambiar_escena(ruta_menu_principal)

# --- CORRECCIÓN AQUÍ: Agregamos '= ""' para que el argumento sea opcional ---
func _cambiar_escena(ruta: String = ""):
	# Si la ruta llega vacía (error de llamada), usamos el menú principal por defecto
	if ruta == "":
		print("⚠️ Advertencia: _cambiar_escena llamada sin ruta. Usando menú principal.")
		ruta = ruta_menu_principal
		
	if ruta == "": # Si aún sigue vacía porque no se asignó en el inspector
		push_error("ERROR: No hay ruta definida en el Inspector.")
		return

	# IMPORTANTE: Despausar antes de cambiar
	get_tree().paused = false
	
	# Verificamos que el SceneTree exista antes de intentar el cambio
	var tree = get_tree()
	if tree:
		var error = tree.change_scene_to_file(ruta)
		if error == OK:
			queue_free()
		else:
			push_error("Error al cargar escena: " + str(error))
