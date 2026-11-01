class_name LogObstacle
extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
var has_hit: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	if body is FoxPlayer:
		has_hit = true
		body.stumble()
		# Animación de bamboleo al chocar
		var tw = create_tween()
		tw.tween_property(sprite, "rotation", 0.15, 0.08)
		tw.tween_property(sprite, "rotation", -0.1, 0.08)
		tw.tween_property(sprite, "rotation", 0.0, 0.1)
