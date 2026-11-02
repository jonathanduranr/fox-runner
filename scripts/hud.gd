class_name GameHUD
extends CanvasLayer

const FoxDropZone = preload("res://scripts/fox_drop_zone.gd")
const StickerButton = preload("res://scripts/sticker_button.gd")

signal mode_toggle_requested
signal item_equipped(slot: String, item_id: String)
signal hat_equipped(hat_id: String)

@onready var star_count_label: Label = $TopBar/HBoxContainer/StarCount
@onready var distance_label: Label = $TopBar/HBoxContainer/DistanceLabel
@onready var mission_label: Label = $TopBar/MissionPanel/MissionLabel
@onready var mode_button: Button = $TopBar/RightButtons/ModeButton
@onready var wardrobe_button: Button = $TopBar/RightButtons/WardrobeButton
@onready var tutorial_label: Label = $TutorialLabel

# Panel del Probador de Stickers
@onready var wardrobe_backdrop: ColorRect = $WardrobeBackdrop
@onready var wardrobe_panel: Panel = $WardrobeModal
@onready var close_wardrobe_btn: Button = $WardrobeModal/CloseButton
@onready var drop_zone: FoxDropZone = $WardrobeModal/Content/FoxStand/DropZone
@onready var dressed_fox_rect: TextureRect = $WardrobeModal/Content/FoxStand/DropZone/DressedFoxRect
@onready var outfit_name_label: Label = $WardrobeModal/Content/FoxStand/OutfitNameLabel
@onready var unequip_btn: Button = $WardrobeModal/Content/FoxStand/UnequipBtn
@onready var sticker_grid: GridContainer = $WardrobeModal/Content/StickerAlbum/ScrollContainer/StickerGrid

# Banner de celebración de misión
@onready var celebration_banner: Panel = $CelebrationBanner
@onready var celebration_text: Label = $CelebrationBanner/CelebrationText

var total_stars: int = 0
var max_distance: float = 0.0

# Texturas de botones de modo
const ICON_SUN: Texture2D = preload("res://assets/textures/sun.png")
const ICON_MOON: Texture2D = preload("res://assets/textures/moon.png")
const FOX_NONE: Texture2D = preload("res://assets/textures/dressed_foxes/none.png")

# Los 12 Stickers oficiales y sus ilustraciones completas correspondientes
const STICKERS: Array[Dictionary] = [
	{"id": "royal_crown", "name": "Corona Real", "sticker": preload("res://assets/textures/stickers/royal_crown.png"), "dressed": preload("res://assets/textures/dressed_foxes/royal_crown.png")},
	{"id": "flower_wreath", "name": "Corona de Flores", "sticker": preload("res://assets/textures/stickers/flower_wreath.png"), "dressed": preload("res://assets/textures/dressed_foxes/flower_wreath.png")},
	{"id": "party_hat", "name": "Gorro de Fiesta", "sticker": preload("res://assets/textures/stickers/party_hat.png"), "dressed": preload("res://assets/textures/dressed_foxes/party_hat.png")},
	
	{"id": "sunglasses", "name": "Gafas de Sol", "sticker": preload("res://assets/textures/stickers/sunglasses.png"), "dressed": preload("res://assets/textures/dressed_foxes/sunglasses.png")},
	{"id": "aviator_goggles", "name": "Antiparras de Aviador", "sticker": preload("res://assets/textures/stickers/aviator_goggles.png"), "dressed": preload("res://assets/textures/dressed_foxes/aviator_goggles.png")},
	{"id": "snorkel_mask", "name": "Máscara con Esnórquel", "sticker": preload("res://assets/textures/stickers/snorkel_mask.png"), "dressed": preload("res://assets/textures/dressed_foxes/snorkel_mask.png")},
	
	{"id": "hiking_backpack", "name": "Mochila de Excursión", "sticker": preload("res://assets/textures/stickers/hiking_backpack.png"), "dressed": preload("res://assets/textures/dressed_foxes/hiking_backpack.png")},
	{"id": "messenger_satchel", "name": "Bolso Mensajero", "sticker": preload("res://assets/textures/stickers/messenger_satchel.png"), "dressed": preload("res://assets/textures/dressed_foxes/messenger_satchel.png")},
	{"id": "school_backpack", "name": "Mochila Escolar", "sticker": preload("res://assets/textures/stickers/school_backpack.png"), "dressed": preload("res://assets/textures/dressed_foxes/school_backpack.png")},
	
	{"id": "colorful_sneakers", "name": "Zapatillas de Colores", "sticker": preload("res://assets/textures/stickers/colorful_sneakers.png"), "dressed": preload("res://assets/textures/dressed_foxes/colorful_sneakers.png")},
	{"id": "winter_booties", "name": "Botitas de Invierno", "sticker": preload("res://assets/textures/stickers/winter_booties.png"), "dressed": preload("res://assets/textures/dressed_foxes/winter_booties.png")},
	{"id": "roller_skates", "name": "Patines de 4 Ruedas", "sticker": preload("res://assets/textures/stickers/roller_skates.png"), "dressed": preload("res://assets/textures/dressed_foxes/roller_skates.png")},
]

