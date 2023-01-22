extends CollisionShape2D

onready var tower_instance = self.get_parent()

func _draw():
	if tower_instance.is_selected:
		draw_circle(Vector2(0,0), tower_instance._area, Color8(200,200,200,65))
