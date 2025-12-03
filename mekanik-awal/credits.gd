extends Control

@export var display_time: float = 2.0  
@export var fade_time: float = 0.5
@export var next_scene: String = "res://MainMenu/main_menu.tscn"
@onready var role_label = $CenterContainer/VBoxContainer/RoleLabel
@onready var name_label = $CenterContainer/VBoxContainer/NameLabel
@onready var content_box = $CenterContainer/VBoxContainer

var credits_data = [
	{ "role": "DIRECTED BY", "name": "RANDI" },
	{ "role": "ARTIST DESIGNER", "name": "HAFIZ" },
	{ "role": "ARTIST DESIGNER", "name": "THEYO" },
	{ "role": "ARTIST DESIGNER", "name": "RYON.YON" },
	{ "role": "GAMEPLAY PROGRAMMER", "name": "JORDY" },
	{ "role": "SOUND ENGINEER", "name": "ALBI" },
	{ "role": "SPECIAL THANKS", "name": "THEYO & RYON.YON" },
	{ "role": " ", "name": "TO BE CONTINUE" }
]

var credits_theme = load("res://audio/bgm/credits_theme.ogg")

func _ready():
	content_box.modulate.a = 0.0
	play_credits_sequence()
	SoundManager.play_music(credits_theme)

func play_credits_sequence():
	for data in credits_data:
		role_label.text = data["role"]
		name_label.text = data["name"]
		var tween_in = create_tween()
		tween_in.tween_property(content_box, "modulate:a", 1.0, fade_time)
		await tween_in.finished
		await get_tree().create_timer(display_time).timeout
		var tween_out = create_tween()
		tween_out.tween_property(content_box, "modulate:a", 0.0, fade_time)
		await tween_out.finished
		await get_tree().create_timer(0.3).timeout
	finish_credits()

func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		finish_credits()

func finish_credits():
	Transition.change_scene_to_file(next_scene)
	SoundManager.stop_music()
