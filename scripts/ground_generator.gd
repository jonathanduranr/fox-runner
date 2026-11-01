class_name GroundGenerator
extends Node2D

# Parámetros matemáticos para las colinas continuas y suaves estilo Alto's Adventure
@export var base_height: float = 510.0
@export var bottom_depth: float = 1400.0
@export var chunk_width: float = 800.0
@export var segments_per_chunk: int = 40

# Frecuencias y amplitudes para ondas armónicas suaves
var f1: float = 0.0015
var a1: float = 65.0
var f2: float = 0.0032
var a2: float = 35.0
var f3: float = 0.0007
var a3: float = 45.0

# Colores según modo Día y Noche
var day_ground_color: Color = Color(0.48, 0.65, 0.52) # Verde salvia mate
var day_line_color: Color = Color(0.38, 0.55, 0.42)
var night_ground_color: Color = Color(0.12, 0.16, 0.28) # Azul índigo medianoche
var night_line_color: Color = Color(0.18, 0.24, 0.38)

var current_ground_color: Color = day_ground_color
var current_line_color: Color = day_line_color

var star_scene = preload("res://scenes/star.tscn")
var mushroom_scene = preload("res://scenes/spring_mushroom.tscn")
var log_scene = preload("res://scenes/log_obstacle.tscn")
var pine_tree_texture = preload("res://assets/textures/pine_tree.svg")

var active_chunks: Dictionary = {}

func _ready() -> void:
	pass

# Calcula la altura Y exacta para cualquier coordenada X en el mundo
func get_height_at(x: float) -> float:
	var h = base_height
	h += sin(x * f1) * a1
	h += cos(x * f2) * a2
	h += sin(x * f3) * a3
	return h

# Calcula la pendiente / ángulo normal en X
func get_slope_angle_at(x: float) -> float:
	var delta = 4.0
	var y1 = get_height_at(x - delta)
	var y2 = get_height_at(x + delta)
	return atan2(y2 - y1, delta * 2.0)

# Actualiza la generación de colinas alrededor de la posición del jugador
func update_chunks(player_x: float) -> void:
	var current_chunk_idx = int(floor(player_x / chunk_width))
	
	for i in range(current_chunk_idx - 1, current_chunk_idx + 4):
		if not active_chunks.has(i):
			create_chunk(i)
	
	var chunks_to_remove = []
	for idx in active_chunks.keys():
		if idx < current_chunk_idx - 2:
			chunks_to_remove.append(idx)
			
	for idx in chunks_to_remove:
		active_chunks[idx].queue_free()
		active_chunks.erase(idx)

func create_chunk(chunk_idx: int) -> void:
	var chunk_node = StaticBody2D.new()
	chunk_node.name = "Chunk_%d" % chunk_idx
	chunk_node.collision_layer = 1
	chunk_node.collision_mask = 1
	add_child(chunk_node)
	active_chunks[chunk_idx] = chunk_node
	
	var start_x = chunk_idx * chunk_width
	var end_x = (chunk_idx + 1) * chunk_width
	
	# Puntos exactos sin huecos entre chunks
	var surface_points: PackedVector2Array = []
	for i in range(segments_per_chunk + 1):
		var x = start_x + (float(i) / segments_per_chunk) * chunk_width
		var y = get_height_at(x)
		surface_points.append(Vector2(x, y))
	
	# 1. Colisión sólida continua
	var col_points: PackedVector2Array = surface_points.duplicate()
	col_points.append(Vector2(end_x, bottom_depth))
	col_points.append(Vector2(start_x, bottom_depth))
	
	var col_poly = CollisionPolygon2D.new()
	col_poly.polygon = col_points
	chunk_node.add_child(col_poly)
	
	# 2. Relleno visual con solape de 2px
	var visual_points: PackedVector2Array = surface_points.duplicate()
	visual_points.append(Vector2(end_x + 2.0, get_height_at(end_x + 2.0)))
	visual_points.append(Vector2(end_x + 2.0, bottom_depth))
	visual_points.append(Vector2(start_x, bottom_depth))
	
	var poly_visual = Polygon2D.new()
	poly_visual.name = "GroundFill"
	poly_visual.polygon = visual_points
	poly_visual.color = current_ground_color
	chunk_node.add_child(poly_visual)
	
	# 3. Línea de cresta suave
	var line_visual = Line2D.new()
	line_visual.name = "GroundLine"
	line_visual.points = surface_points
	line_visual.width = 4.0
	line_visual.default_color = current_line_color
	line_visual.joint_mode = Line2D.LINE_JOINT_ROUND
	chunk_node.add_child(line_visual)
	
	# 4. Decoraciones, Hongos, Troncos y Estrellas
	spawn_decorations_in_chunk(chunk_node, chunk_idx, start_x, end_x)

