class_name GameHUD
extends CanvasLayer

signal mode_toggle_requested
signal item_equipped(slot: String, item_id: String)
signal hat_equipped(hat_id: String) # compatibilidad hacia atrás

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

# Pestañas de categorías
@onready var tab_hats: Button = $WardrobeModal/Content/LeftSection/CategoryTabs/TabHats
@onready var tab_eyewear: Button = $WardrobeModal/Content/LeftSection/CategoryTabs/TabEyewear
@onready var tab_backpacks: Button = $WardrobeModal/Content/LeftSection/CategoryTabs/TabBackpacks
@onready var tab_footwear: Button = $WardrobeModal/Content/LeftSection/CategoryTabs/TabFootwear

# Botones de ítems (5 botones: 1 para "none" y 4 para los ítems de la categoría)
@onready var item_buttons: Array[Button] = [
	$WardrobeModal/Content/LeftSection/ItemList/ItemBtn0,
	$WardrobeModal/Content/LeftSection/ItemList/ItemBtn1,
	$WardrobeModal/Content/LeftSection/ItemList/ItemBtn2,
	$WardrobeModal/Content/LeftSection/ItemList/ItemBtn3,
	$WardrobeModal/Content/LeftSection/ItemList/ItemBtn4,
]

# Capas del Probador Combinable
@onready var preview_layers: Dictionary = {
	"footwear": $WardrobeModal/Content/PreviewSection/PreviewCard/LayersHolder/LayerFootwear,
	"backpack": $WardrobeModal/Content/PreviewSection/PreviewCard/LayersHolder/LayerBackpack,
	"eyewear": $WardrobeModal/Content/PreviewSection/PreviewCard/LayersHolder/LayerEyewear,
	"hat": $WardrobeModal/Content/PreviewSection/PreviewCard/LayersHolder/LayerHat,
}

@onready var preview_title: Label = $WardrobeModal/Content/PreviewSection/PreviewTitle
@onready var preview_desc: Label = $WardrobeModal/Content/PreviewSection/PreviewDesc
@onready var action_btn: Button = $WardrobeModal/Content/PreviewSection/ActionBtn

# Banner de celebración de misión
@onready var celebration_banner: Panel = $CelebrationBanner
@onready var celebration_text: Label = $CelebrationBanner/CelebrationText

var total_stars: int = 0
var max_distance: float = 0.0

# Texturas de botones de modo
const ICON_SUN: Texture2D = preload("res://assets/textures/sun.png")
const ICON_MOON: Texture2D = preload("res://assets/textures/moon.png")
const ICON_NATURAL: Texture2D = preload("res://assets/textures/icon_natural.png")

