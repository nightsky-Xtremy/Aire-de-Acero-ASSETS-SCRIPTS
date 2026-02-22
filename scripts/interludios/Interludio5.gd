extends Control

# --- CONFIGURACIÓN ---
@export_group("Contenido")
@export var imagen_escena: Texture2D
@export_multiline var texto_historia: String = "Inteligencia de Gestokya del Norte nos da informes sobre un bombardero a punto de despegar de una base oculta en las afuera de la ciudad de capital de Cryctia, Gestokya del Sur."
@export_file("*.tscn") var siguiente_nivel: String = "res://scenes/levels/Level5.tscn"

@export_group("Tiempos")
@export var velocidad_escritura: float = 0.05
@export var tiempo_espera_final: float = 2.0

# --- NODOS ---
@onready var texture_rect = $TextureRect
@onready var label_texto = $Label
# Variable de seguridad para evitar errores de carga en el ejecutable
var cambiando_escena: bool = false

func _ready():
	# 1. Preparación inicial
	label_texto.text = ""
	if imagen_escena:
		texture_rect.texture = imagen_escena
	
	# 2. Iniciar con pantalla en negro (Fade In)
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.5)
	
	await tween.finished
	_empezar_narracion()

func _empezar_narracion():
	# 3. Efecto Máquina de Escribir
	for letra in texto_historia:
		# Si el jugador salta, detenemos el proceso de escritura
		if cambiando_escena: break
		
		label_texto.text += letra
		
		if Input.is_anything_pressed():
			await get_tree().create_timer(0.01).timeout
		else:
			await get_tree().create_timer(velocidad_escritura).timeout
	
	# 4. Espera antes de cambiar de nivel automáticamente
	if not cambiando_escena:
		await get_tree().create_timer(tiempo_espera_final).timeout
		_cambiar_escena()

func _input(event):
	# Saltar con Enter, Espacio o botón configurado
	if event.is_action_pressed("ui_accept") and not cambiando_escena:
		_cambiar_escena()

func _cambiar_escena():
	# Bloqueo para evitar que se llame dos veces a la carga de escena
	cambiando_escena = true
	
	# 5. Fundido a negro antes de salir (Fade Out)
	var tween_out = create_tween()
	tween_out.tween_property(self, "modulate:a", 0, 1.0)
	await tween_out.finished
	
	# Validación final para el ejecutable con Embed PCK
	if siguiente_nivel != "" and ResourceLoader.exists(siguiente_nivel):
		print("🚀 Rumbo a la Capital: ", siguiente_nivel)
		get_tree().change_scene_to_file(siguiente_nivel)
	else:
		push_error("❌ ERROR: No se encontró la escena del Nivel 5: " + siguiente_nivel)
