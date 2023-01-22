extends Node2D

onready var game_manager = get_tree().current_scene.get_node("GameManager")
onready var cursor_sprite = get_tree().current_scene.get_node("Cursor/Sprite")

var _area = 20
var _healing_timer = 0
var _healing_rate = 1
var _healing_amount = 1.5
var _speed = 100
var _wait = 1
var _wait_timer = 0
var _is_being_held = true
var colliding_towers = {}
var _target

func _ready():
	$CollisionShape2D.shape.radius = _area
	_speed += rand_range(-30, 30)

func _process(delta):
	delta *= game_manager.speed
	var mouse_pos = get_viewport().get_mouse_position()
	
	if _is_mouse_in_hitbox():
		cursor_sprite.texture = load("res://Mouse/mouse_point.png")
		if Input.is_action_just_pressed("left_click"):
			_is_being_held = true
	else:
		cursor_sprite.texture = load("res://Mouse/mouse_normal.png")
	
	if _is_being_held:
		cursor_sprite.texture = load("res://Mouse/mouse_grab.png")
		global_position = mouse_pos
		$AnimatedSprite.playing = true
		$AnimatedSprite.animation = "RUN"
		$AnimatedSprite.speed_scale = 2 * game_manager.speed
		z_index = 20
		if Input.is_action_just_released("left_click"):
			_is_being_held = false
			cursor_sprite.texture = load("res://Mouse/mouse_point.png")
	else:
		z_index = 4
		$AnimatedSprite.speed_scale = 1 * game_manager.speed
		var target_index = -1
		var towers = colliding_towers.values()
		for i in range(len(towers)):
			var tower = towers[i]
			if self.global_position.distance_to(tower.global_position) > _area + tower._area:
				continue
			target_index = i
			break
		if target_index != -1:
			_target = towers[target_index]
		else:
			_target = null
		
		if _target == null or _target._is_broken:
			_wait_timer += delta
			if _wait_timer >= _wait:
				$AnimatedSprite.animation = "RUN"
				var distance = global_position.distance_to(mouse_pos)
				if distance > 30:
					var prev_rotation = self.rotation
					self.look_at(mouse_pos)
					global_position += transform.x * delta * _speed
					self.rotation = prev_rotation
					$AnimatedSprite.playing = true
				else:
					$AnimatedSprite.playing = false
				$AnimatedSprite.flip_h = (mouse_pos.x < global_position.x)

		else:
			$AnimatedSprite.animation = "FIX"
			$AnimatedSprite.playing = true
			_wait_timer = 0
			_healing_timer += delta
			if _healing_timer >= _healing_rate:
				_healing_timer = 0
				_target._repair(_healing_amount)

func _on_BotInstance_area_entered(col_area):
	var tower_instance = col_area.get_parent()
	if tower_instance.has_method("_repair"):
		colliding_towers[tower_instance._obj_id] = tower_instance

func _on_BotInstance_area_exited(col_area):
	var tower_instance = col_area.get_parent()
	if tower_instance.has_method("_repair"):
		colliding_towers.erase(tower_instance._obj_id)

func _is_mouse_in_hitbox():
	var mouse_pos = get_viewport().get_mouse_position()
	var circle = $CollisionShape2D.shape.radius
	if mouse_pos.distance_to(global_position) <= circle:
		return true
	return false
