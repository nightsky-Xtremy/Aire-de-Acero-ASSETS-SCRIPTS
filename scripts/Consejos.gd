extends Node2D

# Usamos @export_file para que puedas elegir el archivo desde la carpetita en el Inspector
@export_file("*.tscn") var ruta_menu: String = "res://scenes/ui/MainMenu.tscn"

func _ready():
	# 1. Aseguramos que el mouse funcione
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# 2. Buscamos el botón "Menu" sin importar dónde esté escondido
	var btn = find_child("Menu", true, false)
	
	if btn:
		# Si ya tenía una conexión, la limpiamos para evitar conflictos
		if btn.pressed.is_connected(_on_menu_pressed):
			btn.pressed.disconnect(_on_menu_pressed)
		
		# Conectamos la señal
		btn.pressed.connect(_on_menu_pressed)
		print("✅ ÉXITO: Botón 'Menu' encontrado y conectado.")
	else:
		push_error("❌ ERROR: No existe ningún nodo llamado 'Menu' en esta escena.")

func _on_menu_pressed():
	print("🚀 Botón presionado. Intentando cargar: ", ruta_menu)
	
	if ruta_menu == "":
		push_error("❌ ERROR: No has seleccionado la ruta del menú en el Inspector.")
		return
		
	var error = get_tree().change_scene_to_file(ruta_menu)
	
	if error != OK:
		push_error("❌ ERROR de Godot al cargar la escena: " + str(error))
