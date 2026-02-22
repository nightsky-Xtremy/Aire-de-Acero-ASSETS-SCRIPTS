extends Control

# Referencias a los botones
var boton_comenzar: Button
var boton_historia: Button
var boton_consejo: Button
var boton_salir: Button

# Rutas de las escenas con @export para poder editarlas desde el Inspector
@export_group("Configuración de Rutas")
@export_file("*.tscn") var escena_mision_1: String = "res://scenes/cinematics/Interludio1.tscn"
@export_file("*.tscn") var escena_consejo: String = "res://scenes/ui/Consejos.tscn"

func _ready():
	# Configuración inicial del estado del juego
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	
	# Localización de nodos (botones)
	boton_comenzar = find_child("Comenzar", true, false) as Button
	
	# Lógica especial para buscar "Consejos" o "Consejo"
	boton_consejo = find_child("Consejos", true, false) as Button
	if not boton_consejo:
		boton_consejo = find_child("Consejo", true, false) as Button
		
	boton_salir = find_child("Salir", true, false) as Button
	
	# Conexiones de señales con verificación de existencia
	if boton_comenzar:
		boton_comenzar.pressed.connect(_on_comenzar_pressed)
		
	if boton_consejo: 
		boton_consejo.pressed.connect(_on_consejo_pressed)
		print("✅ Botón de Consejos conectado correctamente.")
	else:
		push_warning("⚠️ Advertencia: No se encontró el botón de Consejos/Consejo.")
		
	if boton_salir:
		boton_salir.pressed.connect(_on_salir_pressed)

# --- LÓGICA DE LOS BOTONES ---

func _on_comenzar_pressed() -> void:
	_cambiar_escena(escena_mision_1, "Misión 1")

func _on_consejo_pressed() -> void:
	print("🖱️ Clic en Consejos detectado.")
	_cambiar_escena(escena_consejo, "Consejos")

func _on_salir_pressed() -> void:
	print("🚪 Saliendo del juego...")
	get_tree().quit()

# --- FUNCIÓN NÚCLEO DE CAMBIO DE ESCENA ---

func _cambiar_escena(ruta: String, nombre_escena: String) -> void:
	# 1. Validar que la ruta no esté vacía
	if ruta == "":
		push_error("❌ ERROR: La ruta para '" + nombre_escena + "' está vacía en el Inspector.")
		return
		
	# 2. VALIDACIÓN CRÍTICA PARA EXPORTACIÓN:
	# Usamos ResourceLoader.exists en lugar de FileAccess porque los archivos .tscn 
	# se convierten en recursos binarios dentro del .pck al exportar.
	if not ResourceLoader.exists(ruta):
		push_error("❌ ERROR: No se puede encontrar la escena en: " + ruta + 
		". Verifica que el nombre sea idéntico (mayúsculas/minúsculas).")
		return
		
	print("🚀 Cargando: ", nombre_escena, " (", ruta, ")")
	
	# 3. Intentar el cambio de escena
	var resultado = get_tree().change_scene_to_file(ruta)
	
	# 4. Verificar si hubo un error interno al cargar
	if resultado != OK:
		push_error("❌ ERROR FATAL al intentar cargar la escena. Código de error: ", resultado)
