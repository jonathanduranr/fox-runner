class_name GameHUD
extends CanvasLayer

signal mode_toggle_requested
signal hat_equipped(hat_id: String)

@onready var star_count_label: Label = $TopBar/HBoxContainer/StarCount
@onready var distance_label: Label = $TopBar/HBoxContainer/DistanceLabel
@onready var mission_label: Label = $TopBar/MissionPanel/MissionLabel
@onready var mode_button: Button = $TopBar/RightButtons/ModeButton
@onready var wardrobe_button: Button = $TopBar/RightButtons/WardrobeButton
@onready var tutorial_label: Label = $TutorialLabel

# Panel del Guardarropa
@onready var wardrobe_backdrop: ColorRect = $WardrobeBackdrop
@onready var wardrobe_panel: Panel = $WardrobeModal
@onready var close_wardrobe_btn: Button = $WardrobeModal/CloseButton

# Banner de celebración de misión
@onready var celebration_banner: Panel = $CelebrationBanner
@onready var celebration_text: Label = $CelebrationBanner/CelebrationText

var total_stars: int = 0
var max_distance: float = 0.0

# Texturas de botones de modo
const ICON_SUN: Texture2D = preload("res://assets/textures/sun.png")
const ICON_MOON: Texture2D = preload("res://assets/textures/moon.png")

# Sistema de Misiones para niños (sin emojis que fallen en renderizar)
var missions = [
	{"id": "stars_20", "text": "Recoge 20 estrellas", "target": 20, "progress": 0, "reward": 10},
	{"id": "mushroom_2", "text": "Rebota en 2 hongos saltarines", "target": 2, "progress": 0, "reward": 15},
	{"id": "glide_4s", "text": "Planea 4 segundos seguidos", "target": 4, "progress": 0, "reward": 15},
	{"id": "dist_400", "text": "Recorre 400 metros", "target": 400, "progress": 0, "reward": 20},
	{"id": "stars_50", "text": "Consigue 50 estrellas", "target": 50, "progress": 0, "reward": 25},
]
var current_mission_idx: int = 0

# Inventario de sombreros desbloqueados
var unlocked_hats: Dictionary = {
	"none": true,
	"flower": false,
	"nightcap": false,
	"crown": false,
	"wizard": false
}
var hat_prices: Dictionary = {
	"flower": 10,
	"nightcap": 15,
	"crown": 25,
	"wizard": 35
}

func _ready() -> void:
	mode_button.pressed.connect(_on_mode_button_pressed)
	wardrobe_button.pressed.connect(_on_wardrobe_button_pressed)
	close_wardrobe_btn.pressed.connect(_on_close_wardrobe_pressed)
	wardrobe_panel.visible = false
	if wardrobe_backdrop:
		wardrobe_backdrop.visible = false
		wardrobe_backdrop.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_close_wardrobe_pressed()
			elif event is InputEventScreenTouch and event.pressed:
				_on_close_wardrobe_pressed()
		)
	celebration_banner.visible = false
	
	setup_wardrobe_buttons()
	update_star_display()
	update_mission_display()
	
	# Desvanecer el tutorial después de 6 segundos
	var tw = create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(tutorial_label, "modulate:a", 0.0, 1.5)

func setup_wardrobe_buttons() -> void:
	var items = [
		{"id": "none", "btn": $WardrobeModal/VBox/Grid/NoneBtn},
		{"id": "flower", "btn": $WardrobeModal/VBox/Grid/FlowerBtn},
		{"id": "nightcap", "btn": $WardrobeModal/VBox/Grid/NightcapBtn},
		{"id": "crown", "btn": $WardrobeModal/VBox/Grid/CrownBtn},
		{"id": "wizard", "btn": $WardrobeModal/VBox/Grid/WizardBtn},
	]
	
	for item in items:
		var hat_id = item["id"]
		var btn: Button = item["btn"]
		btn.pressed.connect(func(): _on_hat_item_clicked(hat_id, btn))
		update_hat_button_text(hat_id, btn)

func update_hat_button_text(hat_id: String, btn: Button) -> void:
	var names = {
		"none": "Al natural",
		"flower": "Flores",
		"nightcap": "Dormir",
		"crown": "Corona",
		"wizard": "Mago"
	}
	var hat_name = names.get(hat_id, hat_id)
	if hat_id == "none":
		btn.text = " " + hat_name
		return
		
	if unlocked_hats.get(hat_id, false):
		btn.text = " %s (Usar)" % hat_name
	else:
		btn.text = " %s (%d est.)" % [hat_name, hat_prices.get(hat_id, 10)]

