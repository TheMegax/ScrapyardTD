extends Area2D

onready var game_manager = self.get_parent()
onready var area_circle = self.get_node("AreaCircle")
onready var health_bar = self.get_node("Layer/HealthBar")
onready var sprite_turret = self.get_node("SpriteTurret")
onready var sprite_base = self.get_node("SpriteBase")
onready var shoot_sound = self.get_node("ShootSound")
onready var circular_progress = self.get_node("Layer3/CircularProgress")
onready var scrap_label = self.get_node("Layer2/Container/ScrapLabel")

enum PLACEMENT {GROUND, AIR, ROAD, WATER}
enum TARGETS {FIRST, LAST, CLOSE, STRONG}

var _tower_type
var _tower_name
var _level = 0
var _area
var _projectile
var _placement_type
var _attack_speed
var _max_health
var _health
var _heating_rate
var _maintenance_rate
var _maintenance_time = 1
var _maintenance_fraction = 8
var _building_time
var _target_type = "FIRST"
var _should_look_at_target
var _target
var _building_price
var _turret_offset
var _obj_id

var _heat_level = 0
var _is_broken = true
var _sell_price = 0
var attack_timer = 0
var repair_timer = 0
var build_timer = 0
var warning = 0

var colliding_enemies = {}
var is_selected = false
var mouse_inside_area = false

# TODO: Somehow, building other towers modifies the area
# of already placed ones. BIG issue.
# A patchwork solution was necessary as to not waste time

func _ready():
	#area_circle.shape.radius = _area
	area_circle.shape.radius = 2000
	_health = 0
	sprite_base.texture = load("res://Towers/BrokenBase.png")
	sprite_turret.texture = load("res://Towers/" + _tower_name + "Turret-" + str(_level) + ".png")
	sprite_turret.offset.y = _turret_offset
	
	if _tower_name == "Laser":
		$ShootSound.stream = load("res://Other/169989__peepholecircus__laser-bolt.mp3")
		$ShootSound.volume_db = -15
	
