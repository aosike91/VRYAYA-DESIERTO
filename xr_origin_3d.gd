extends Node3D

var xr_interface: XRInterface

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		XRServer.primary_interface = xr_interface
		if xr_interface.is_initialized():
			print("✅ OpenXR initialized successfully")
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			get_viewport().use_xr = true
		else:
			print("❌ OpenXR found but not initialized")
	else:
		print("❌ OpenXR interface not found")
