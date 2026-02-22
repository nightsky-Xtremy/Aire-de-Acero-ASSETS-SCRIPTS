extends Control

@export_file("*.tscn") var ruta_menu: String = "res://scenes/ui/MainMenu.tscn"

func _ready():
	# Conectamos la señal que avisa cuando el video termina
	$VideoStreamPlayer.finished.connect(_on_video_finished)

func _on_video_finished():
	# Cuando el video de Canva termina, vamos al menú
	get_tree().change_scene_to_file(ruta_menu)

func _input(event):
	# Opcional: Permitir que el jugador se salte el video con cualquier tecla
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			_on_video_finished()
