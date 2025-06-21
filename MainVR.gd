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
		var main_viewport = get_viewport()
		if main_viewport:
			# Activar MSAA para mejor calidad
			main_viewport.msaa_3d = Viewport.MSAA_4X
			
			# Asegurar que el viewport se actualice siempre
			main_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			
			print("MSAA configurado a 4X")
		
		# Configurar el SubViewport del video si existe
		var sub_viewport = $SubViewport
		if sub_viewport:
			sub_viewport.msaa_3d = Viewport.MSAA_4X
			sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			
			# Configurar el tamaño del SubViewport para mejor calidad
			sub_viewport.size = Vector2i(1920, 1080)  # Resolución alta para videos
			
		print("Configuración VR completada")
	else:
		print("⚠️ No se pudo encontrar la interfaz OpenXR")

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
			# Mostrar viewport y reproducir animación
			viewport2d.visible = true
			animasau.play("confetti")
			confettiaudio.play()
			
			await animasau.animation_finished
			viewport2d.visible = false
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

# Función para ajustar la calidad dinámicamente (opcional)
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
