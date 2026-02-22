extends Control

# --- CONFIGURACIÓN ---
@export_group("Contenido")
@export var imagen_escena: Texture2D
@export_multiline var texto_historia: String = "Hay varios puntos enemigos en la Bahia de New Kyon..."
@export_file("*.tscn") var siguiente_nivel: String = "res://scenes/levels/Level1.tscn"

@export_group("Tiempos")
@export var velocidad_escritura: float = 0.05
@export var tiempo_espera_final: float = 2.0

# --- NODOS ---
@onready var texture_rect = $TextureRect
@onready var label_texto = $Label
# Variable de control para evitar doble carga
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
		# Si ya empezamos a cambiar de escena (por skip), salimos del bucle
		if cambiando_escena: break
		
		label_texto.text += letra
		
		if Input.is_anything_pressed():
			await get_tree().create_timer(0.01).timeout
		else:
			await get_tree().create_timer(velocidad_escritura).timeout
	
	# 4. Espera antes de cambiar de nivel (solo si no se ha saltado ya)
	if not cambiando_escena:
		await get_tree().create_timer(tiempo_espera_final).timeout
		_cambiar_escena()

func _input(event):
	# Saltar interludio si se presiona "Enter" o "Espacio"
	if event.is_action_pressed("ui_accept") and not cambiando_escena:
		_cambiar_escena()

func _cambiar_escena():
	# Bloqueamos la función para que no se ejecute dos veces
	cambiando_escena = true
	
	# 5. Fundido a negro antes de salir (Fade Out)
	var tween_out = create_tween()
	tween_out.tween_property(self, "modulate:a", 0, 1.0)
	await tween_out.finished
	
	# VALIDACIÓN DE RUTA PARA EL EJECUTABLE (.exe)
	if siguiente_nivel != "" and ResourceLoader.exists(siguiente_nivel):
		get_tree().change_scene_to_file(siguiente_nivel)
	else:
		push_error("Error: No se encontró la escena: " + siguiente_nivel)
