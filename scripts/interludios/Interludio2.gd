extends Control

# --- CONFIGURACIÓN ---
@export_group("Contenido")
@export var imagen_escena: Texture2D
@export_multiline var texto_historia: String = "Halcon 4 reabasteciendo combustible. Nos acercamos al desierto de Guajera. Bien Halcon 7, demuestre porque fue escogido"
@export_file("*.tscn") var siguiente_nivel: String = "res://scenes/levels/Level2.tscn"

@export_group("Tiempos")
@export var velocidad_escritura: float = 0.05
@export var tiempo_espera_final: float = 2.0

# --- NODOS ---
@onready var texture_rect = $TextureRect
@onready var label_texto = $Label
# Control de flujo para evitar errores al exportar
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
		# Si el usuario salta la escena, detenemos el bucle inmediatamente
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
	# Saltar interludio con Enter/Espacio/Click
	if event.is_action_pressed("ui_accept") and not cambiando_escena:
		_cambiar_escena()

func _cambiar_escena():
	# Bloqueo de seguridad
	cambiando_escena = true
	
	# 5. Fundido a negro antes de salir (Fade Out)
	var tween_out = create_tween()
	tween_out.tween_property(self, "modulate:a", 0, 1.0)
	await tween_out.finished
	
	# Verificación compatible con el ejecutable .exe (Embed PCK)
	if siguiente_nivel != "" and ResourceLoader.exists(siguiente_nivel):
		print("🚀 Saliendo de Interludio 2 hacia: ", siguiente_nivel)
		get_tree().change_scene_to_file(siguiente_nivel)
	else:
		push_error("❌ ERROR: No se encontró la escena destino en Interludio 2: " + siguiente_nivel)