# Catálogo completo de las 16 prendas combinables
const CATALOG: Dictionary = {
	"hat": {
		"title": "Gorros y Coronas",
		"items": [
			{"id": "none", "name": "Al natural", "desc": "Cabecita libre y fresca.", "price": 0, "icon": ICON_NATURAL},
			{"id": "royal_crown", "name": "Corona Real", "desc": "Digna de la realeza del bosque.", "price": 25, "icon": preload("res://assets/textures/wardrobe/icons/hats_royal_crown.png"), "layer": preload("res://assets/textures/wardrobe/layers/hat_royal_crown.png")},
			{"id": "flower_wreath", "name": "Corona de Flores", "desc": "Flores silvestres aromáticas del prado.", "price": 15, "icon": preload("res://assets/textures/wardrobe/icons/hats_flower_wreath.png"), "layer": preload("res://assets/textures/wardrobe/layers/hat_flower_wreath.png")},
			{"id": "party_hat", "name": "Gorro de Fiesta", "desc": "¡Listo para celebrar con piruetas!", "price": 20, "icon": preload("res://assets/textures/wardrobe/icons/hats_party_hat.png"), "layer": preload("res://assets/textures/wardrobe/layers/hat_party_hat.png")},
			{"id": "feather_headband", "name": "Vincha con Plumas", "desc": "Espíritu veloz y libre de las colinas.", "price": 30, "icon": preload("res://assets/textures/wardrobe/icons/hats_feather_headband.png"), "layer": preload("res://assets/textures/wardrobe/layers/hat_feather_headband.png")},
		]
	},
	"eyewear": {
		"title": "Gafas y Antiparras",
		"items": [
			{"id": "none", "name": "Al natural", "desc": "Mirada atenta del zorrito.", "price": 0, "icon": ICON_NATURAL},
			{"id": "sunglasses", "name": "Gafas de Sol", "desc": "Estilo fresco y relajado para el día.", "price": 10, "icon": preload("res://assets/textures/wardrobe/icons/eyewear_sunglasses.png"), "layer": preload("res://assets/textures/wardrobe/layers/eyewear_sunglasses.png")},
			{"id": "reading_glasses", "name": "Lentes de Lectura", "desc": "Para zorritos sabios y curiosos.", "price": 15, "icon": preload("res://assets/textures/wardrobe/icons/eyewear_reading_glasses.png"), "layer": preload("res://assets/textures/wardrobe/layers/eyewear_reading_glasses.png")},
			{"id": "aviator_goggles", "name": "Antiparras de Aviador", "desc": "¡Listas para volar alto por el cielo!", "price": 20, "icon": preload("res://assets/textures/wardrobe/icons/eyewear_aviator_goggles.png"), "layer": preload("res://assets/textures/wardrobe/layers/eyewear_aviator_goggles.png")},
			{"id": "snorkel_mask", "name": "Máscara con Esnórquel", "desc": "Para chapotear y explorar el río.", "price": 25, "icon": preload("res://assets/textures/wardrobe/icons/eyewear_snorkel_mask.png"), "layer": preload("res://assets/textures/wardrobe/layers/eyewear_snorkel_mask.png")},
		]
	},
	"backpack": {
		"title": "Mochilas y Bolsos",
		"items": [
			{"id": "none", "name": "Al natural", "desc": "Lomo libre para saltar alto.", "price": 0, "icon": ICON_NATURAL},
			{"id": "hiking_backpack", "name": "Mochila de Excursión", "desc": "Con esterilla lista para acampar.", "price": 15, "icon": preload("res://assets/textures/wardrobe/icons/backpacks_hiking_backpack.png"), "layer": preload("res://assets/textures/wardrobe/layers/backpack_hiking_backpack.png")},
			{"id": "messenger_satchel", "name": "Bolso Mensajero", "desc": "Para llevar cartas y pequeños tesoros.", "price": 20, "icon": preload("res://assets/textures/wardrobe/icons/backpacks_messenger_satchel.png"), "layer": preload("res://assets/textures/wardrobe/layers/backpack_messenger_satchel.png")},
			{"id": "school_backpack", "name": "Mochila Escolar", "desc": "Espaciosa para libros y ricas meriendas.", "price": 25, "icon": preload("res://assets/textures/wardrobe/icons/backpacks_school_backpack.png"), "layer": preload("res://assets/textures/wardrobe/layers/backpack_school_backpack.png")},
			{"id": "star_backpack", "name": "Mochila Estrella", "desc": "Brilla con la magia de las estrellas.", "price": 30, "icon": preload("res://assets/textures/wardrobe/icons/backpacks_star_backpack.png"), "layer": preload("res://assets/textures/wardrobe/layers/backpack_star_backpack.png")},
		]
	},
	"footwear": {
		"title": "Calzado y Patines",
		"items": [
			{"id": "none", "name": "Al natural", "desc": "Patitas ágiles tocando el pasto.", "price": 0, "icon": ICON_NATURAL},
			{"id": "colorful_sneakers", "name": "Zapatillas de Colores", "desc": "Súper cómodas para trotar sin parar.", "price": 15, "icon": preload("res://assets/textures/wardrobe/icons/footwear_colorful_sneakers.png"), "layer": preload("res://assets/textures/wardrobe/layers/footwear_colorful_sneakers.png")},
			{"id": "winter_booties", "name": "Botitas de Invierno", "desc": "Acolchadas y calentitas para el frío.", "price": 20, "icon": preload("res://assets/textures/wardrobe/icons/footwear_winter_booties.png"), "layer": preload("res://assets/textures/wardrobe/layers/footwear_winter_booties.png")},
			{"id": "adventurer_boots", "name": "Botas de Aventura", "desc": "Resistentes para cualquier sendero.", "price": 25, "icon": preload("res://assets/textures/wardrobe/icons/footwear_adventurer_boots.png"), "layer": preload("res://assets/textures/wardrobe/layers/footwear_adventurer_boots.png")},
			{"id": "roller_skates", "name": "Patines de 4 Ruedas", "desc": "¡Velocidad y piruetas por las colinas!", "price": 35, "icon": preload("res://assets/textures/wardrobe/icons/footwear_roller_skates.png"), "layer": preload("res://assets/textures/wardrobe/layers/footwear_roller_skates.png")},
		]
	}
}

