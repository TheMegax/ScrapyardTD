extends Node2D

enum ENEMIES {TROOPER, SWARMER, HELI, BULKY, DEGRADER, JET, RUSH, DUPPER, BOSS}
enum TOWERS {PEASHOOTER, SLASHER, SNIPER, SHOTGUN, MINIGUN, HOMING, LASER, BLOWER, SPINSTER, ROADLY, BOOMERANG}

export var _lives = 100
export var _difficulty = "Normal"
export var _scraps = 150
export var _round = 0
export var _fastfoward = 3
export var _health_mod_value = 1.03
onready var gui = self.get_parent().get_node("GUI")
onready var grid_container = gui.get_node("ScrollContainer/CenterContainer/GridContainer")
onready var health_label = gui.get_node("HBoxContainer/HealthLabel")
onready var scrap_label = gui.get_node("HBoxContainer/ScrapLabel")
onready var round_label = gui.get_node("RoundInfo/RoundLabel")
onready var next_label = gui.get_node("RoundInfo/NextLabel")
onready var bot_label = gui.get_node("HelperInfo/BotLabel")
onready var tower_info = gui.get_node("TowerInfo")
onready var sell_label = tower_info.get_node("SellContainer/SellLabel")
onready var target_label = tower_info.get_node("TargetContainer/TargetLabel")
onready var speed_sprite = gui.get_node("SpeedSprite")
onready var overlay_screen = self.get_parent().get_node("OverlayScreen")
onready var cursor_sprite = self.get_parent().get_node("Cursor/Sprite")
onready var map_path = self.get_parent().get_node("MapPath")
onready var tile_map = self.get_parent().get_node("TileMap")
onready var tile_highlight = self.get_parent().get_node("TileHighlight")
onready var music_player = self.get_parent().get_node("MusicPlayer")

var used_positions = []
var _health_mod = 1
var bot_price = 20
var ROUND_TIME = 15
var selected_tower
var held_tower
var round_data = []
var time = 0
var speed = 1
var next_round_timer = 0
var is_on_round = false
var pause = false
var object_count = 0
var spawner_count = 0
var enemy_count = 0
var _has_game_started = false
var tower_data
var has_won = false
var has_lost = false

func _ready():	
	round_label.text = ""
	next_label.text = ""
	
	var file = File.new()
	file.open("res://Towers/TowerInfo.json", file.READ)
	var text_json = file.get_as_text()
	var result_json = JSON.parse(text_json)
	var tower_stats = result_json.result
	file.close()
	
	for data in tower_stats:
		var container_instance = preload("res://TowerContainer.tscn").instance()
		container_instance.get_node("VBoxContainer/CenterContainer").tower = TOWERS.get(data.get("name"))
		container_instance.get_node("VBoxContainer/CenterContainer").price = data.get("price")
		grid_container.add_child(container_instance)