func _process(delta):
	delta *= game_manager.speed
	if game_manager._lives == 0:
		return
		
	mouse_inside_area = _is_mouse_in_hitbox()
	
	if Input.is_action_just_pressed("left_click"):
		is_selected = _is_mouse_in_hitbox_or_gui()
		if is_selected:
			game_manager.selected_tower = self
		area_circle.update()
	
	var health_percentage = (_health / _max_health)
	health_bar.value = health_percentage*100
	var pct_diff = 1.0 - health_percentage
	var red_color = min(255, pct_diff*2 * 255)
	var green_color = min(255, health_percentage*2 * 255)
	var col = Color8(red_color, green_color, 0)
	health_bar.tint_progress = col
	
	_sell_price = ceil((_building_price * 0.7) * health_percentage)
	
	if _is_broken:
		modulate.g8 = 255
		modulate.b8 = 255
		sprite_turret.visible = false
		$Layer2.visible = true
		scrap_label.text = str(_building_price)
		if mouse_inside_area and game_manager._scraps >= _building_price:
			repair_timer += delta
		else:
			repair_timer -= delta*2
		repair_timer = clamp(repair_timer, 0, _building_time)
		
		var progress = repair_timer/_building_time
		circular_progress.value = progress*100
		pct_diff = 1.0 - progress
		red_color = min(255, pct_diff*2 * 255)
		green_color = min(255, progress*2 * 255)
		col = Color8(red_color, green_color, 0)
		circular_progress.tint_progress = col
		
		if repair_timer == _building_time:
			game_manager._scraps -= _building_price
			repair_timer = 0
			_is_broken = false
			$Layer2.visible = false
			sprite_turret.visible = true
			sprite_base.texture = load("res://Towers/RedBase.png")
			circular_progress.value = 0
			_health = _max_health
		return
	
	if game_manager._has_game_started:
		_health -= _maintenance_rate * delta
	
	if mouse_inside_area and _health != _max_health:
		repair_timer += delta
	else:
		repair_timer -= delta*2
	repair_timer = clamp(repair_timer, 0, _maintenance_time)
	
	var progress = repair_timer/_maintenance_time
	circular_progress.value = progress*100
	pct_diff = 1.0 - progress
	red_color = min(255, pct_diff*2 * 255)
	green_color = min(255, progress*2 * 255)
	col = Color8(red_color, green_color, 0)
	circular_progress.tint_progress = col
	
	if repair_timer == _maintenance_time:
		repair_timer = 0
		circular_progress.value = 0
		_health += _max_health/_maintenance_fraction
	
	_health = clamp(_health, 0, _max_health)
	if _health == 0:
		sprite_base.texture = load("res://Towers/BrokenBase.png")
		_is_broken = true
		return
		
	if _health <= _max_health/4:
		modulate.g8 = 255 - warning
		modulate.b8 = 255 - warning
		warning -= delta * 100 / game_manager.speed
		if warning <= 0:
			warning = 70
	else:
		modulate.g8 = 255
		modulate.b8 = 255
		warning = 70
	
	attack_timer += delta
	var loops = floor(attack_timer / _attack_speed)
	attack_timer -= loops*_attack_speed
	
	_calculate_target()
	if _should_look_at_target:
		_look_at_target()
	
	if _tower_name == "Slasher":
		sprite_turret.rotate(-0.1)
	elif _tower_name == "Spinster":
		sprite_turret.rotate(0.01*game_manager.speed)
	if _target != null:
		if _tower_name == "Slasher":
			sprite_turret.rotate(-0.3)
		for _i in range(loops):
			_shoot_target()
	
	if _tower_name == "Roadly" and attack_timer > _attack_speed/2:
		sprite_turret.texture = load("res://Towers/RoadlyTurret-0.png")

func _calculate_target():
	if colliding_enemies.empty():
		_target = null
		return
	
	match _target_type:
		"FIRST":
			# Calculate first
			var max_offset = 0
			var target_index = -1
			var enemies = colliding_enemies.values()
			for i in range(len(enemies)):
				var enemy = enemies[i]
				if self.global_position.distance_to(enemy.global_position) > _area + enemy._area:
					continue
				if enemy.unit_offset > max_offset:
					max_offset = enemy.unit_offset
					target_index = i
			if target_index != -1:
				_target = enemies[target_index]
			else:
				_target = null
		"LAST":
			# Calculate last
			var min_offset = 9999999
			var target_index = -1
			var enemies = colliding_enemies.values()
			for i in range(len(enemies)):
				var enemy = enemies[i]
				if self.global_position.distance_to(enemy.global_position) > _area + enemy._area:
					continue
				if enemy.unit_offset < min_offset:
					min_offset = enemy.unit_offset
					target_index = i
			if target_index != -1:
				_target = enemies[target_index]
			else:
				_target = null
		"CLOSE":
			# Calculate close
			var min_distance = 999999999
			var target_index = -1
			var enemies = colliding_enemies.values()
			for i in range(len(enemies)):
				var enemy = enemies[i]
				var distance = global_position.distance_to(enemy.global_position)
				if distance > _area + enemy._area:
					continue
				if distance < min_distance:
					min_distance = distance
					target_index = i
			if target_index != -1:
				_target = enemies[target_index]
			else:
				_target = null
		"STRONG":
			# Calculate first
			var max_health = 0
			var target_index = -1
			var enemies = colliding_enemies.values()
			for i in range(len(enemies)):
				var enemy = enemies[i]
				if self.global_position.distance_to(enemy.global_position) > _area + enemy._area:
					continue
				if enemy._health > max_health:
					max_health = enemy._health
					target_index = i
			if target_index != -1:
				_target = enemies[target_index]
			else:
				_target = null


