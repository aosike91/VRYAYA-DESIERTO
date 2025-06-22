extends Node3D

@onready var audio1 = $Audio1  
@onready var audio2 = $Audio2
@onready var audiopregunta = $AudioPregunta
@onready var audiorespuesta1 = $AudioRespuesta1
@onready var audiorespuesta2 = $AudioRespuesta2
@onready var audiorespuesta3 = $AudioRespuesta3
@onready var audiorespuesta4 = $AudioRespuesta4
@onready var audiofinal = $AudioFinal
@onready var video_player = $SubViewport/VideoStreamPlayer  
@onready var botones = $Botones
@onready var animasau : AnimationPlayer = $XROrigin3D/XRCamera3D/Viewport2Din3D/AnimationPlayer	
@onready var audio : AudioStreamPlayer = $AudioStreamPlayer
@onready var control : Control = $XROrigin3D/XRCamera3D/Control
@onready var viewport2d  = $XROrigin3D/XRCamera3D/Viewport2Din3D
@onready var confettiaudio: AudioStreamPlayer = $AudioStreamPlayer
@onready var grass_node = $Node3D/Grass  # Referencia al nodo Grass
var videos = ["ERRORMENSAJE", "ERRORCODIGO", "ERROREMISOR","ERRORRECEPTOR"]  
var respuestas_correctas = ["Mensaje", "Código", "Emisor","Receptor"]  
var audios_respuesta = []
var indice_video_actual = 0
var esperando_respuesta = false
var respuestas_usuario = []
var xr_interface

func _ready():
	# CONFIGURACIÓN VR PARA MEJOR CALIDAD
	configurar_calidad_vr()
	
	# Inicializar array de audios de respuesta
	audios_respuesta = [audiorespuesta1, audiorespuesta2, audiorespuesta3, audiorespuesta4]
	
	# Deshabilitar el viewport inicialmente
	viewport2d.visible = false
	
	# Deshabilitar botones inicialmente
	deshabilitar_botones()
	
	iniciar_secuencia()

func configurar_calidad_vr():
	# Obtener la interfaz XR
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("Configurando calidad VR...")
		
		# Aumentar la resolución de renderizado (valores entre 1.0 y 2.0)
		# Empieza con 1.3, puedes ajustar según tu hardware
		xr_interface.render_target_size_multiplier = 1.3
		print("Render scale configurado a: ", xr_interface.render_target_size_multiplier)
		
		# Configurar el viewport principal
		var camera = $XROrigin3D/XRCamera3D
		if camera:
		# Reducir la distancia máxima de renderizado para mejorar rendimiento
			camera.far = 200.0  # Objetos más allá de 100 metros no se renderizan
		
		var main_viewport = get_viewport()
		if main_viewport:
			# Activar MSAA para mejor calidad
			main_viewport.msaa_3d = Viewport.MSAA_4X
			
			# Asegurar que el viewport se actualice siempre
			
			print("MSAA configurado a 4X")
		
		# CONFIGURACIÓN DE SOMBRAS DE ALTA CALIDAD
		configurar_sombras_alta_calidad()
		
		print("Configuración VR completada")
	else:
		print("⚠️ No se pudo encontrar la interfaz OpenXR")

