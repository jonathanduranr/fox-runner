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

# Panel del Probador de Stickers (Pantalla completa estilo Mesa Casual)
@onready var wardrobe_modal: Control = $WardrobeModal
@onready var close_wardrobe_btn: Button = $WardrobeModal/TopHeader/HBox/CloseButton
@onready var center_card: PanelContainer = $WardrobeModal/CenterCard
@onready var drop_zone: FoxDropZone = $WardrobeModal/CenterCard/VBox/DropZone
@onready var dressed_fox_rect: TextureRect = $WardrobeModal/CenterCard/VBox/DropZone/DressedFoxRect
@onready var outfit_name_label: Label = $WardrobeModal/CenterCard/VBox/OutfitNameLabel
@onready var unequip_btn: Button = $WardrobeModal/CenterCard/VBox/ButtonsRow/UnequipBtn
@onready var random_btn: Button = $WardrobeModal/CenterCard/VBox/ButtonsRow/RandomBtn
@onready var stickers_area: Control = $WardrobeModal/StickersArea

# Banner de celebración de misión
@onready var celebration_banner: Panel = $CelebrationBanner
@onready var celebration_text: Label = $CelebrationBanner/CelebrationText

var total_stars: int = 0
var max_distance: float = 0.0

# Texturas de botones de modo
const ICON_SUN: Texture2D = preload("res://assets/textures/sun.png")
const ICON_MOON: Texture2D = preload("res://assets/textures/moon.png")
const FOX_NONE: Texture2D = preload("res://assets/textures/dressed_foxes/none.png")