var current_sticker_id: String = "none"

# Misiones
var missions = [
	{"id": "stars_20", "text": "Recoge 20 estrellas", "target": 20, "progress": 0, "reward": 10},
	{"id": "mushroom_2", "text": "Rebota en 2 hongos saltarines", "target": 2, "progress": 0, "reward": 15},
	{"id": "glide_4s", "text": "Planea 4 segundos seguidos", "target": 4, "progress": 0, "reward": 15},
	{"id": "dist_400", "text": "Recorre 400 metros", "target": 400, "progress": 0, "reward": 20},
	{"id": "stars_50", "text": "Consigue 50 estrellas", "target": 50, "progress": 0, "reward": 25},
]
var current_mission_idx: int = 0

func _ready() -> void:
	mode_button.pressed.connect(_on_mode_button_pressed)
	wardrobe_button.pressed.connect(_on_wardrobe_button_pressed)
	close_wardrobe_btn.pressed.connect(_on_close_wardrobe_pressed)
	unequip_btn.pressed.connect(func(): dress_fox("none"))
	drop_zone.sticker_dropped.connect(dress_fox)
	
	wardrobe_panel.visible = false
	if wardrobe_backdrop:
		wardrobe_backdrop.visible = false
		wardrobe_backdrop.gui_input.connect(func(event):
			if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
				_on_close_wardrobe_pressed()
		)
	celebration_banner.visible = false
	
	setup_sticker_album()
	dress_fox("none", false)
	update_star_display()
	update_mission_display()
	
	# Desvanecer tutorial después de 6 segundos
	var tw = create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(tutorial_label, "modulate:a", 0.0, 1.5)

func setup_sticker_album() -> void:
	for s in STICKERS:
		var card_vbox = VBoxContainer.new()
		card_vbox.custom_minimum_size = Vector2(100, 110)
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.add_theme_constant_override("separation", 4)
		
		var btn = StickerButton.new()
		btn.sticker_id = s["id"]
		btn.texture = s["sticker"]
		btn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		btn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = Vector2(100, 82)
		btn.sticker_clicked.connect(dress_fox)
		
		# Efecto visual de sticker coleccionable
		btn.mouse_entered.connect(func():
			var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.1)
		)
		btn.mouse_exited.connect(func():
			var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		)
		
		var lbl = Label.new()
		lbl.text = s["name"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(1, 0.98, 0.92, 0.9))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(100, 26)
		
		card_vbox.add_child(btn)
		card_vbox.add_child(lbl)
		sticker_grid.add_child(card_vbox)

func dress_fox(sticker_id: String, play_feedback: bool = true) -> void:
	current_sticker_id = sticker_id
	
	if sticker_id == "none":
		dressed_fox_rect.texture = FOX_NONE
		outfit_name_label.text = "Al natural"
		unequip_btn.disabled = true
	else:
		var found = false
		for s in STICKERS:
			if s["id"] == sticker_id:
				dressed_fox_rect.texture = s["dressed"]
				outfit_name_label.text = s["name"]
				unequip_btn.disabled = false
				found = true
				break
				
		if not found:
			dressed_fox_rect.texture = FOX_NONE
			outfit_name_label.text = "Al natural"
			unequip_btn.disabled = true
			
	if play_feedback:
		dressed_fox_rect.scale = Vector2(1.08, 1.08)
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(dressed_fox_rect, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if AudioManager:
			AudioManager.play_celebration()
			
	item_equipped.emit("sticker", sticker_id)
	hat_equipped.emit(sticker_id)

func _on_wardrobe_button_pressed() -> void:
	if wardrobe_backdrop:
		wardrobe_backdrop.visible = true
	wardrobe_panel.visible = true
	wardrobe_panel.scale = Vector2(0.85, 0.85)
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(wardrobe_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	get_tree().paused = true

func _on_close_wardrobe_pressed() -> void:
	get_tree().paused = false
	if wardrobe_backdrop:
		wardrobe_backdrop.visible = false
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(wardrobe_panel, "scale", Vector2(0.85, 0.85), 0.15)
	tw.tween_callback(func(): wardrobe_panel.visible = false)

func add_star() -> void:
	total_stars += 1
	update_star_display()
	
	star_count_label.scale = Vector2(1.3, 1.3)
	var tw = create_tween()
	tw.tween_property(star_count_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
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
