extends Node2D

@onready var nodes_container = $NodesContainer  # Holds dynamically created rooms
@onready var path_lines = $Line2D  # Line2D for drawing paths

var layers = randi_range(8, 12)  # Number of vertical layers
var map_structure = {}  # Stores the generated map
var room_buttons = {}  # Keeps track of spawned buttons

# Reference to the RoomButton scene (must be assigned in the Inspector)
@export var room_button_scene: PackedScene  

@export var player_icon_scene: PackedScene
#var player_icon = null

@onready var player_icon = $NodesContainer/PlayerIcon

func _ready():
	if room_button_scene == null:
		print("⚠️ WARNING: room_button_scene is NULL. Assigning manually...")
		room_button_scene = load("res://scenes/RoomButton.tscn")  # Adjust path if needed
		print("✅ Loaded RoomButton scene:", room_button_scene)
	generate_map()
	spawn_rooms()
	draw_paths()

### **📌 Generate the Map Structure**
func generate_map():
	if not Global.saved_map.is_empty():
		map_structure = Global.saved_map  # Load stored map
		print("🔄 Loaded Existing Map: ", map_structure)
		return  

	print("🎲 Generating New Map...")
	map_structure.clear()

	var prev_layer = ["Start"]
	map_structure[0] = prev_layer  

	for i in range(1, layers):
		var num_rooms = randi_range(2, 4)
		var current_layer = []

		for j in range(num_rooms):
			var room_type = pick_random_room_type()
			var room_name = room_type + str(i) + "_" + str(j)
			current_layer.append(room_name)

		map_structure[i] = current_layer  
		
		for prev_room in prev_layer:
			var num_connections = 1 if "Shop" in prev_room or "Puzzle" in prev_room or "Event" in prev_room else randi_range(1, 2)
		#for prev_room in prev_layer:   # made random number of connections, ended up too nested
			#var num_connections = randi_range(1, len(current_layer)) 
			var possible_connections = current_layer.duplicate()
			possible_connections.shuffle()
			map_structure[prev_room] = possible_connections.slice(0, num_connections)

		prev_layer = current_layer  

	map_structure[layers] = ["Boss"]
	for last_room in prev_layer:
		map_structure[last_room] = ["Boss"]

	Global.saved_map = map_structure  # ✅ Save the generated map
	print("✅ Saved New Map: ", Global.saved_map)

func on_room_selected(room_name: String):
	var room_button = room_buttons.get(room_name)
	if room_button:
		player_icon.move_to(room_button.global_position + (room_button.size / 2))

func pick_random_room_type():
	# Define weighted probabilities
	var room_weights = {
		"Battle": 6,    # 60% weight
		"Shop": 2,      # 20% weight
		"Puzzle": 3.5,  # 35% weight
		"City": 1,      # 10% weight
		"Event": 3.5,   # 35% weight
		"Challenge": 2  # 20% weight
	}

	# Calculate total weight
	var total_weight = 0.0
	for weight in room_weights.values():
		total_weight += weight

	# Pick a random number within total weight
	var random_value = randf() * total_weight

	# Iterate through room types and subtract their weights
	for room_type in room_weights.keys():
		random_value -= room_weights[room_type]
		if random_value <= 0:
			return room_type  # Return the selected room

	return "Battle"  # Fallback (should never happen)

func _on_room_button_pressed(room_name):
	print("🟢 Clicked on Room:", room_name)
	if player_icon and room_buttons.has(room_name):
		# Move Player Icon to clicked room
		player_icon.move_to(room_buttons[room_name].global_position)
		print("🚶 Player moving to", room_name)

### **📌 Spawn Room Buttons Dynamically**
func spawn_rooms():
	var screen_width = get_viewport_rect().size.x
	var y_spacing = 200  # Vertical spacing between layers

	for i in map_structure.keys():  # Iterate only over valid keys
		if typeof(i) != TYPE_INT or typeof(map_structure[i]) != TYPE_ARRAY:
			continue  # Skip invalid keys

		var num_rooms = len(map_structure[i])
		var x_spacing = screen_width / (num_rooms + 1)  # Distribute evenly

		for j in range(num_rooms):
			var room_name = map_structure[i][j]
			var room_button = room_button_scene.instantiate() as TextureButton
			if room_button == null:
				print("❌ ERROR: RoomButton scene is not instantiating!")
				return  # Exit function early to prevent further errors

			# 🟢 Connect RoomButton signal to map.gd dynamically
			room_button.pressed.connect(_on_room_button_pressed.bind(room_name))

			# Position the room dynamically
			room_button.name = room_name
			room_button.position = Vector2((j + 1) * x_spacing, i * y_spacing + 100)

			# ✅ Assign different icons for each room type
			var icon_texture = load(get_icon_for_room(room_name))
			var icon_node = room_button.get_node("Icon")  # Get the TextureRect inside RoomButton
			if icon_node and icon_texture:
				icon_node.texture = icon_texture  # Set room-specific icon

			nodes_container.add_child(room_button)
			room_buttons[room_name] = room_button  # Store button reference

	# 🟡 Automatically Spawn Player Icon on Start Room
	if player_icon_scene and "Start" in room_buttons:
		player_icon = player_icon_scene.instantiate()
		player_icon.global_position = room_buttons["Start"].global_position + Vector2(32, 32)
		nodes_container.add_child(player_icon)
		print("🚀 Player placed on Start Room")

### **📌 Draw Paths Between Rooms**
func draw_paths():
	path_lines.clear_points()  

	for start in map_structure.keys():
		if typeof(start) == TYPE_INT:
			continue  

		var ends = map_structure[start]
		var start_node = room_buttons.get(start, null)

		if start_node:
			var start_center = start_node.position + (start_node.size / 2)

			for end in ends:
				var end_node = room_buttons.get(end, null)
				if end_node:
					var end_center = end_node.position + (end_node.size / 2)

					print("✔ Drawing line from", start, "to", end)

					var new_line = Line2D.new()
					new_line.width = 5
					new_line.default_color = Color.BLACK
					new_line.add_point(start_center)
					new_line.add_point(end_center)

					add_child(new_line)  # Add line to scene

### **📌 Function to Assign Different Icons for Each Room Type**
func get_icon_for_room(room_name):
	var icons = {
		"Battle": "res://assets/swords.png",
		"Shop": "res://assets/shop.png",
		"Event": "res://assets/event.png",
		"Puzzle": "res://assets/puzzle.png",
		"Challenge": "res://assets/challenge.png",
		"City": "res://assets/city.png",
		"Boss": "res://assets/boss.png"
	}

	for key in icons.keys():
		if key in room_name:  # Check if room_name contains "Battle", "Shop", etc.
			return icons[key]

	return "res://assets/start_icon.png"  # Fallback icon if no icon is fould
