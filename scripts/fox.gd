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

# SpriteFrames anatómicos pre-renderizados fotograma a fotograma para cada prenda/sombrero
var outfit_frames: Dictionary = {
	"crown": preload("res://scenes/outfit_crown.tres"),
	"wizard": preload("res://scenes/outfit_wizard.tres"),
	"flower": preload("res://scenes/outfit_flower.tres"),
	"nightcap": preload("res://scenes/outfit_nightcap.tres"),
}

@onready var visuals: Node2D = $Visuals
@onready var anim_sprite: AnimatedSprite2D = $Visuals/AnimSprite
@onready var outfit_sprite: AnimatedSprite2D = $Visuals/Outfit
@onready var glide_particles: CPUParticles2D = $Visuals/GlideParticles
@onready var night_aura: Sprite2D = $Visuals/NightAura
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
			
	# Sincronizar prenda/sombrero fotograma a fotograma con el zorrito
	if outfit_sprite and outfit_sprite.visible:
		if outfit_sprite.animation != anim_sprite.animation:
			outfit_sprite.animation = anim_sprite.animation
		outfit_sprite.frame = anim_sprite.frame
		outfit_sprite.speed_scale = anim_sprite.speed_scale

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
	if hat_id == "none" or not outfit_frames.has(hat_id):
		outfit_sprite.visible = false
		outfit_sprite.sprite_frames = null
	else:
		outfit_sprite.sprite_frames = outfit_frames[hat_id]
		outfit_sprite.visible = true
		outfit_sprite.animation = anim_sprite.animation
		outfit_sprite.frame = anim_sprite.frame
		outfit_sprite.speed_scale = anim_sprite.speed_scale
		
		# Animación suave y tierna al vestirse
		visuals.scale = Vector2(1.12, 1.12)
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_magnet_area_entered(area: Area2D) -> void:
	if area is StarCollectible:
		area.attract_to(self)
		if not area.collected.is_connected(_on_star_collected):
			area.collected.connect(_on_star_collected)

func _on_star_collected() -> void:
	star_collected.emit()

func set_night_mode(is_night: bool, animated: bool = true) -> void:
	if night_light:
		night_light.enabled = is_night
		var target_energy = 0.7 if is_night else 0.0
		var target_alpha = 0.35 if is_night else 0.0
		if animated:
			var tw = create_tween().set_parallel(true)
			tw.tween_property(night_light, "energy", target_energy, 0.5)
			if night_aura:
				tw.tween_property(night_aura, "modulate:a", target_alpha, 0.5)
		else:
			night_light.energy = target_energy
			if night_aura:
				night_aura.modulate.a = target_alpha
