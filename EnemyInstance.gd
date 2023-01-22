extends PathFollow2D

onready var game_manager = get_tree().current_scene.get_node("GameManager")
onready var enemy_collision = self.get_node("Area2D/EnemyCollision")
onready var health_bar = self.get_node("Area2D/Layer/HealthBar")
onready var enemy_sprite = self.get_node("Area2D/EnemySprite")
onready var ENEMIES = game_manager.ENEMIES

var _speed
var _max_health
var _health
var _damage
var _scrap
var _type
var _area = 10
var _obj_id

func _ready():
	enemy_collision.shape.radius = _area
	_max_health = _health
	
	match _type:
		ENEMIES.TROOPER:
			enemy_sprite.animation = "TROOPER"
		ENEMIES.SWARMER:
			enemy_sprite.animation = "SWARMER"
		ENEMIES.HELI:
			enemy_sprite.animation = "HELI"
		ENEMIES.BULKY:
			enemy_sprite.animation = "BULKY"
		ENEMIES.JET:
			enemy_sprite.animation = "JET"
		ENEMIES.DUPPER:
			enemy_sprite.animation = "DUPPER"
		ENEMIES.BOSS:
			enemy_sprite.animation = "BOSS"
func _process(delta):
	delta *= game_manager.speed
	self.set_offset(self.get_offset() + _speed * delta)
	if self.unit_offset == 1:
		game_manager._lives -= _damage
		queue_free()
		return
	
	enemy_sprite.speed_scale = game_manager.speed
	
	var health_percentage = (_health / _max_health)
	health_bar.value = health_percentage*100
	var pct_diff = 1.0 - health_percentage
	var red_color = min(255, pct_diff*2 * 255)
	var green_color = min(255, health_percentage*2 * 255)
	var col = Color8(red_color, green_color, 0)
	health_bar.tint_progress = col
	
	if health_percentage <= 0:
		var scrap_instance = preload("res://ScrapInstance.tscn").instance()
		scrap_instance._value = _scrap
		scrap_instance._speed = 0.5
		scrap_instance.position = global_position
		game_manager.add_child(scrap_instance)
		game_manager.enemy_count -= 1
		queue_free()
		return
