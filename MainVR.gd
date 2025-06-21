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
var lod_timer = 0.0
var lod_update_interval = 0.5  # Actualizar LOD cada 0.5 segundos

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
		
		# Configurar LOD y distancias de renderizado
		configurar_lod_sistema()
		
		print("Configuración VR completada")
	else:
		print("⚠️ No se pudo encontrar la interfaz OpenXR")

func configurar_lod_sistema():
	# Configurar las distancias de renderizado y LOD
	var camera = $XROrigin3D/XRCamera3D
	if camera:
		# Reducir la distancia máxima de renderizado para mejorar rendimiento
		camera.far = 100.0  # Objetos más allá de 100 metros no se renderizan
		
		# Configurar el Environment para fog (niebla) que oculte objetos lejanos
		var environment = camera.environment
		if not environment:
			environment = Environment.new()
			camera.environment = environment
		
		# Activar fog para ocultar objetos lejanos gradualmente
		environment.fog_enabled = true
		environment.fog_light_color = Color(0.8, 0.8, 0.9, 1.0)  # Color azulado suave
		environment.fog_light_energy = 0.5
		environment.fog_sun_scatter = 0.1
		environment.fog_density = 0.01  # Densidad baja para efecto sutil
		environment.fog_aerial_perspective = 0.3
		environment.fog_sky_affect = 0.1
		
		print("Sistema LOD configurado")
	
	# Configurar mesh LOD automático para todos los MeshInstance3D
	configurar_mesh_lod_automatico()

func configurar_mesh_lod_automatico():
	# Buscar todos los MeshInstance3D en la escena
	var meshes = find_all_mesh_instances(self)
	
	for mesh_instance in meshes:
		# Solo aplicar LOD a objetos que no sean críticos (UI, botones, etc.)
		if not es_objeto_critico(mesh_instance):
			configurar_lod_para_mesh(mesh_instance)

func find_all_mesh_instances(node: Node) -> Array:
	var meshes = []
	
	if node is MeshInstance3D:
		meshes.append(node)
	
	for child in node.get_children():
		meshes.append_array(find_all_mesh_instances(child))
	
	return meshes

func es_objeto_critico(mesh_instance: MeshInstance3D) -> bool:
	# Definir qué objetos son críticos y NO deben tener LOD reducido
	var path = mesh_instance.get_path()
	var name = mesh_instance.name.to_lower()
	
	# Objetos críticos: botones, UI, elementos interactivos cercanos
	var objetos_criticos = ["boton", "button", "ui", "viewport2din3d", "control"]
	
	for critico in objetos_criticos:
		if critico in name:
			return true
	
	# Si está muy cerca de la cámara también es crítico
	var camera = $XROrigin3D/XRCamera3D
	if camera:
		var distancia = camera.global_position.distance_to(mesh_instance.global_position)
		if distancia < 3.0:  # Objetos a menos de 3 metros son críticos
			return true
	
	return false

func configurar_lod_para_mesh(mesh_instance: MeshInstance3D):
	# Crear sistema de LOD basado en distancia
	var camera = $XROrigin3D/XRCamera3D
	if not camera:
		return
	
	# Configurar material con LOD
	var material = mesh_instance.get_surface_override_material(0)
	if not material:
		material = mesh_instance.mesh.surface_get_material(0)
	
	if material:
		# Crear copia del material para modificar
		var lod_material = material.duplicate()
		
		# Configurar filtro de texturas con distancia
		if lod_material.has_method("set_texture_filter"):
			lod_material.set_texture_filter(BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
		
		mesh_instance.set_surface_override_material(0, lod_material)

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

func _process(delta):
	# Actualizar LOD dinámicamente
	lod_timer += delta
	if lod_timer >= lod_update_interval:
		lod_timer = 0.0
		actualizar_lod_dinamico()

func actualizar_lod_dinamico():
	var camera = $XROrigin3D/XRCamera3D
	if not camera:
		return
	
	var meshes = find_all_mesh_instances(self)
	
	for mesh_instance in meshes:
		if es_objeto_critico(mesh_instance):
			continue
		
		var distancia = camera.global_position.distance_to(mesh_instance.global_position)
		actualizar_calidad_por_distancia(mesh_instance, distancia)

func actualizar_calidad_por_distancia(mesh_instance: MeshInstance3D, distancia: float):
	# Definir niveles de calidad por distancia
	var material = mesh_instance.get_surface_override_material(0)
	if not material:
		return
	
	# Muy cerca (0-5m): Calidad máxima
	if distancia < 5.0:
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		material.flags_transparent = false
		
	# Distancia media (5-15m): Calidad media
	elif distancia < 15.0:
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
	# Lejos (15-30m): Calidad baja
	elif distancia < 30.0:
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Reducir detalles si es posible
		if material.has_method("set_detail_enabled"):
			material.set_detail_enabled(false)
	
	# Muy lejos (30m+): Muy baja calidad o invisible
	else:
		mesh_instance.visible = false  # Ocultar completamente
