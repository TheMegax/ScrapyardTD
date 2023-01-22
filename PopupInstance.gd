extends Node2D

var _text
var _speed = 1
onready var _tween = self.get_node("Tween")
onready var game_manager = get_tree().current_scene.get_node("GameManager")

func _ready():
	$Text.text = _text
	var _from = self.global_position + Vector2(0, -20)
	var _target = self.global_position + Vector2(0, -50)
	moveToTarget(_target, _from, _speed)

func _process(delta):
	delta *= game_manager.speed
	_tween.playback_speed = game_manager.speed
	
	var alpha = modulate.a - delta*2
	alpha = clamp(alpha, 0, 1)
	modulate.a = alpha
	
	if alpha == 0:
		queue_free()

func moveToTarget(end, start, speed):
	_tween.interpolate_property(self, "global_position",
		start, end, speed,
		Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tween.start()
