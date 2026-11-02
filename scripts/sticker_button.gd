class_name StickerButton
extends TextureRect

signal sticker_clicked(sticker_id: String)

var sticker_id: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		sticker_clicked.emit(sticker_id)

func _get_drag_data(_at_position: Vector2) -> Variant:
	var drag_preview = TextureRect.new()
	drag_preview.texture = texture
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drag_preview.custom_minimum_size = Vector2(96, 80)
	drag_preview.modulate = Color(1.15, 1.15, 1.15, 0.95)
	
	var preview_control = Control.new()
	drag_preview.position = -drag_preview.custom_minimum_size * 0.5
	preview_control.add_child(drag_preview)
	set_drag_preview(preview_control)
	return {"sticker_id": sticker_id}
