extends Area2D

onready var enemy_base = self.get_parent()

func _take_damage(damage):
	enemy_base._health -= damage
