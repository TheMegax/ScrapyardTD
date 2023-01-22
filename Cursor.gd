extends Node2D

onready var game_manager = self.get_parent().get_node("GameManager")
onready var held_tower_sprite = self.get_node("HeldTower")
onready var held_tower_area = self.get_node("HeldTowerArea")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(_delta):
	self.position = get_viewport().get_mouse_position()
	if game_manager.held_tower != null:
		if Input.is_action_just_released("left_click"):
			game_manager._try_place_tower(self.position)
			game_manager.held_tower = null
			held_tower_sprite.texture = null
			held_tower_area.update()
	held_tower_area.update()

