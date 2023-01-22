extends Area2D

onready var game_manager = get_tree().current_scene.get_node("GameManager")
onready var collision_square = self.get_node("CollisionSquare")
onready var collision_circle = self.get_node("CollisionCircle")

enum PROJECTILES {BASIC, SMALL, HOMING, BOOMERANG, SNIPE, WIND, AREA, LASER}

var _type
var _speed
var _damage
var _pierce
var _max_age
var _age
var _area
var _offset_units
var _scale
var area_exceptions = {}
var _targetless_timer = 0

var colliding_enemies = {}
var _target

# TODO: Collision calculations work fine, but projectiles
# can "go through" enemies before being destroyed.

func _ready():
	_age = 0
	collision_square.shape.extents = Vector2(0, 0)
	self.position += self.transform.x * _offset_units
	$Sprite.scale = Vector2(_scale, _scale)
	if _type == "LASER":
		$Sprite.texture = load("res://Projectiles/proj_laser.png")
	elif _type == "AREA":
		collision_square.visible = false
		collision_square.disabled = true
		collision_circle.visible = true
		collision_circle.disabled = false
		$Sprite.visible = false
		collision_circle.shape.radius = _area
	elif _type == "BOOMERANG":
		$Sprite.texture = load("res://Projectiles/proj_boomerang.png")
	elif _type == "HOMING":
		$Sprite.texture = load("res://Projectiles/proj_homing.png")

func _process(delta):
	delta *= game_manager.speed
	_age += delta
	if _type != "AREA":
		collision_square.shape.extents = Vector2(_speed * delta, _area)
		collision_square.position = Vector2(_area - _speed * delta, 0)
	
	if _type == "BOOMERANG":
		$Sprite.rotate(-0.3)
	
	if _type == "HOMING":
		# Calculate close
		var min_distance = 999999999
		var target_index = -1
		var enemies = colliding_enemies.values()
		for i in range(len(enemies)):
			var enemy = enemies[i]
			if area_exceptions.has(enemy._obj_id):
				continue
			var distance = global_position.distance_to(enemy.global_position)
			if distance < min_distance:
				min_distance = distance
				target_index = i
		if target_index != -1:
			_target = enemies[target_index]
		else:
			_target = null
		
		if _target != null:
			self.look_at(_target.global_position)
			global_position += transform.x * delta * _speed
		else:
			global_position += transform.x * delta * _speed
			_targetless_timer += delta
			if (_targetless_timer >= 1):
				queue_free()
	
	if _age >= _max_age:
		queue_free()
	
func _physics_process(delta):
	delta *= game_manager.speed
	if _type != "HOMING":
		self.position += self.transform.x * _speed * delta
	if _type == "BOOMERANG":
		_speed -= delta*200

func _on_ProjectileInstance_area_entered(area):
	if _pierce > 0 and area.has_method("_take_damage"):
		var enemy_instance = area.get_parent()
		if not area_exceptions.has(enemy_instance._obj_id):
			area._take_damage(_damage)
			_pierce -= 1
			area_exceptions[enemy_instance._obj_id] = enemy_instance
	
	if _pierce <= 0:
		queue_free()


func _on_Homing_area_entered(col_area):
	if col_area.has_method("_take_damage"):
		var enemy_instance = col_area.get_parent()
		colliding_enemies[enemy_instance._obj_id] = enemy_instance


func _on_Homing_area_exited(col_area):
	if col_area.has_method("_take_damage"):
		var enemy_instance = col_area.get_parent()
		colliding_enemies.erase(enemy_instance._obj_id)