# Estado de equipamiento combinado
var equipped_items: Dictionary = {
	"hat": "none",
	"eyewear": "none",
	"backpack": "none",
	"footwear": "none",
}

# Desbloqueos (guardados por "slot_item")
var unlocked_items: Dictionary = {
	"hat_none": true,
	"eyewear_none": true,
	"backpack_none": true,
	"footwear_none": true,
}

var current_category: String = "hat"
var selected_item_data: Dictionary = {}

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
	action_btn.pressed.connect(_on_action_btn_pressed)
	
	wardrobe_panel.visible = false
	if wardrobe_backdrop:
		wardrobe_backdrop.visible = false
		wardrobe_backdrop.gui_input.connect(func(event):
			if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
				_on_close_wardrobe_pressed()
		)
	celebration_banner.visible = false
	
	setup_category_tabs()
	update_star_display()
	update_mission_display()
	
	# Desvanecer el tutorial después de 6 segundos
	var tw = create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(tutorial_label, "modulate:a", 0.0, 1.5)

func setup_category_tabs() -> void:
	tab_hats.pressed.connect(func(): select_category("hat"))
	tab_eyewear.pressed.connect(func(): select_category("eyewear"))
	tab_backpacks.pressed.connect(func(): select_category("backpack"))
	tab_footwear.pressed.connect(func(): select_category("footwear"))
	
	# Conectar botones de ítems una sola vez
	for i in range(item_buttons.size()):
		var idx = i
		item_buttons[idx].pressed.connect(func(): _on_item_button_pressed(idx))
		
	select_category("hat")

func select_category(cat: String) -> void:
	current_category = cat
	
	# Resaltar pestaña activa
	var tabs = {"hat": tab_hats, "eyewear": tab_eyewear, "backpack": tab_backpacks, "footwear": tab_footwear}
	for c in tabs.keys():
		var btn: Button = tabs[c]
		if c == cat:
			btn.modulate = Color(1.2, 1.2, 1.2, 1.0)
		else:
			btn.modulate = Color(0.8, 0.8, 0.8, 0.9)
			
	populate_items_list()
	
	# Seleccionar el ítem actualmente equipado en esta categoría para previsualizar
	var eq_id = equipped_items.get(cat, "none")
	select_item_by_id(eq_id)

func populate_items_list() -> void:
	var cat_data = CATALOG.get(current_category, {})
	var items: Array = cat_data.get("items", [])
	
	for i in range(item_buttons.size()):
		var btn: Button = item_buttons[i]
		if i < items.size():
			btn.visible = true
			var it = items[i]
			btn.icon = it["icon"]
			update_button_label(btn, it)
		else:
			btn.visible = false

func update_button_label(btn: Button, item: Dictionary) -> void:
	var item_id: String = item["id"]
	var name_str: String = item["name"]
	var key = current_category + "_" + item_id
	var is_equipped = (equipped_items.get(current_category, "none") == item_id)
	
	if item_id == "none":
		if is_equipped:
			btn.text = " %s (Equipado)" % name_str
		else:
			btn.text = " %s" % name_str
		return
		
	if is_equipped:
		btn.text = " %s (Equipado)" % name_str
	elif unlocked_items.get(key, false):
		btn.text = " %s (Listo)" % name_str
	else:
		btn.text = " %s (%d est.)" % [name_str, item["price"]]

