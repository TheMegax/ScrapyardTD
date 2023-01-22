extends CenterContainer

onready var game_manager = get_tree().current_scene.get_node("GameManager")
onready var held_tower_sprite = get_tree().current_scene.get_node("Cursor/HeldTower")
onready var cursor_sprite = get_tree().current_scene.get_node("Cursor/Sprite")
var tower
var price
var tower_name
var tower_texture

func _ready():
	tower_name = game_manager.TOWERS.keys()[tower].capitalize()
	var file_dir = "res://Towers/" + tower_name + "Icon.png"
	$TowerImage.texture = load(file_dir)
	tower_texture = file_dir

	self.get_parent().get_node("TowerTitle").text = tower_name
	self.get_parent().get_node("TowerPrice").text = "$" + str(price)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			if not game_manager.pause:
				game_manager.held_tower = tower
				if tower_texture != null:
					held_tower_sprite.texture = load("res://Towers/" + tower_name + "Icon.png")


func _on_CenterContainer_mouse_entered():
	cursor_sprite.texture = load("res://Mouse/mouse_point.png")


func _on_CenterContainer_mouse_exited():
	cursor_sprite.texture = load("res://Mouse/mouse_normal.png")
