class_name ParallaxManager
extends Node2D

@onready var sky_rect: ColorRect = $SkyLayer/SkyRect
@onready var sun_sprite: Sprite2D = $CelestialLayer/Sun
@onready var moon_sprite: Sprite2D = $CelestialLayer/Moon

@onready var mountains_layer: Parallax2D = $MountainsLayer
@onready var mountains_polygon: Polygon2D = $MountainsLayer/MountainsPoly

@onready var midground_layer: Parallax2D = $MidgroundLayer
@onready var midground_polygon: Polygon2D = $MidgroundLayer/MidgroundPoly

# Colores para Día y Noche
const DAY_SKY_TOP: Color = Color(0.68, 0.82, 0.94)
const DAY_SKY_BOTTOM: Color = Color(0.98, 0.84, 0.74)
const DAY_MOUNTAIN: Color = Color(0.72, 0.70, 0.84)
const DAY_MIDGROUND: Color = Color(0.55, 0.70, 0.60)

const NIGHT_SKY_TOP: Color = Color(0.08, 0.10, 0.22)
const NIGHT_SKY_BOTTOM: Color = Color(0.18, 0.12, 0.26)
const NIGHT_MOUNTAIN: Color = Color(0.14, 0.13, 0.26)
const NIGHT_MIDGROUND: Color = Color(0.10, 0.14, 0.22)

var is_night_mode: bool = false

func _ready() -> void:
	build_distant_mountains()
	build_midground_hills()
	apply_mode(is_night_mode, false)

func build_distant_mountains() -> void:
	# Genera una cadena montañosa procedural suave de 2560px de ancho que repite
	var points: PackedVector2Array = []
	points.append(Vector2(0, 720))
	
	var width = 2560.0
	var step = 80.0
	var x = 0.0
	while x <= width:
		var y = 380.0 + sin(x * 0.003) * 120.0 + cos(x * 0.007) * 60.0
		points.append(Vector2(x, y))
		x += step
		
	points.append(Vector2(width, 720))
	mountains_polygon.polygon = points
	mountains_layer.repeat_size = Vector2(width, 0)
	mountains_layer.scroll_scale = Vector2(0.08, 0.08)

func build_midground_hills() -> void:
	var points: PackedVector2Array = []
	points.append(Vector2(0, 720))
	
	var width = 2560.0
	var step = 60.0
	var x = 0.0
	while x <= width:
		var y = 470.0 + sin(x * 0.004) * 80.0 + cos(x * 0.009) * 40.0
		points.append(Vector2(x, y))
		x += step
		
	points.append(Vector2(width, 720))
	midground_polygon.polygon = points
	midground_layer.repeat_size = Vector2(width, 0)
	midground_layer.scroll_scale = Vector2(0.25, 0.25)

func apply_mode(is_night: bool, animated: bool = true) -> void:
	is_night_mode = is_night
	var duration = 1.0 if animated else 0.0
	
	var target_sky_col = NIGHT_SKY_BOTTOM if is_night else DAY_SKY_BOTTOM
	var target_mtn_col = NIGHT_MOUNTAIN if is_night else DAY_MOUNTAIN
	var target_mid_col = NIGHT_MIDGROUND if is_night else DAY_MIDGROUND
	
	if animated:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(sky_rect, "color", target_sky_col, duration)
		tw.tween_property(mountains_polygon, "color", target_mtn_col, duration)
		tw.tween_property(midground_polygon, "color", target_mid_col, duration)
		
		# Sol y Luna
		var sun_alpha = 0.0 if is_night else 1.0
		var moon_alpha = 1.0 if is_night else 0.0
		tw.tween_property(sun_sprite, "modulate:a", sun_alpha, duration)
		tw.tween_property(moon_sprite, "modulate:a", moon_alpha, duration)
	else:
		sky_rect.color = target_sky_col
		mountains_polygon.color = target_mtn_col
		midground_polygon.color = target_mid_col
		sun_sprite.modulate.a = 0.0 if is_night else 1.0
		moon_sprite.modulate.a = 1.0 if is_night else 0.0
