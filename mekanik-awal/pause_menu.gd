extends CanvasLayer

@onready var panel = $Panel
@onready var settings_tab: Panel = $Settings_tab


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide_pause()

func show_pause() -> void:
	visible = true

func hide_pause() -> void:
	visible = false

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	hide_pause()


func _on_restart_bttn_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_settings_bttn_pressed() -> void:
	panel.visible = false
	settings_tab.visible = true

func _on_close_bttn_pressed() -> void:
	panel.visible = true
	settings_tab.visible = false

func _on_main_menu_bttn_pressed() -> void:
	get_tree().paused = false
	SoundManager.stop_music()
	Transition.change_scene_to_file("res://MainMenu/main_menu.tscn")
