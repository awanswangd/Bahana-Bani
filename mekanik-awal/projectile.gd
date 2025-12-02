extends Node2D

@export var blue: Color = Color("#4682b4")
@export var green: Color = Color("#ffffffff")
@export var red: Color = Color("#ffffffff")

@export var speed: float = 100.0 

@onready var prompt: RichTextLabel = $RichTextLabel

@onready var sprite = $Sprite2D 

var is_targeted: bool = false

func _ready() -> void:
	add_to_group("projectile")
	
	# SETUP SHADER: Duplicate material agar outline unik
	if sprite.material:
		sprite.material = sprite.material.duplicate()

func _physics_process(delta: float) -> void:
	# gerak ke kiri
	global_position.x -= speed * delta

	# optional: kalau sudah jauh banget, auto hilang
	if global_position.x < -2000:
		queue_free()

# --- FUNGSI OUTLINE (Ini yang sebelumnya hilang) ---
func set_targeted(value: bool) -> void:
	is_targeted = value
	if sprite.material:
		if value:
			# Outline nyala (tebal 10.0 atau sesuai selera)
			sprite.material.set_shader_parameter("line_thickness", 10.0)
		else:
			# Outline mati
			sprite.material.set_shader_parameter("line_thickness", 0.0)

func get_prompt() -> String:
	return prompt.text

func set_prompt(text: String) -> void:
	prompt.text = text

func set_next_character(next_character_index: int) -> void:
	var text := prompt.text

	var blue_text = get_bbcode_color_tag(blue) + text.substr(0, next_character_index) + get_bbcode_end_color_tag()
	var green_text = ""
	var red_text = ""

	if next_character_index < text.length():
		green_text = get_bbcode_color_tag(green) + text.substr(next_character_index, 1) + get_bbcode_end_color_tag()

	if next_character_index + 1 < text.length():
		red_text = get_bbcode_color_tag(red) + text.substr(next_character_index + 1) + get_bbcode_end_color_tag()

	prompt.parse_bbcode(blue_text + green_text + red_text)

func get_bbcode_color_tag(color: Color) -> String:
	return "[color=#" + color.to_html(false) + "]"

func get_bbcode_end_color_tag() -> String:
	return "[/color]"
