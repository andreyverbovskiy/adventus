extends Node2D

@onready var nodes_container = $NodesContainer  # The container holding all rooms (buttons)
@onready var path_lines = $Line2D  # Line2D for connections

var layers = randi_range(8, 12)  # Number of vertical layers
var map_structure = {}  # Stores the generated map

func _ready():
	generate_map()
	draw_paths()

func generate_map():
	if not Global.saved_map.is_empty():
		map_structure = Global.saved_map  # Load the stored map
		print("🔄 Loaded Existing Map: ", map_structure)  # Debugging
		return  # Skip generating a new one

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
			var num_connections = randi_range(1, len(current_layer))
			var possible_connections = current_layer.duplicate()
			possible_connections.shuffle()
			map_structure[prev_room] = possible_connections.slice(0, num_connections)

		prev_layer = current_layer  

	map_structure[layers] = ["Boss"]
	for last_room in prev_layer:
		map_structure[last_room] = ["Boss"]

	Global.saved_map = map_structure  # ✅ Save the generated map
	print("✅ Saved New Map: ", Global.saved_map)

func pick_random_room_type():
	var room_types = ["Battle", "Shop", "Event", "Puzzle", "Challenge", "City"]
	return room_types[randi() % room_types.size()]

func draw_paths():
	path_lines.clear_points()  # Remove old lines

	for start in map_structure.keys():
		if typeof(start) == TYPE_INT:
			continue  # Skip numeric layer keys, only process connections

		var ends = map_structure[start]
		var start_node = nodes_container.get_node_or_null(start)

		if start_node:
			var start_size = start_node.size / 2
			var start_center = start_node.position + start_size

			for end in ends:
				var end_node = nodes_container.get_node_or_null(end)
				if end_node:
					var end_size = end_node.size / 2
					var end_center = end_node.position + end_size

					print("✔ Drawing line from", start, "to", end)

					var new_line = Line2D.new()
					new_line.width = 5
					new_line.default_color = Color.BLACK
					new_line.add_point(start_center)
					new_line.add_point(end_center)

					add_child(new_line)  # Add the new line
