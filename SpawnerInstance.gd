extends Node2D

onready var game_manager = self.get_parent()
onready var map_path = game_manager.get_parent().get_node("MapPath")

var _intervalseconds = 0.5
var _quantity = 1
var _obj_id
var _variation = 8
onready var ENEMIES = game_manager.ENEMIES
onready var _type

var timer = 0

func _process(delta):
	# Weak spawning routine
	delta *= game_manager.speed
	timer += delta
	var loops = floor(timer / _intervalseconds)
	timer -= loops*_intervalseconds
	
	for _i in range(loops):
		var enemy_instance = preload("res://EnemyInstance.tscn").instance()
		
		enemy_instance._type = _type
		enemy_instance._obj_id = game_manager.object_count
		game_manager.object_count += 1
		enemy_instance.h_offset = rand_range(-_variation,_variation)
		enemy_instance.v_offset = rand_range(-_variation,_variation)
		match _type:
			ENEMIES.TROOPER:
				enemy_instance._health = 20 * game_manager._health_mod
				enemy_instance._damage = 2
				enemy_instance._speed = 60
				enemy_instance._scrap = 3
			ENEMIES.SWARMER:
				enemy_instance._health = 7 * game_manager._health_mod
				enemy_instance._damage = 1
				enemy_instance._speed = 100
				enemy_instance._scrap = 1
			ENEMIES.HELI:
				enemy_instance._health = 40 * game_manager._health_mod
				enemy_instance._damage = 3
				enemy_instance._speed = 100
				enemy_instance._scrap = 5
			ENEMIES.BULKY:
				enemy_instance._health = 100 * game_manager._health_mod
				enemy_instance._damage = 10
				enemy_instance._speed = 50
				enemy_instance._scrap = 10
			ENEMIES.JET:
				enemy_instance._health = 50 * game_manager._health_mod
				enemy_instance._damage = 4
				enemy_instance._speed = 140
				enemy_instance._scrap = 12
			ENEMIES.DUPPER:
				enemy_instance._health = 400 * game_manager._health_mod
				enemy_instance._damage = 20
				enemy_instance._speed = 40
				enemy_instance._scrap = 15
			ENEMIES.BOSS:
				enemy_instance._health = 2000 * game_manager._health_mod
				enemy_instance._damage = 50
				enemy_instance._speed = 30
				enemy_instance._scrap = 1000
		
		map_path.add_child(enemy_instance)
		game_manager.enemy_count += 1
		_quantity -= 1
		if (_quantity <= 0):
			game_manager.spawner_count -= 1
			queue_free()
