extends Camera2D

var dragging = false
var last_mouse_position = Vector2()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			last_mouse_position = get_global_mouse_position()
	
	if event is InputEventMouseMotion and dragging:
		var mouse_movement = last_mouse_position - get_global_mouse_position()
		position += mouse_movement
		last_mouse_position = get_global_mouse_position()
