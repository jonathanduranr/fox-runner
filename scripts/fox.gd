class_name FoxPlayer
extends CharacterBody2D

signal star_collected
signal mushroom_bounced
signal glided_time(seconds: float)

@export var run_speed: float = 350.0
@export var jump_velocity: float = -470.0
@export var gravity: float = 960.0
@export var glide_fall_speed: float = 88.0

var is_gliding: bool = false
var was_on_floor: bool = false
var is_invulnerable: bool = false
var glide_timer: float = 0.0

# Gestión del pañuelo rojo dinámico ondeante (Estilo Alto's Adventure)
var scarf_points: Array[Vector2] = []
const SCARF_LENGTH: int = 7
const SCARF_SEGMENT_DIST: float = 8.0

# Sombreros disponibles
var hat_textures: Dictionary = {
	"crown": preload("res://assets/textures/hat_crown.svg"),
	"wizard": preload("res://assets/textures/hat_wizard.svg"),
	"flower": preload("res://assets/textures/hat_flower.svg"),
	"nightcap": preload("res://assets/textures/hat_nightcap.svg"),
}

@onready var visuals: Node2D = $Visuals
@onready var anim_sprite: AnimatedSprite2D = $Visuals/AnimSprite
@onready var hat_sprite: Sprite2D = $Visuals/Hat
@onready var scarf_line: Line2D = $Visuals/ScarfLine
@onready var glide_particles: CPUParticles2D = $Visuals/GlideParticles
@onready var night_light: PointLight2D = $NightLight
@onready var magnet_area: Area2D = $MagnetArea

func _ready() -> void:
	floor_snap_length = 24.0
	floor_stop_on_slope = false
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(65.0)
	
	magnet_area.area_entered.connect(_on_magnet_area_entered)
	if glide_particles:
		glide_particles.emitting = false
		
	# Inicializar puntos de la bufanda
	scarf_points.clear()
	var neck_pos = Vector2(2, -28)
	for i in range(SCARF_LENGTH):
		scarf_points.append(neck_pos - Vector2(i * SCARF_SEGMENT_DIST, 0))
	scarf_line.points = PackedVector2Array(scarf_points)

func _physics_process(delta: float) -> void:
	velocity.x = run_speed
	
	var jump_held = Input.is_action_pressed("jump")
	var jump_just_pressed = Input.is_action_just_pressed("jump")
	
	if is_on_floor():
		is_gliding = false
		glide_timer = 0.0
		anim_sprite.play("run")
		anim_sprite.speed_scale = run_speed / 340.0
		if glide_particles:
			glide_particles.emitting = false
			
		if jump_just_pressed:
			velocity.y = jump_velocity
			anim_sprite.play("jump")
			if AudioManager:
				AudioManager.play_jump()
			visuals.scale = Vector2(0.85, 1.25)
			var tw = create_tween()
			tw.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.22)
	else:
		if jump_held and velocity.y > 0.0:
			is_gliding = true
			anim_sprite.play("glide")
			glide_timer += delta
			glided_time.emit(glide_timer)
			velocity.y = move_toward(velocity.y, glide_fall_speed, 850.0 * delta)
			if glide_particles:
				glide_particles.emitting = true
		else:
			is_gliding = false
			anim_sprite.play("jump")
			velocity.y += gravity * delta
			if glide_particles:
				glide_particles.emitting = false
				
	if is_on_floor() and not was_on_floor:
		visuals.scale = Vector2(1.2, 0.8)
		var tw = create_tween()
		tw.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.2)
		
	was_on_floor = is_on_floor()
	move_and_slide()
	
	update_visuals_and_scarf(delta)

func update_visuals_and_scarf(delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	
	if is_on_floor():
		var floor_normal = get_floor_normal()
		var target_rot = floor_normal.angle() + PI * 0.5
		visuals.rotation = lerp_angle(visuals.rotation, target_rot * 0.6, 12.0 * delta)
	else:
		if is_gliding:
			visuals.rotation = lerp_angle(visuals.rotation, 0.06, 6.0 * delta)
		else:
			var pitch = clamp(velocity.y / 600.0, -0.35, 0.35)
			visuals.rotation = lerp_angle(visuals.rotation, pitch, 6.0 * delta)
			
	# Simulación de la bufanda ondeante detrás del cuello
	var neck_origin = Vector2(2, -28)
	scarf_points[0] = neck_origin
	
	for i in range(1, SCARF_LENGTH):
		var prev = scarf_points[i - 1]
		var curr = scarf_points[i]
		
		# Ondulación por viento
		var wave_freq = 14.0 if is_gliding else 18.0
		var wave_amp = 3.5 if is_gliding else 5.0
		var wave_y = sin(t * wave_freq - float(i) * 0.8) * wave_amp
		
		var target_pos = prev - Vector2(SCARF_SEGMENT_DIST, -wave_y * 0.3)
		scarf_points[i] = curr.lerp(target_pos, 16.0 * delta)
		
	scarf_line.points = PackedVector2Array(scarf_points)

func launch_spring(bounce_force: float = -680.0) -> void:
	velocity.y = bounce_force
	is_gliding = false
	anim_sprite.play("jump")
	visuals.scale = Vector2(0.8, 1.35)
	var tw = create_tween()
	tw.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.25)
	mushroom_bounced.emit()

func stumble() -> void:
	if is_invulnerable:
		return
	is_invulnerable = true
	
	if AudioManager:
		AudioManager.play_stumble()
		
	# Voltereta cómica suave
	var tw = create_tween()
	tw.tween_property(visuals, "rotation", visuals.rotation + TAU, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Parpadeo de invulnerabilidad tierna
	var blink_tw = create_tween()
	for i in range(4):
		blink_tw.tween_property(visuals, "modulate:a", 0.35, 0.12)
		blink_tw.tween_property(visuals, "modulate:a", 1.0, 0.12)
	blink_tw.tween_callback(func(): is_invulnerable = false)

func equip_hat(hat_id: String) -> void:
	if hat_id == "none" or not hat_textures.has(hat_id):
		hat_sprite.visible = false
	else:
		hat_sprite.texture = hat_textures[hat_id]
		hat_sprite.visible = true
		hat_sprite.scale = Vector2(0.8, 0.8)
		var tw = create_tween()
		tw.tween_property(hat_sprite, "scale", Vector2(0.5, 0.5), 0.2).set_trans(Tween.TRANS_BACK)

func _on_magnet_area_entered(area: Area2D) -> void:
	if area is StarCollectible:
		area.attract_to(self)
		if not area.collected.is_connected(_on_star_collected):
			area.collected.connect(_on_star_collected)

func _on_star_collected() -> void:
	star_collected.emit()

func set_night_mode(is_night: bool) -> void:
	if night_light:
		night_light.enabled = is_night
		var tw = create_tween()
		var target_energy = 0.9 if is_night else 0.0
		tw.tween_property(night_light, "energy", target_energy, 0.5)