func configurar_sombras_alta_calidad():
	print("🌑 Configurando sombras de alta calidad...")
	
	# Configurar el RenderingServer para mejores sombras
	var rendering_server = RenderingServer
	
	# Configurar la calidad de las sombras direccionales (sol)
	# SHADOW_QUALITY_HARD = sombras duras pero rápidas
	# SHADOW_QUALITY_SOFT_LOW = sombras suaves de baja calidad
	# SHADOW_QUALITY_SOFT_MEDIUM = sombras suaves de calidad media
	# SHADOW_QUALITY_SOFT_HIGH = sombras suaves de alta calidad
	rendering_server.directional_shadow_quality_set(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	
	# Configurar la calidad de las sombras positional (luces puntuales y spots)
	rendering_server.positional_shadow_quality_set(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	
	# Aumentar el tamaño del atlas de sombras direccionales (mayor resolución)
	# Valores posibles: 1024, 2048, 4096, 8192
	# Más alto = mejor calidad pero más costo de rendimiento
	rendering_server.directional_shadow_atlas_set_size(4096, true)  # true para 16-bit
	
	print("✅ Sombras configuradas:")
	print("  - Calidad direccional: SOFT_HIGH")
	print("  - Calidad posicional: SOFT_HIGH") 
	print("  - Atlas direccional: 4096x4096")
	
	# Configurar luces específicas si existen
	configurar_luces_escena()

func deshabilitar_botones():
	# Deshabilitar todos los botones de respuesta
	for boton in botones.get_children():
		boton.set_process_input(false)
		# Si tienen algún método específico para deshabilitarlos, úsalo aquí
		if boton.has_method("set_disabled"):
			boton.set_disabled(true)

func habilitar_botones():
	# Habilitar todos los botones de respuesta
	for boton in botones.get_children():
		boton.set_process_input(true)
		if boton.has_method("set_disabled"):
			boton.set_disabled(false)

# Nueva función para mostrar viewport y ocultar grass
func mostrar_viewport():
	viewport2d.visible = true
	if grass_node:
		grass_node.visible = false
		print("🌱 Grass ocultado")

# Nueva función para ocultar viewport y mostrar grass
func ocultar_viewport():
	viewport2d.visible = false
	if grass_node:
		grass_node.visible = true
		print("🌱 Grass mostrado")

func iniciar_secuencia():
	audio1.play()
	await audio1.finished  
	audio2.play()
	await audio2.finished  
	reproducir_video()

func reproducir_video():
	if indice_video_actual < videos.size():
		# Deshabilitar botones mientras se reproduce el video
		deshabilitar_botones()
		
		# Reproducir video
		video_player.stream = load("res://videos/" + videos[indice_video_actual] + ".ogv")  
		video_player.play()
		
		# Esperar a que termine el video
		await video_player.finished
		
		# Reproducir audio pregunta
		audiopregunta.play()
		await audiopregunta.finished
		
		# Ahora habilitar botones para responder
		habilitar_botones()
		esperando_respuesta = true
		
		# Timeout de 10 segundos para responder
		await get_tree().create_timer(10).timeout
		
		if esperando_respuesta:
			esperando_respuesta = false
			# Si no respondió, marcar como incorrecta
			respuestas_usuario.append(false)
			cambiar_video()

func verificar_respuesta(nodo_seleccionado):
	if esperando_respuesta:
		esperando_respuesta = false
		deshabilitar_botones()
		
		var es_correcta = (nodo_seleccionado.name == respuestas_correctas[indice_video_actual])
		respuestas_usuario.append(es_correcta)
		
		if es_correcta:
			print("✅ Respuesta correcta:", nodo_seleccionado.name)
			# Mostrar viewport y ocultar grass usando la nueva función
			mostrar_viewport()
			animasau.play("confetti")
			confettiaudio.play()
			
			await animasau.animation_finished
			# Ocultar viewport y mostrar grass usando la nueva función
			ocultar_viewport()
		else:
			print("❌ Respuesta incorrecta:", nodo_seleccionado.name)
		
		# Reproducir audio de respuesta correspondiente
		audios_respuesta[indice_video_actual].play()
		await audios_respuesta[indice_video_actual].finished
		
		cambiar_video()

func cambiar_video():
	indice_video_actual += 1
	if indice_video_actual < videos.size():
		reproducir_video()
	else:
		print("🏁 Fin de los videos")
		finalizar_quiz()

func finalizar_quiz():
	# Reproducir audio final
	audiofinal.play()
	await audiofinal.finished
	
	# Aquí puedes agregar lógica adicional para el final del quiz
	print("Quiz completado")
	# Por ejemplo, cambiar de escena:
	# get_tree().change_scene_to_file("res://siguiente_escena.tscn")

func configurar_luces_escena():
	print("💡 Configurando luces de la escena...")
	
	# Buscar todas las luces direccionales (como el sol)
	var luces_direccionales = get_tree().get_nodes_in_group("directional_lights")
	if luces_direccionales.is_empty():
		# Si no hay grupo, buscar por tipo
		luces_direccionales = []
		_buscar_luces_recursivo(self, DirectionalLight3D, luces_direccionales)
	
	for luz in luces_direccionales:
		if luz is DirectionalLight3D:
			# Habilitar sombras
			luz.shadow_enabled = true
			# Configurar bias para evitar shadow acne
			luz.shadow_bias = 0.1
			luz.shadow_normal_bias = 1.0
			# Configurar el modo de sombra
			luz.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			# Aumentar la distancia máxima de sombras
			luz.directional_shadow_max_distance = 100.0
			print("  ✅ DirectionalLight configurada:", luz.name)
	
	# Buscar luces puntuales y spots
	var luces_puntuales = []
	_buscar_luces_recursivo(self, SpotLight3D, luces_puntuales)
	_buscar_luces_recursivo(self, OmniLight3D, luces_puntuales)
	
	for luz in luces_puntuales:
		if luz is Light3D:
			# Habilitar sombras
			luz.shadow_enabled = true
			# Configurar bias
			luz.shadow_bias = 0.1
			luz.shadow_normal_bias = 1.0
			print("  ✅ Luz puntual/spot configurada:", luz.name)
	
	print("💡 Configuración de luces completada")

# Función auxiliar para buscar luces recursivamente
func _buscar_luces_recursivo(nodo: Node, tipo_luz: Variant, array_luces: Array):
	if nodo.is_class(str(tipo_luz).get_slice(".", -1)):
		array_luces.append(nodo)
	
	for hijo in nodo.get_children():
		_buscar_luces_recursivo(hijo, tipo_luz, array_luces)
func _input(event):
	# Para testing: puedes ajustar la calidad con teclas
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL:  # Tecla +
			if xr_interface:
				xr_interface.render_target_size_multiplier = min(xr_interface.render_target_size_multiplier + 0.1, 2.0)
				print("Render scale aumentado a: ", xr_interface.render_target_size_multiplier)
		elif event.keycode == KEY_MINUS:  # Tecla -
			if xr_interface:
				xr_interface.render_target_size_multiplier = max(xr_interface.render_target_size_multiplier - 0.1, 0.5)
				print("Render scale reducido a: ", xr_interface.render_target_size_multiplier)
