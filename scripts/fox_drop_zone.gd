class_name FoxDropZone
extends PanelContainer

signal sticker_dropped(sticker_id: String)
signal drag_hover_changed(is_hovered: bool)

var _is_hovered: bool = false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var can_drop = (data is Dictionary and data.has("sticker_id"))
	if can_drop and not _is_hovered:
		_is_hovered = true
		drag_hover_changed.emit(true)
	return can_drop

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_is_hovered = false
	drag_hover_changed.emit(false)
	if data is Dictionary and data.has("sticker_id"):
		sticker_dropped.emit(data["sticker_id"])

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if _is_hovered:
			_is_hovered = false
			drag_hover_changed.emit(false)
