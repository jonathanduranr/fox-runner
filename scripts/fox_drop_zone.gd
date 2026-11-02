class_name FoxDropZone
extends PanelContainer

signal sticker_dropped(sticker_id: String)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("sticker_id")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.has("sticker_id"):
		sticker_dropped.emit(data["sticker_id"])
