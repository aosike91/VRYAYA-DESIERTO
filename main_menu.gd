extends Node3D

@onready var animacion: AnimationPlayer = $XROrigin3D/AnimationPlayer
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Conectar la señal finished del audio para cambiar de escena
	audio.finished.connect(_on_audio_finished)
	
	animacion.play("caminata")
	audio.play()

# Función que se ejecuta cuando termina el audio
func _on_audio_finished() -> void:
	# Cambiar a la escena node_3d.tscn
	get_tree().change_scene_to_file("res://node_3d.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
