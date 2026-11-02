class_name StickerButton
extends TextureRect

signal sticker_clicked(sticker_id: String)

var sticker_id: String = ""
var sticker_name: String = ""
var base_pos: Vector2 = Vector2.ZERO
var base_rot: float = 0.0
var is_dragging_me: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pivot_offset = custom_minimum_size * 0.5
	rotation_degrees = base_rot
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_initial_transform(pos: Vector2, rot_deg: float) -> void:
	base_pos = pos
	base_rot = rot_deg
	position = pos
	rotation_degrees = rot_deg
	pivot_offset = custom_minimum_size * 0.5

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		# Efecto táctil de pulsación elástica
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.08)
		tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK)
		sticker_clicked.emit(sticker_id)

func _get_drag_data(_at_position: Vector2) -> Variant:
	is_dragging_me = true
	modulate.a = 0.45
	
	# Vista previa de arrastre flotante con sombrita y brillo
	var drag_preview = TextureRect.new()
	drag_preview.texture = texture
	drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drag_preview.custom_minimum_size = custom_minimum_size * 1.15
	drag_preview.pivot_offset = drag_preview.custom_minimum_size * 0.5
	drag_preview.rotation_degrees = 8.0
	drag_preview.modulate = Color(1.1, 1.1, 1.1, 0.95)
	
	var preview_holder = Control.new()
	drag_preview.position = -drag_preview.custom_minimum_size * 0.5
	preview_holder.add_child(drag_preview)
	
	set_drag_preview(preview_holder)
	return {"sticker_id": sticker_id}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		is_dragging_me = false
		modulate.a = 1.0

func _on_mouse_entered() -> void:
	if is_dragging_me:
		return
	z_index = 20
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.14, 1.14), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", base_pos + Vector2(0, -6), 0.15).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "rotation_degrees", base_rot * 0.5, 0.15)

func _on_mouse_exited() -> void:
	if is_dragging_me:
		return
	z_index = 0
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", base_pos, 0.15).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "rotation_degrees", base_rot, 0.15)