func spawn_decorations_in_chunk(parent: Node2D, chunk_idx: int, start_x: float, end_x: float) -> void:
	# Árboles en laderas
	var num_trees = randi_range(1, 2)
	for i in range(num_trees):
		var tree_x = randf_range(start_x + 80, end_x - 80)
		var tree_y = get_height_at(tree_x)
		
		var tree = Sprite2D.new()
		tree.texture = pine_tree_texture
		tree.position = Vector2(tree_x, tree_y - 65)
		var s = randf_range(0.75, 1.05)
		tree.scale = Vector2(s, s)
		tree.modulate = current_line_color * 0.9
		tree.z_index = -1
		parent.add_child(tree)
		
	# A partir del chunk 1, añadimos interactividad rica
	if chunk_idx >= 1:
		# 1. Hongo Saltarín (cada 2 chunks)
		if chunk_idx % 2 == 1:
			var mush_x = start_x + chunk_width * 0.4
			var mush_y = get_height_at(mush_x)
			var mushroom = mushroom_scene.instantiate()
			mushroom.position = Vector2(mush_x, mush_y)
			parent.add_child(mushroom)
			
			# Arco alto de estrellas para recoger al salir volando por el hongo
			var count = 5
			var spacing = 50.0
			var start_arc_x = mush_x - 40.0
			for s_idx in range(count):
				var sx = start_arc_x + s_idx * spacing
				var sy = mush_y - 180.0 - sin(s_idx / float(count - 1) * PI) * 120.0
				var star = star_scene.instantiate()
				star.position = Vector2(sx, sy)
				parent.add_child(star)
				
		# 2. Tronquito obstáculo para saltar (cada 3 chunks)
		elif chunk_idx % 3 == 2:
			var log_x = start_x + chunk_width * 0.65
			var log_y = get_height_at(log_x)
			var log_obj = log_scene.instantiate()
			log_obj.position = Vector2(log_x, log_y)
			parent.add_child(log_obj)

	# 3. Arcos estándar de estrellas en crestas de colinas
	var mid_x = (start_x + end_x) * 0.5
	var crest_y = get_height_at(mid_x)
	if crest_y < base_height and (chunk_idx % 2 != 1):
		var count = 4
		var spacing = 45.0
		var start_arc_x = mid_x - (count * spacing * 0.5)
		for s_idx in range(count):
			var sx = start_arc_x + s_idx * spacing
			var sy = get_height_at(sx) - 100.0 - sin(s_idx / float(count - 1) * PI) * 45.0
			var star = star_scene.instantiate()
			star.position = Vector2(sx, sy)
			parent.add_child(star)

func set_mode_colors(ground_col: Color, line_col: Color) -> void:
	current_ground_color = ground_col
	current_line_color = line_col
	for chunk in active_chunks.values():
		var fill = chunk.get_node_or_null("GroundFill")
		if fill:
			fill.color = ground_col
		var line = chunk.get_node_or_null("GroundLine")
		if line:
			line.default_color = line_col