# Las 12 Prendas oficiales con coordenadas ergonómicas en la mesa (6 izq, 6 der)
const STICKER_CONFIG: Array[Dictionary] = [
	# 6 Stickers en el lado Izquierdo de la mesa
	{
		"id": "sunglasses",
		"name": "Gafas de Sol",
		"pos": Vector2(35, 95),
		"rot": -10.0,
		"tex": preload("res://assets/textures/stickers/sunglasses.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/sunglasses.png")
	},
	{
		"id": "aviator_goggles",
		"name": "Antiparras de Aviador",
		"pos": Vector2(225, 90),
		"rot": 8.0,
		"tex": preload("res://assets/textures/stickers/aviator_goggles.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/aviator_goggles.png")
	},
	{
		"id": "snorkel_mask",
		"name": "Máscara de Snorkel",
		"pos": Vector2(45, 260),
		"rot": 13.0,
		"tex": preload("res://assets/textures/stickers/snorkel_mask.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/snorkel_mask.png")
	},
	{
		"id": "hiking_backpack",
		"name": "Mochila Senderismo",
		"pos": Vector2(235, 255),
		"rot": -7.0,
		"tex": preload("res://assets/textures/stickers/hiking_backpack.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/hiking_backpack.png")
	},
	{
		"id": "messenger_satchel",
		"name": "Bolso Mensajero",
		"pos": Vector2(35, 425),
		"rot": -11.0,
		"tex": preload("res://assets/textures/stickers/messenger_satchel.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/messenger_satchel.png")
	},
	{
		"id": "school_backpack",
		"name": "Mochila Escolar",
		"pos": Vector2(225, 430),
		"rot": 9.0,
		"tex": preload("res://assets/textures/stickers/school_backpack.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/school_backpack.png")
	},
	
	# 6 Stickers en el lado Derecho de la mesa
	{
		"id": "colorful_sneakers",
		"name": "Zapatillas Coloridas",
		"pos": Vector2(885, 90),
		"rot": 9.0,
		"tex": preload("res://assets/textures/stickers/colorful_sneakers.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/colorful_sneakers.png")
	},
	{
		"id": "winter_booties",
		"name": "Botitas de Invierno",
		"pos": Vector2(1075, 95),
		"rot": -12.0,
		"tex": preload("res://assets/textures/stickers/winter_booties.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/winter_booties.png")
	},
	{
		"id": "roller_skates",
		"name": "Patines de 4 Ruedas",
		"pos": Vector2(875, 255),
		"rot": -8.0,
		"tex": preload("res://assets/textures/stickers/roller_skates.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/roller_skates.png")
	},
	{
		"id": "royal_crown",
		"name": "Corona Real",
		"pos": Vector2(1065, 260),
		"rot": 14.0,
		"tex": preload("res://assets/textures/stickers/royal_crown.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/royal_crown.png")
	},
	{
		"id": "flower_wreath",
		"name": "Corona de Flores",
		"pos": Vector2(885, 430),
		"rot": 11.0,
		"tex": preload("res://assets/textures/stickers/flower_wreath.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/flower_wreath.png")
	},
	{
		"id": "party_hat",
		"name": "Gorrito de Fiesta",
		"pos": Vector2(1075, 425),
		"rot": -10.0,
		"tex": preload("res://assets/textures/stickers/party_hat.png"),
		"dressed": preload("res://assets/textures/dressed_foxes/party_hat.png")
	},
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
	random_btn.pressed.connect(_on_random_btn_pressed)
	
	drop_zone.sticker_dropped.connect(dress_fox)
	drop_zone.drag_hover_changed.connect(_on_drop_zone_hover_changed)
	
	wardrobe_modal.visible = false
	celebration_banner.visible = false
	
	setup_sticker_table()
	dress_fox("none", false)
	update_star_display()
	update_mission_display()
	
	# Desvanecer tutorial después de 6 segundos
	var tw = create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(tutorial_label, "modulate:a", 0.0, 1.5)

func setup_sticker_table() -> void:
	for child in stickers_area.get_children():
		child.queue_free()
		
	for cfg in STICKER_CONFIG:
		var btn = StickerButton.new()
		btn.sticker_id = cfg["id"]
		btn.sticker_name = cfg["name"]
		btn.texture = cfg["tex"]
		btn.custom_minimum_size = Vector2(165, 140)
		btn.size = Vector2(165, 140)
		btn.set_initial_transform(cfg["pos"], cfg["rot"])
		btn.sticker_clicked.connect(dress_fox)
		stickers_area.add_child(btn)

func dress_fox(sticker_id: String, play_feedback: bool = true) -> void:
	current_sticker_id = sticker_id
	
	if sticker_id == "none":
		dressed_fox_rect.texture = FOX_NONE
		outfit_name_label.text = "Al natural (Sin ropa)"
		unequip_btn.disabled = true
	else:
		var found = false
		for s in STICKER_CONFIG:
			if s["id"] == sticker_id:
				dressed_fox_rect.texture = s["dressed"]
				outfit_name_label.text = "¡" + s["name"] + "! ✨"
				unequip_btn.disabled = false
				found = true
				break
				
		if not found:
			dressed_fox_rect.texture = FOX_NONE
			outfit_name_label.text = "Al natural (Sin ropa)"
			unequip_btn.disabled = true
			
	if play_feedback:
		# Squash and stretch jugoso para el zorrito
		dressed_fox_rect.pivot_offset = dressed_fox_rect.size * 0.5
		dressed_fox_rect.scale = Vector2(1.22, 0.82)
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(dressed_fox_rect, "scale", Vector2(0.92, 1.12), 0.12).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(dressed_fox_rect, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# Pulso elástico en la tarjeta central
		center_card.pivot_offset = center_card.size * 0.5
		var card_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		card_tw.tween_property(center_card, "scale", Vector2(1.03, 1.03), 0.08)
		card_tw.tween_property(center_card, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_BACK)
		
		if AudioManager:
			AudioManager.play_celebration()
			
	item_equipped.emit("sticker", sticker_id)
	hat_equipped.emit(sticker_id)

func _on_random_btn_pressed() -> void:
	var pool = STICKER_CONFIG.duplicate()
	var pick = pool[randi() % pool.size()]
	dress_fox(pick["id"])

func _on_drop_zone_hover_changed(is_hovered: bool) -> void:
	center_card.pivot_offset = center_card.size * 0.5
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if is_hovered:
		tw.tween_property(center_card, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_CUBIC)
	else:
		tw.tween_property(center_card, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_CUBIC)

func _on_wardrobe_button_pressed() -> void:
	wardrobe_modal.visible = true
	wardrobe_modal.modulate.a = 0.0
	wardrobe_modal.pivot_offset = Vector2(640, 360)
	wardrobe_modal.scale = Vector2(0.95, 0.95)
	
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(wardrobe_modal, "modulate:a", 1.0, 0.22)
	tw.tween_property(wardrobe_modal, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	get_tree().paused = true

func _on_close_wardrobe_pressed() -> void:
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(wardrobe_modal, "modulate:a", 0.0, 0.15)
	tw.tween_property(wardrobe_modal, "scale", Vector2(0.95, 0.95), 0.15)
	tw.chain().tween_callback(func():
		wardrobe_modal.visible = false
		get_tree().paused = false
	)

func add_star() -> void:
	total_stars += 1
	update_star_display()
	
	# Efecto rebote en el contador
	var tw = create_tween()
	tw.tween_property(star_count_label, "scale", Vector2(1.35, 1.35), 0.08)
	tw.tween_property(star_count_label, "scale", Vector2(1.0, 1.0), 0.12)
	
	check_mission_progress("stars", total_stars)

func update_star_display() -> void:
	star_count_label.text = str(total_stars)

func update_distance(distance: float) -> void:
	var meters = max(0.0, distance / 10.0)
	if meters > max_distance:
		max_distance = meters
		distance_label.text = "%d m" % int(meters)
		check_mission_progress("dist", int(meters))

func register_mushroom_bounce() -> void:
	check_mission_progress("mushroom", 1, true)

func register_glide_time(seconds: float) -> void:
	check_mission_progress("glide", int(seconds))

func check_mission_progress(mission_type: String, value: int, is_relative: bool = false) -> void:
	if current_mission_idx >= missions.size():
		return
		
	var m = missions[current_mission_idx]
	if not m["id"].begins_with(mission_type):
		return
		
	if is_relative:
		m["progress"] += value
	else:
		m["progress"] = max(m["progress"], value)
		
	update_mission_display()
	
	if m["progress"] >= m["target"]:
		complete_current_mission()

func complete_current_mission() -> void:
	var m = missions[current_mission_idx]
	total_stars += m["reward"]
	update_star_display()
	
	celebration_text.text = "¡Misión Lograda!
+%d Estrellas de regalo ⭐" % m["reward"]
	celebration_banner.visible = true
	celebration_banner.scale = Vector2(0.5, 0.5)
	celebration_banner.pivot_offset = Vector2(250, 60)
	
	var tw = create_tween()
	tw.tween_property(celebration_banner, "scale", Vector2(1.05, 1.05), 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(celebration_banner, "scale", Vector2(1.0, 1.0), 0.1)
	tw.tween_interval(2.5)
	tw.tween_property(celebration_banner, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		celebration_banner.visible = false
		celebration_banner.modulate.a = 1.0
	)
	
	if AudioManager:
		AudioManager.play_celebration()
		
	current_mission_idx += 1
	update_mission_display()

func update_mission_display() -> void:
	if current_mission_idx < missions.size():
		var m = missions[current_mission_idx]
		mission_label.text = "Misión: %s (%d/%d)" % [m["text"], m["progress"], m["target"]]
	else:
		mission_label.text = "¡Todas las misiones completadas! 🌟"

func set_mode_icon(is_night: bool) -> void:
	if is_night:
		mode_button.icon = ICON_MOON
		mode_button.text = " Noche"
	else:
		mode_button.icon = ICON_SUN
		mode_button.text = " Día"

func _on_mode_button_pressed() -> void:
	mode_toggle_requested.emit()
