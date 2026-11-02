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

# Ranuras de accesorios combinables (Gorros, Gafas, Mochilas, Zapatos)
var equipped_slots: Dictionary = {
	"hat": "none",
	"eyewear": "none",
	"backpack": "none",
	"footwear": "none",
}

var current_hat: String:
	get:
		return equipped_slots["hat"]
	set(val):
		equip_item("hat", val)

# Texturas oficiales de las 16 prendas en espacio anatómico de carrera
var wardrobe_textures: Dictionary = {
	# Gorros
	"hat_royal_crown": preload("res://assets/textures/wardrobe/ingame/hat_royal_crown.png"),
	"hat_flower_wreath": preload("res://assets/textures/wardrobe/ingame/hat_flower_wreath.png"),
	"hat_party_hat": preload("res://assets/textures/wardrobe/ingame/hat_party_hat.png"),
	"hat_feather_headband": preload("res://assets/textures/wardrobe/ingame/hat_feather_headband.png"),
	
	# Gafas
	"eyewear_sunglasses": preload("res://assets/textures/wardrobe/ingame/eyewear_sunglasses.png"),
	"eyewear_reading_glasses": preload("res://assets/textures/wardrobe/ingame/eyewear_reading_glasses.png"),
	"eyewear_aviator_goggles": preload("res://assets/textures/wardrobe/ingame/eyewear_aviator_goggles.png"),
	"eyewear_snorkel_mask": preload("res://assets/textures/wardrobe/ingame/eyewear_snorkel_mask.png"),
	
	# Mochilas
	"backpack_hiking_backpack": preload("res://assets/textures/wardrobe/ingame/backpack_hiking_backpack.png"),
	"backpack_messenger_satchel": preload("res://assets/textures/wardrobe/ingame/backpack_messenger_satchel.png"),
	"backpack_school_backpack": preload("res://assets/textures/wardrobe/ingame/backpack_school_backpack.png"),
	"backpack_star_backpack": preload("res://assets/textures/wardrobe/ingame/backpack_star_backpack.png"),
	
	# Zapatos
	"footwear_colorful_sneakers": preload("res://assets/textures/wardrobe/ingame/footwear_colorful_sneakers.png"),
	"footwear_winter_booties": preload("res://assets/textures/wardrobe/ingame/footwear_winter_booties.png"),
	"footwear_adventurer_boots": preload("res://assets/textures/wardrobe/ingame/footwear_adventurer_boots.png"),
	"footwear_roller_skates": preload("res://assets/textures/wardrobe/ingame/footwear_roller_skates.png"),
}

const STRIDE_BOB: Array = [
	Vector2(0, 0),       # frame 0
	Vector2(1.0, 0),     # frame 1 (extensión de zancada)
	Vector2(0.5, -0.5),  # frame 2
	Vector2(0, 2.5),     # frame 3 (compresión de pisada)
	Vector2(0, 0),       # frame 4
	Vector2(1.0, 0),     # frame 5 (extensión)
	Vector2(0.5, 2.5),   # frame 6 (compresión)
	Vector2(0, 0),       # frame 7
]

@onready var visuals: Node2D = $Visuals
@onready var anim_sprite: AnimatedSprite2D = $Visuals/AnimSprite
@onready var slot_nodes: Dictionary = {
	"footwear": $Visuals/Footwear,
	"backpack": $Visuals/Backpack,
	"eyewear": $Visuals/Eyewear,
	"hat": $Visuals/Hat,
}
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
			
	# Animar sincronía y rebote anatómico de todas las prendas equipadas
	update_accessories_bob()

func update_accessories_bob() -> void:
	var base_pos = Vector2(0, -32)
	var bob = Vector2.ZERO
	if anim_sprite.animation == "run":
		var f = anim_sprite.frame % STRIDE_BOB.size()
		bob = STRIDE_BOB[f]
	elif anim_sprite.animation == "jump":
		bob = Vector2(0, 1.5)
	elif anim_sprite.animation == "glide":
		bob = Vector2(0.5, -1.0)
		
	for slot in slot_nodes.keys():
		var node: Sprite2D = slot_nodes[slot]
		if node and node.visible:
			node.position = base_pos + bob

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

func equip_item(slot: String, item_id: String) -> void:
	if not slot_nodes.has(slot):
		return
	equipped_slots[slot] = item_id
	var node: Sprite2D = slot_nodes[slot]
	var key = slot + "_" + item_id
	if item_id == "none" or not wardrobe_textures.has(key):
		node.visible = false
		node.texture = null
	else:
		node.texture = wardrobe_textures[key]
		node.visible = true
		
		# Animación suave y tierna al vestirse
		visuals.scale = Vector2(1.08, 1.08)
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func equip_hat(hat_id: String) -> void:
	equip_item("hat", hat_id)

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
