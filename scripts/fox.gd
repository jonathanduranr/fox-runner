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

var current_hat: String = "none"

# Sombreros disponibles con texturas PNG optimizadas
var hat_textures: Dictionary = {
	"crown": preload("res://assets/textures/hat_crown.png"),
	"wizard": preload("res://assets/textures/hat_wizard.png"),
	"flower": preload("res://assets/textures/hat_flower.png"),
	"nightcap": preload("res://assets/textures/hat_nightcap.png"),
}

# Sockets de posición de la cabeza para cada animación y fotograma (en espacio de Visuals)
const HEAD_SOCKETS: Dictionary = {
	"run": [
		Vector2(24.2, -51.3), # frame 0
		Vector2(30.3, -51.3), # frame 1 (extensión zancada hacia adelante)
		Vector2(25.3, -51.8), # frame 2
		Vector2(24.2, -44.7), # frame 3 (compresión de pisada hacia abajo)
		Vector2(24.8, -50.2), # frame 4
		Vector2(30.3, -50.7), # frame 5 (extensión zancada hacia adelante)
		Vector2(25.9, -46.9), # frame 6 (compresión de pisada hacia abajo)
		Vector2(24.2, -50.7), # frame 7
	],
	"jump": [
		Vector2(24.2, -44.7)
	],
	"glide": [
		Vector2(24.2, -51.3)
	]
}

# Calibración individual anatómica para que cada prenda calce cómoda y natural en la cabecita
const HAT_CONFIGS: Dictionary = {
	"crown": {
		"offset": Vector2(0.0, -6.0),
		"scale": Vector2(0.19, 0.19),
		"rot": deg_to_rad(2.0)
	},
	"flower": {
		"offset": Vector2(0.0, -4.0),
		"scale": Vector2(0.22, 0.22),
		"rot": 0.0
	},
	"nightcap": {
		"offset": Vector2(-1.5, -5.0),
		"scale": Vector2(0.22, 0.22),
		"rot": deg_to_rad(-5.0)
	},
	"wizard": {
		"offset": Vector2(-1.0, -8.0),
		"scale": Vector2(0.21, 0.21),
		"rot": deg_to_rad(-3.0)
	}
}

@onready var visuals: Node2D = $Visuals
@onready var anim_sprite: AnimatedSprite2D = $Visuals/AnimSprite
@onready var hat_sprite: Sprite2D = $Visuals/Hat
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
	
	update_visuals(delta)

func update_visuals(delta: float) -> void:
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
			
	# Actualizar posición y movimiento del sombrero sincronizado al movimiento de la cabeza
	if hat_sprite.visible and current_hat != "none":
		update_hat_transform()

func update_hat_transform() -> void:
	var anim_name = anim_sprite.animation
	var sockets: Array = HEAD_SOCKETS.get(anim_name, HEAD_SOCKETS["run"])
	var frame_idx: int = anim_sprite.frame % sockets.size()
	var base_socket: Vector2 = sockets[frame_idx]
	
	var cfg: Dictionary = HAT_CONFIGS.get(current_hat, {
		"offset": Vector2.ZERO,
		"scale": Vector2(0.48, 0.48),
		"rot": 0.0
	})
	
	var target_pos: Vector2 = base_socket + cfg["offset"]
	var target_rot: float = cfg["rot"]
	
	# Dinámica sutil de viento al saltar o planear
	if not is_on_floor():
		if is_gliding:
			target_pos += Vector2(1.0, -1.0)
			target_rot += deg_to_rad(-5.0)
		else:
			var pitch_hat = clamp(velocity.y / 700.0, -0.22, 0.22)
			target_rot += pitch_hat * 0.4
	
	hat_sprite.position = target_pos
	hat_sprite.rotation = target_rot
	if not hat_sprite.has_meta("is_animating_scale"):
		hat_sprite.scale = cfg["scale"]

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
	current_hat = hat_id
	if hat_id == "none" or not hat_textures.has(hat_id):
		hat_sprite.visible = false
		hat_sprite.texture = null
	else:
		hat_sprite.texture = hat_textures[hat_id]
		hat_sprite.visible = true
		update_hat_transform()
		
		var cfg = HAT_CONFIGS.get(hat_id, {"scale": Vector2(0.48, 0.48)})
		var base_scale: Vector2 = cfg["scale"]
		hat_sprite.set_meta("is_animating_scale", true)
		hat_sprite.scale = base_scale * 1.5
		var tw = create_tween()
		tw.tween_property(hat_sprite, "scale", base_scale, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): hat_sprite.remove_meta("is_animating_scale"))

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
