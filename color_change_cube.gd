extends RigidBody3D

@onready var main_vr = get_node("/root/MainVR")

func pointer_event(event : XRToolsPointerEvent) -> void:
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		print("🎯 Botón presionado:", name)

		var nodo_principal = get_node("/root/Node3D")  # Ajustado a la ruta correcta
		if nodo_principal:
			nodo_principal.verificar_respuesta(self)