func _look_at_target():
	if (_target == null):
		return
	sprite_turret.look_at(_target.global_position)
	sprite_turret.rotation_degrees += 90
	
func _shoot_target():
	shoot_sound.play()
	if _tower_name == "Roadly":
		sprite_turret.texture = load("res://Towers/RoadlyTurret-1.png")
	for i in range(_projectile.get("quantity")):
		var projectile_instance = preload("res://ProjectileInstance.tscn").instance()
		projectile_instance._type = _projectile.get("type")
		projectile_instance._speed = _projectile.get("speed")
		projectile_instance._damage = _projectile.get("damage")
		projectile_instance._pierce = _projectile.get("pierce")
		projectile_instance._max_age = _projectile.get("max_age")
		projectile_instance._area = _projectile.get("area")
		projectile_instance._offset_units = _projectile.get("offset_units")
		projectile_instance._scale = _projectile.get("scale")
		var spread = _projectile.get("random_spread")
		projectile_instance.rotation = sprite_turret.rotation
		projectile_instance.rotation_degrees += rand_range(-spread, spread)
		projectile_instance.rotation_degrees -= 90
		if _tower_name == "Spinster":
			projectile_instance.rotation_degrees += 90*i
		self.add_child(projectile_instance)

func _is_mouse_in_hitbox():
	var mouse_pos = get_viewport().get_mouse_position()		
	var box = $Hitbox/CollisionShape2D.shape.extents.x * $Hitbox.scale.x
	if mouse_pos.x >= global_position.x - box and mouse_pos.x <= global_position.x + box:
		if mouse_pos.y >= global_position.y - box and mouse_pos.y <= global_position.y + box:
			return true
	return false
	
func _is_mouse_in_hitbox_or_gui():
	var mouse_pos = get_viewport().get_mouse_position()
	if mouse_pos.x < 64 or mouse_pos.y < 64 or mouse_pos.x > 1080 or mouse_pos.y > 700:
		return is_selected
		
	var box = $Hitbox/CollisionShape2D.shape.extents.x * $Hitbox.scale.x
	if mouse_pos.x >= global_position.x - box and mouse_pos.x <= global_position.x + box:
		if mouse_pos.y >= global_position.y - box and mouse_pos.y <= global_position.y + box:
			return true
	return false
	
func _repair(amount):
	_health += amount
	_health = clamp(_health, 0, _max_health)
	
func _damage(amount):
	_health -= amount
	_health = clamp(_health, 0, _max_health)

func _destroy():
	var _scrap_size = 10
	while _sell_price > 0:
		var scrap_instance = preload("res://ScrapInstance.tscn").instance()
		if _sell_price >= _scrap_size:
			scrap_instance._value = _scrap_size
		else:
			scrap_instance._value = _sell_price
		scrap_instance._speed = 0.5
		scrap_instance.position = global_position
		game_manager.add_child(scrap_instance)
		_sell_price -= _scrap_size
	var pos = game_manager._mouse_to_map(global_position)
	var value = "[" + str(pos.x) + "," + str(pos.y) + "]"
	var i = game_manager.used_positions.find(value)
	game_manager.used_positions.remove(i)
	queue_free()

func _next_target():
	if _target_type == "FIRST":
		_target_type = "LAST"
	elif _target_type == "LAST":
		_target_type = "CLOSE"
	elif _target_type == "CLOSE":
		_target_type = "STRONG"
	elif _target_type == "STRONG":
		_target_type = "FIRST"

func _on_TowerInstance_area_entered(col_area):
	if col_area.has_method("_take_damage"):
		var enemy_instance = col_area.get_parent()
		colliding_enemies[enemy_instance._obj_id] = enemy_instance

func _on_TowerInstance_area_exited(col_area):
	if col_area.has_method("_take_damage"):
		var enemy_instance = col_area.get_parent()
		colliding_enemies.erase(enemy_instance._obj_id)