func _on_hat_item_clicked(hat_id: String, btn: Button) -> void:
	if unlocked_hats.get(hat_id, false):
		_on_close_wardrobe_pressed()
		hat_equipped.emit(hat_id)
		if AudioManager:
			AudioManager.play_celebration()
	else:
		var price = hat_prices.get(hat_id, 10)
		if total_stars >= price:
			total_stars -= price
			unlocked_hats[hat_id] = true
			update_star_display()
			update_hat_button_text(hat_id, btn)
			_on_close_wardrobe_pressed()
			hat_equipped.emit(hat_id)
			if AudioManager:
				AudioManager.play_celebration()
		else:
			btn.text = " ¡Faltan estrellas!"
			var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_interval(1.2)
			tw.tween_callback(func(): update_hat_button_text(hat_id, btn))

func add_star() -> void:
	total_stars += 1
	update_star_display()
	
	# Efecto pop en el contador
	star_count_label.scale = Vector2(1.3, 1.3)
	var tw = create_tween()
	tw.tween_property(star_count_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
	# Avanzar misión de estrellas
	check_mission_progress("stars", total_stars)

func update_distance(dist_px: float) -> void:
	var meters = int(dist_px / 100.0)
	if meters > max_distance:
		max_distance = meters
		distance_label.text = "%d m" % max_distance
		check_mission_progress("distance", max_distance)

func register_mushroom_bounce() -> void:
	check_mission_progress("mushroom", 1, true)

func register_glide_time(seconds: float) -> void:
	check_mission_progress("glide", int(seconds))

func check_mission_progress(mission_type: String, value: int, is_incremental: bool = false) -> void:
	if current_mission_idx >= missions.size():
		return
		
	var m = missions[current_mission_idx]
	var matched = false
	
	match m["id"]:
		"stars_20", "stars_50":
			if mission_type == "stars":
				m["progress"] = value
				matched = true
		"mushroom_2":
			if mission_type == "mushroom":
				if is_incremental:
					m["progress"] += value
				matched = true
		"glide_4s":
			if mission_type == "glide":
				m["progress"] = max(m["progress"], value)
				matched = true
		"dist_400":
			if mission_type == "distance":
				m["progress"] = value
				matched = true
				
	if matched:
		update_mission_display()
		if m["progress"] >= m["target"]:
			complete_current_mission()

func complete_current_mission() -> void:
	var m = missions[current_mission_idx]
	total_stars += m["reward"]
	update_star_display()
	
	if AudioManager:
		AudioManager.play_celebration()
		
	# Mostrar banner de fiesta de misión
	celebration_text.text = "¡Misión Lograda!\n+%d Estrellas de regalo" % m["reward"]
	celebration_banner.visible = true
	celebration_banner.scale = Vector2(0.5, 0.5)
	celebration_banner.modulate.a = 0.0
	
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(celebration_banner, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK)
	tw.tween_property(celebration_banner, "modulate:a", 1.0, 0.3)
	tw.chain().tween_interval(2.5)
	tw.tween_property(celebration_banner, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		celebration_banner.visible = false
		current_mission_idx += 1
		update_mission_display()
	)

func update_mission_display() -> void:
	if current_mission_idx < missions.size():
		var m = missions[current_mission_idx]
		mission_label.text = "Misión: %s (%d/%d)" % [m["text"], m["progress"], m["target"]]
	else:
		mission_label.text = "¡Eres el Gran Campeón del Bosque!"

func update_star_display() -> void:
	star_count_label.text = "%d" % total_stars

func set_mode_icon(is_night: bool) -> void:
	mode_button.icon = ICON_MOON if is_night else ICON_SUN
	mode_button.text = " Noche" if is_night else " Día"

func _on_mode_button_pressed() -> void:
	mode_toggle_requested.emit()

func _on_wardrobe_button_pressed() -> void:
	if wardrobe_backdrop:
		wardrobe_backdrop.visible = true
	wardrobe_panel.visible = true
	wardrobe_panel.scale = Vector2(0.8, 0.8)
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(wardrobe_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	get_tree().paused = true

func _on_close_wardrobe_pressed() -> void:
	get_tree().paused = false
	if wardrobe_backdrop:
		wardrobe_backdrop.visible = false
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(wardrobe_panel, "scale", Vector2(0.8, 0.8), 0.15)
	tw.tween_callback(func(): wardrobe_panel.visible = false)
