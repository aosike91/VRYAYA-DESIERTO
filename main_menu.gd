extends Node3D

@onready var animacion: AnimationPlayer = $XROrigin3D/XRCamera3D/AnimationPlayer
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

# Variables para controlar la carga
var is_loading = false
var scene_loaded = false
var target_scene_path = "res://node_3d.tscn"

func _ready() -> void:
	# Configurar viewport
	get_viewport().msaa_3d = Viewport.MSAA_4X
	
	# Conectar señales
	audio.finished.connect(_on_audio_finished)
	
	# Iniciar carga de la escena en segundo plano
	start_loading()
	
	# Esperar 3 segundos antes de iniciar animación y audio
	await get_tree().create_timer(3.0).timeout
	
	# Iniciar animación y audio después de la espera
	animacion.play("caminata")
	audio.play()

func start_loading() -> void:
	if not is_loading:
		is_loading = true
		# Cargar la escena en segundo plano
		ResourceLoader.load_threaded_request(target_scene_path)

func _process(delta: float) -> void:
	# Verificar el progreso de carga
	if is_loading and not scene_loaded:
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
		
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				scene_loaded = true
				print("Escena cargada completamente")
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				# Opcional: mostrar progreso de carga
				var load_progress = progress[0] if progress.size() > 0 else 0.0
				print("Progreso de carga: ", load_progress * 100, "%")
			ResourceLoader.THREAD_LOAD_FAILED:
				print("Error al cargar la escena")
				is_loading = false

func _on_audio_finished() -> void:
	# Esperar a que la escena esté completamente cargada
	if scene_loaded:
		change_to_loaded_scene()
	else:
		# Si no está cargada, esperar hasta que lo esté
		print("Esperando a que termine la carga...")
		await_scene_load()

func await_scene_load() -> void:
	# Esperar hasta que la escena esté cargada
	while not scene_loaded and is_loading:
		await get_tree().process_frame
	
	if scene_loaded:
		change_to_loaded_scene()

func change_to_loaded_scene() -> void:
	# Obtener la escena cargada
	var loaded_scene = ResourceLoader.load_threaded_get(target_scene_path)
	
	if loaded_scene:
		# Cambiar a la escena cargada
		get_tree().change_scene_to_packed(loaded_scene)
	else:
		# Fallback: cargar de forma síncrona
		print("Carga asíncrona falló, cargando de forma síncrona...")
		get_tree().change_scene_to_file(target_scene_path)
