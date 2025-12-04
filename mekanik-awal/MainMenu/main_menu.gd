extends Control

@onready var main_buttons: VBoxContainer = $Main_Buttons
@onready var settings_tab: Panel = $Settings_tab
@onready var notification: Panel = $Notification
@onready var button_pressed: AudioStreamPlayer = $Button_Pressed


func _ready():
	main_buttons.visible = true
	settings_tab.visible = false
	notification.visible = false

func _process(delta):
	pass

func _on_start_bttn_pressed() -> void:
	button_pressed.play()
	Transition.change_scene_to_file("res://cutscene_story_1.tscn")

func _on_endless_bttn_pressed() -> void:
	button_pressed.play()
	Transition.change_scene_to_file("res://main_endless.tscn")

func _on_setting_bttn_pressed() -> void:
	button_pressed.play()
	main_buttons.visible = false
	settings_tab.visible = true


func _on_exit_bttn_pressed() -> void:
	button_pressed.play()
	get_tree().quit()


func _on_close_bttn_pressed() -> void:
	button_pressed.play()
	_ready()

func _on_credits_pressed() -> void:
	button_pressed.play()
	Transition.change_scene_to_file("res://credits.tscn")

func _on_leaderboard_pressed() -> void:
	Transition.change_scene_to_file("res://leaderboard.tscn")
