extends Control

# --- CONFIGURACIÓN ---
@export_group("Contenido")
@export var imagen_escena: Texture2D
@export_multiline var texto_historia: String = "No hemos ganado esta guerra, pero acabar con el hijo del General Pierce es un golpe fuerte en su ejercito"
@export_file("*.tscn") var siguiente_nivel: String = "res://scenes/ui/MainMenu.tscn"

@export_group("Tiempos")
@export var velocidad_escritura: float = 0.05
@export var tiempo_espera_final: float = 2.0

# --- NODOS ---
@onready var texture_rect = $TextureRect
@onready var label_texto = $Label
@onready var color_fondo = $ColorRect

# Control de flujo para evitar colisiones en el ejecutable .exe
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
		# Si se activó el salto de escena, detenemos el proceso
		if cambiando_escena: break
		
		label_texto.text += letra
		
		# Aceleración por input
		if Input.is_anything_pressed():
			await get_tree().create_timer(0.01).timeout
		else:
			await get_tree().create_timer(velocidad_escritura).timeout
	
	# 4. Espera antes de cambiar de nivel automáticamente
	if not cambiando_escena:
		await get_tree().create_timer(tiempo_espera_final).timeout
		_cambiar_escena()

func _input(event):
	# Captura de Enter/Espacio/Click
	if event.is_action_pressed("ui_accept") and not cambiando_escena:
		_cambiar_escena()

func _cambiar_escena():
	# Bloqueo inmediato para prevenir errores de carga
	cambiando_escena = true
	
	# 5. Fundido a negro antes de salir (Fade Out)
	var tween_out = create_tween()
	tween_out.tween_property(self, "modulate:a", 0, 1.0)
	await tween_out.finished
	
	# Validación de recurso para .exe con PCK embebido
	if siguiente_nivel != "" and ResourceLoader.exists(siguiente_nivel):
		print("🚀 ¡PELIGRO! Iniciando nivel del SK-X: ", siguiente_nivel)
		get_tree().change_scene_to_file(siguiente_nivel)
	else:
		push_error("❌ ERROR: No se encontró la escena del Level 6: " + siguiente_nivel)