func select_item_by_id(item_id: String) -> void:
	var cat_data = CATALOG.get(current_category, {})
	var items: Array = cat_data.get("items", [])
	for it in items:
		if it["id"] == item_id:
			preview_item(it)
			return
	if items.size() > 0:
		preview_item(items[0])

func _on_item_button_pressed(idx: int) -> void:
	var cat_data = CATALOG.get(current_category, {})
	var items: Array = cat_data.get("items", [])
	if idx < items.size():
		preview_item(items[idx])

func preview_item(item: Dictionary) -> void:
	selected_item_data = item
	preview_title.text = item["name"]
	preview_desc.text = item["desc"]
	
	refresh_probador_layers()
	update_action_button()

func refresh_probador_layers() -> void:
	# Simular en el probador la combinación actual con el ítem previsualizado en la categoría activa
	for slot in ["footwear", "backpack", "eyewear", "hat"]:
		var layer_rect: TextureRect = preview_layers[slot]
		var item_id_to_show = equipped_items.get(slot, "none")
		
		# Si es la categoría activa, mostrar el ítem que se está probando actualmente
		if slot == current_category and selected_item_data.has("id"):
			item_id_to_show = selected_item_data["id"]
			
		if item_id_to_show == "none":
			layer_rect.texture = null
		else:
			var slot_items: Array = CATALOG[slot]["items"]
			for it in slot_items:
				if it["id"] == item_id_to_show and it.has("layer"):
					layer_rect.texture = it["layer"]
					break

func update_action_button() -> void:
	if not selected_item_data.has("id"):
		action_btn.disabled = true
		action_btn.text = "Selecciona prenda"
		return
		
	var item_id = selected_item_data["id"]
	var is_equipped = (equipped_items.get(current_category, "none") == item_id)
	var key = current_category + "_" + item_id
	var is_unlocked = (item_id == "none" or unlocked_items.get(key, false))
	
	if is_equipped:
		action_btn.disabled = true
		action_btn.text = "Equipado actualmente ✓"
	elif is_unlocked:
		action_btn.disabled = false
		if item_id == "none":
			action_btn.text = "Desequipar ranura"
		else:
			action_btn.text = "Equipar en Zorrito"
	else:
		var price = selected_item_data.get("price", 10)
		if total_stars >= price:
			action_btn.disabled = false
			action_btn.text = "Comprar por %d ⭐" % price
		else:
			action_btn.disabled = true
			action_btn.text = "Faltan estrellas (%d ⭐)" % price

func _on_action_btn_pressed() -> void:
	if not selected_item_data.has("id"):
		return
		
	var item_id = selected_item_data["id"]
	var key = current_category + "_" + item_id
	var is_unlocked = (item_id == "none" or unlocked_items.get(key, false))
	
	if is_unlocked:
		equip_and_sync(current_category, item_id)
	else:
		var price = selected_item_data.get("price", 10)
		if total_stars >= price:
			total_stars -= price
			unlocked_items[key] = true
			update_star_display()
			equip_and_sync(current_category, item_id)

func equip_and_sync(slot: String, item_id: String) -> void:
	equipped_items[slot] = item_id
	item_equipped.emit(slot, item_id)
	if slot == "hat":
		hat_equipped.emit(item_id)
		
	refresh_probador_layers()
	update_action_button()
	populate_items_list()
	if AudioManager:
		AudioManager.play_celebration()

func _on_wardrobe_button_pressed() -> void:
	if wardrobe_backdrop:
		wardrobe_backdrop.visible = true
	wardrobe_panel.visible = true
	wardrobe_panel.scale = Vector2(0.85, 0.85)
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(wardrobe_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	get_tree().paused = true
	select_category(current_category)

func _on_close_wardrobe_pressed() -> void:
	get_tree().paused = false
	if wardrobe_backdrop:
		wardrobe_backdrop.visible = false
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(wardrobe_panel, "scale", Vector2(0.8, 0.8), 0.15)
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
