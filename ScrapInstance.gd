extends Node2D

var _value
var _from
var _target
var _speed
var _range = 40
var _collection_radius = 80
var _collection_speed = 200

onready var _tween = self.get_node("Tween")
onready var game_manager = get_tree().current_scene.get_node("GameManager")

func _ready():
	$Sprite.texture = load("res://Gui/Scrap" + str(randi() % 3 + 2) + ".png")
	rotation_degrees = rand_range(0, 360)
	_from = self.position
	_target = self.position + Vector2(rand_range(-_range, _range), rand_range(-_range, _range))
	moveToTarget(_target, _from, _speed)

func _process(delta):
	delta *= game_manager.speed
	_tween.playback_speed = game_manager.speed
	var mouse_pos = get_viewport().get_mouse_position()
	var distance = global_position.distance_to(mouse_pos)
	if distance < _collection_radius:
		_tween.stop_all()
		var prev_rotation = self.rotation
		self.look_at(mouse_pos)
		global_position += transform.x * delta * _collection_speed
		self.rotation = prev_rotation
		if distance <= (_collection_speed * delta)*3:
			game_manager._scraps += _value
			var popup_instance = preload("res://PopupInstance.tscn").instance()
			popup_instance._text = "+" + str(_value)
			popup_instance.global_position = mouse_pos
			game_manager.add_child(popup_instance)
			queue_free()
	
func moveToTarget(end, start, speed):
	_tween.interpolate_property(self, "position",
		start, end, speed,
		Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tween.start()
