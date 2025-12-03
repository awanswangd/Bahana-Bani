extends Control
@export var display_time: float = 4.0 
@export var next_scene: String = "res://MainMenu/main_menu.tscn"

func _ready():
	await get_tree().create_timer(display_time).timeout
	
	Transition.change_scene_to_file(next_scene)

func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		Transition.change_scene_to_file(next_scene)