func _process(delta):
	if has_won or has_lost:
		var alpha = overlay_screen.modulate.a8 + delta*200
		alpha = clamp(alpha, 0, 255)
		overlay_screen.modulate.a8 = alpha
	
	delta *= speed
	
	var mouse_pos = get_viewport().get_mouse_position()
	if Input.is_action_just_pressed("ui_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
		
	if _lives <= 0:
		_lives = 0
		health_label.text = str(_lives)
		has_lost = true
		overlay_screen.texture = load("res://Gui/Lose.png")
		pause = true
	
	if Input.is_action_just_pressed("toggle_fastfoward"):
		_toggle_fastfoward()
	
	tile_highlight.clear()
	if held_tower != null:
		cursor_sprite.texture = load("res://Mouse/mouse_grab.png")
		var tower_name = TOWERS.keys()[held_tower].capitalize()
		var file = File.new()
		file.open("res://Towers/" + tower_name + ".json", file.READ)
		var text_json = file.get_as_text()
		var result_json = JSON.parse(text_json)
		tower_data = result_json.result[0]
		file.close()
		_highlight_placement(_mouse_to_map(mouse_pos), tower_data.get("placement_type"))
	
	health_label.text = str(_lives)
	scrap_label.text = str(_scraps)
	bot_label.text = "BUY: $" + str(bot_price)
	
	if selected_tower != null:
		tower_info.visible = true
		sell_label.text = "SELL: $" + str(selected_tower._sell_price)
		target_label.text = "TARGET: " + str(selected_tower._target_type)
		if selected_tower.is_selected == false:
			selected_tower = null
	else:
		tower_info.visible = false
	
	if _has_game_started:
		round_label.text = "ROUND: " + str(_round)
		if is_on_round or next_round_timer <= 0:
			next_label.text = ""
		else:
			next_label.text = "Next round in: " + str(ceil(next_round_timer))
		_round_manager(delta)


func _round_manager(delta):
	if pause == true:
		if enemy_count == 0:
			has_won = true
			overlay_screen.texture = load("res://Gui/Win.png")
		return
	if next_round_timer <= 0 and is_on_round == false:
		_round += 1
		_health_mod *= _health_mod_value
		is_on_round = true
		var file = File.new()
		var directory = Directory.new()
		var file_dir = "res://Rounds/" + str(_round) + ".json"
		if directory.file_exists(file_dir):
			file.open(file_dir, file.READ)
			var text_json = file.get_as_text()
			var result_json = JSON.parse(text_json)
			round_data = result_json.result
		else:
			pause = true
			_round -= 1
		file.close()
	
	if is_on_round:
		time += delta
	else:
		next_round_timer -= delta
		return
	
	if round_data.size() == 0:
		if spawner_count == 0:
			time = 0
			is_on_round = false
			next_round_timer = ROUND_TIME
		return
	
	var data = round_data[0]
	var t = data.get("time")
	if t <= time:
		var spawner_instance = preload("res://SpawnerInstance.tscn").instance()
		
		spawner_instance._intervalseconds = data.get("intervalseconds")
		spawner_instance._quantity = data.get("quantity")
		spawner_instance._type = ENEMIES.get(data.get("type"))
		spawner_instance._obj_id = object_count
		object_count += 1
		spawner_count += 1
		self.add_child(spawner_instance)
		round_data.pop_front()

func _mouse_to_map(mouse_pos):
	var new_pos = mouse_pos/4
	new_pos = Vector2(new_pos.x - 16, new_pos.y - 16)
	return tile_map.world_to_map(new_pos)

func _map_to_world_snap(pos):
	var new_pos = tile_map.map_to_world(pos)
	new_pos *= 4
	new_pos = Vector2(new_pos.x + 96, new_pos.y + 96)
	return new_pos

func _highlight_placement(tile_pos, placement_type):
	if _is_valid_placement(tile_pos, placement_type):
		tile_highlight.set_cell(tile_pos.x, tile_pos.y, 1)
	else:
		tile_highlight.set_cell(tile_pos.x, tile_pos.y, 0)

func _is_valid_placement(pos, placement_type):
	var value = "[" + str(pos.x) + "," + str(pos.y) + "]"
	if used_positions.has(value):
		return false
	var cell = tile_map.get_cell(pos.x, pos.y)
	if cell == TileMap.INVALID_CELL:
		return false
	if placement_type == "GROUND":
		if cell == 23:
			return false
		return true
	elif placement_type == "ROAD":
		if cell == 23:
			return true
		return false
	return false

func _try_place_tower(pos):
	cursor_sprite.texture = load("res://Mouse/mouse_normal.png")
	var mouse2map = _mouse_to_map(pos)
	var value = "[" + str(mouse2map.x) + "," + str(mouse2map.y) + "]"
	if _is_valid_placement(mouse2map, tower_data.get("placement_type")):
		used_positions.append(value)
		var tower_instance = preload("res://TowerInstance.tscn").instance()
		tower_instance.position = _map_to_world_snap(mouse2map)
		var tower_name = TOWERS.keys()[held_tower].capitalize()
		
		tower_instance._tower_type = tower_data.get("name")
		tower_instance._area = tower_data.get("area")
		tower_instance._projectile = tower_data.get("projectile")
		tower_instance._placement_type = tower_data.get("placement_type")
		tower_instance._attack_speed = tower_data.get("attack_speed")
		tower_instance._max_health = tower_data.get("max_health")
		tower_instance._heating_rate = tower_data.get("heating_rate")
		tower_instance._maintenance_rate = tower_data.get("maintenance_rate")
		tower_instance._building_time = tower_data.get("building_time")
		tower_instance._building_price = tower_data.get("building_price")
		tower_instance._should_look_at_target = tower_data.get("should_look_at_target")
		tower_instance._turret_offset = tower_data.get("turret_offset")
		tower_instance._obj_id = object_count
		tower_instance._tower_name = tower_name
		object_count += 1
		self.add_child(tower_instance)
		return true
	return false

func _toggle_fastfoward():
	if _has_game_started == false:
		_has_game_started = true
		speed_sprite.texture = load("res://Gui/NormalSpeed.png")
		return
	
	if speed == _fastfoward:
		speed_sprite.texture = load("res://Gui/NormalSpeed.png")
		speed = 1
	else:
		speed_sprite.texture = load("res://Gui/Fastfoward.png")
		speed = _fastfoward

func _on_SpeedSprite_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			_toggle_fastfoward()

func _on_TextureBot_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			if bot_price <= _scraps:
				var bot_instance = preload("res://BotInstance.tscn").instance()
				self.add_child(bot_instance)
				_scraps -= bot_price
				bot_price = ceil(bot_price*1.5)


func _on_SellContainer_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			selected_tower._destroy()
			selected_tower = null


func _on_TargetContainer_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			selected_tower._next_target()


func _on_ResetContainer_gui_input(event):
	if overlay_screen.modulate.a8 == 255:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				_restart()

func _restart():
	has_lost = false
	has_won = false
	pause = false
	bot_price = 20
	_lives = 100
	_scraps = 150
	_round = 0
	_health_mod = 1
	used_positions = []
	_has_game_started = false
	overlay_screen.modulate.a8 = 0
	speed = 1
	next_round_timer = 0
	round_label.text = ""
	next_label.text = ""
	speed_sprite.texture = load("res://Gui/PlayButton.png")
	for kid in get_children():
		kid.queue_free()
	for dude in map_path.get_children():
		dude.queue_free()
