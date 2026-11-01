class_name StarCollectible
extends Area2D

signal collected

@export var magnet_speed: float = 650.0
var target_player: Node2D = null
var base_y: float = 0.0
var float_offset: float = 0.0
var is_being_collected: bool = false

func _ready() -> void:
	base_y = position.y
	float_offset = randf_range(0.0, PI * 2.0)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_being_collected:
		return
		
	if target_player:
		# Movimiento atraído magnéticamente hacia el zorrito
		var dir = (target_player.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta
		# Si está muy cerca, recoger
		if global_position.distance_to(target_player.global_position) < 30.0:
			collect()
	else:
		# Flotación suave relajante
		var t = Time.get_ticks_msec() / 1000.0 * 3.0 + float_offset
		position.y = base_y + sin(t) * 8.0

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Fox" and not is_being_collected:
		collect()

func attract_to(player: Node2D) -> void:
	target_player = player

func collect() -> void:
	if is_being_collected:
		return
	is_being_collected = true
	collected.emit()
	
	# Efecto visual de recolección (escalar y desvanecer)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
