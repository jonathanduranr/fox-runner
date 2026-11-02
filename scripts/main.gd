class_name MainGame
extends Node2D

@onready var fox: FoxPlayer = $Fox
@onready var camera: Camera2D = $Camera2D
@onready var ground_generator: GroundGenerator = $GroundGenerator
@onready var parallax: ParallaxManager = $Parallax
@onready var hud: GameHUD = $HUD

var is_night: bool = false
var start_x: float = 0.0

func _ready() -> void:
	# 1. Generar terreno inicial ANTES de colocar al zorrito
	ground_generator.update_chunks(200.0)
	
	# 2. Posicionar al zorrito exactamente sobre la superficie del suelo
	fox.global_position.x = 200.0
	fox.global_position.y = ground_generator.get_height_at(200.0)
	start_x = fox.global_position.x
	
	# 3. Encuadre de cámara: zorrito en el tercio inferior para lucir el cielo
	camera.global_position.x = fox.global_position.x + 240.0
	camera.global_position.y = fox.global_position.y - 120.0
	
	# 4. Determinar ciclo Día/Noche según la hora real del sistema
	var current_hour = Time.get_time_dict_from_system()["hour"]
	is_night = (current_hour < 7 or current_hour >= 19)
	apply_day_night_mode(is_night, false)
	
	# 5. Iniciar música de fondo relajante
	if AudioManager:
		AudioManager.start_bgm(is_night)
	
	# 6. Conectar eventos del juego y misiones
	fox.star_collected.connect(_on_star_collected)
	fox.mushroom_bounced.connect(_on_mushroom_bounced)
	fox.glided_time.connect(_on_fox_glided)
	
	hud.mode_toggle_requested.connect(_on_mode_toggle_requested)
	hud.hat_equipped.connect(_on_hat_equipped)
	if hud.has_signal("item_equipped"):
		hud.item_equipped.connect(_on_item_equipped)

func _physics_process(delta: float) -> void:
	# Cámara cinematográfica: jugador a la izquierda con visión amplia del cielo y colinas
	var target_cam_x = fox.global_position.x + 240.0
	var target_cam_y = clamp(fox.global_position.y - 110.0, 150.0, 580.0)
	
	camera.global_position.x = target_cam_x
	camera.global_position.y = lerp(camera.global_position.y, target_cam_y, 4.0 * delta)
	
	# Actualizar generación procedural continua de colinas
	ground_generator.update_chunks(fox.global_position.x)
	
	# Salvavidas de seguridad: el zorrito NUNCA puede caer por debajo del terreno
	var ground_y = ground_generator.get_height_at(fox.global_position.x)
	if fox.global_position.y > ground_y + 8.0:
		fox.global_position.y = ground_y
		if fox.velocity.y > 0.0:
			fox.velocity.y = 0.0
	
	# Actualizar distancia recorrida en el HUD
	var traveled = fox.global_position.x - start_x
	hud.update_distance(traveled)

func _on_star_collected() -> void:
	hud.add_star()
	if AudioManager:
		AudioManager.play_star()

func _on_mushroom_bounced() -> void:
	hud.register_mushroom_bounce()

func _on_fox_glided(seconds: float) -> void:
	hud.register_glide_time(seconds)

func _on_hat_equipped(hat_id: String) -> void:
	fox.equip_hat(hat_id)

func _on_item_equipped(slot: String, item_id: String) -> void:
	fox.equip_item(slot, item_id)

func _on_mode_toggle_requested() -> void:
	is_night = not is_night
	if AudioManager:
		AudioManager.play_mode_switch()
		AudioManager.switch_bgm(is_night)
	apply_day_night_mode(is_night, true)

func apply_day_night_mode(night: bool, animated: bool = true) -> void:
	is_night = night
	hud.set_mode_icon(is_night)
	parallax.apply_mode(is_night, animated)
	fox.set_night_mode(is_night, animated)
	
	var ground_col = ground_generator.night_ground_color if is_night else ground_generator.day_ground_color
	var line_col = ground_generator.night_line_color if is_night else ground_generator.day_line_color
	ground_generator.set_mode_colors(ground_col, line_col)
