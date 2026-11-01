class_name SpringMushroom
extends Area2D

signal bounced

@export var bounce_power: float = -680.0
@onready var sprite: Sprite2D = $Sprite2D
var is_bouncing: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_bouncing:
		return
	if body is FoxPlayer:
		is_bouncing = true
		bounced.emit()
		
		# Impulsar al zorrito hacia el cielo
		body.velocity.y = bounce_power
		if AudioManager:
			AudioManager.play_boing()
			
		# Animación elástica de rebote (squash & stretch)
		var tw = create_tween()
		tw.tween_property(sprite, "scale", Vector2(1.35, 0.55), 0.08)
		tw.tween_property(sprite, "scale", Vector2(0.85, 1.25), 0.15).set_trans(Tween.TRANS_BACK)
		tw.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)
		tw.tween_callback(func(): is_bouncing = false)
