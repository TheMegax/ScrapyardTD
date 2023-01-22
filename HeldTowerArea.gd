extends Node2D
onready var game_manager = self.get_parent().get_parent().get_node("GameManager")

func _draw():
	if game_manager.held_tower != null:
		var _area = game_manager.tower_data.get("area")
		draw_circle(Vector2(0,0), _area, Color8(200,200,200,65))
