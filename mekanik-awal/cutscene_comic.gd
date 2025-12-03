extends Control

@export var pages: Array[Texture2D]           
@export var placeholder_page_count: int = 3   
@export var next_scene_path: String = "res://main.tscn"

@onready var page_texture: TextureRect = $Page
@onready var placeholder_label: Label = $PlaceholderLabel
@onready var next_pressed: AudioStreamPlayer = $Next_Pressed


var current_page: int = 0
var total_pages: int = 0
var use_placeholders: bool = false


func _ready() -> void:
	if pages.is_empty():
		use_placeholders = true
		total_pages = placeholder_page_count
		print("CutsceneComic: using PLACEHOLDER pages x", total_pages)
	else:
		use_placeholders = false
		total_pages = pages.size()
		print("CutsceneComic: using REAL pages x", total_pages)

	current_page = 0
	_show_current_page()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		next_pressed.play()
		_next_page()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			Transition.change_scene_to_file(next_scene_path)


func _show_current_page() -> void:
	if use_placeholders:
		page_texture.texture = null
		if placeholder_label:
			placeholder_label.text = "Story 1 - Page %d / %d\n(placeholder)" % [
				current_page + 1, total_pages
			]
			placeholder_label.show()
	else:
		if current_page >= 0 and current_page < pages.size():
			page_texture.texture = pages[current_page]
		if placeholder_label:
			placeholder_label.hide()


func _next_page() -> void:
	current_page += 1

	if current_page >= total_pages:
		Transition.change_scene_to_file(next_scene_path)
	else:
		_show_current_page()
