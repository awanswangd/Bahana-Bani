extends Node2D

@export var blue: Color = Color("#4682b4")
@export var green: Color = Color("#FFFFFF")
@export var red: Color = Color("#FFFFFF")
@export var is_dead: bool = false
@export var speed: float = 2.0
@export var shoot_offset: Vector2 = Vector2(-40, 0)
@export var stop_x: float = 980.0

@onready var prompt: RichTextLabel = $RichTextLabel
@onready var shoot_timer: Timer = $ShootTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_targeted: bool = false
var is_shooting: bool = false 
var has_arrived: bool = false 

func _ready() -> void:
	add_to_group("enemy")
	
	if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	
	if sprite.sprite_frames.has_animation("shoot"):
		sprite.sprite_frames.set_animation_loop("shoot", false)
	
	if sprite.sprite_frames.has_animation("idle"):
		sprite.sprite_frames.set_animation_loop("idle", true)
		
	shoot_timer.wait_time = 2.0
	shoot_timer.one_shot = false
	shoot_timer.start()

func _physics_process(delta: float) -> void:
	if is_dead or is_shooting:
		return

	var final_speed := speed
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("get_enemy_speed_multiplier"):
		final_speed *= main.get_enemy_speed_multiplier()

	if global_position.x > stop_x:
		global_position.x -= final_speed
		has_arrived = false
		if sprite.animation != "flight":
			sprite.play("flight")
	else:
		global_position.x = stop_x
		has_arrived = true
		
		if sprite.animation != "idle":
			sprite.play("idle")

func _on_shoot_timer_timeout() -> void:
	if is_dead or is_shooting or not has_arrived:
		return
	
	tembak_panah()

func tembak_panah() -> void:
	is_shooting = true 
	
	sprite.play("shoot")
	await sprite.animation_finished
	
	if not is_dead:
		var main = get_tree().get_first_node_in_group("main")
		if main and main.has_method("spawn_projectile_at"):
			main.spawn_projectile_at(global_position + shoot_offset)
		
		sprite.play("idle")
	
	is_shooting = false 

func set_targeted(value: bool) -> void:
	is_targeted = value
	if sprite.material:
		if value:
			sprite.material.set_shader_parameter("line_thickness", 10.0)
		else:
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

func die():
	is_dead = true
	shoot_timer.stop()
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	var main = get_tree().get_first_node_in_group("main")
	if main and main.active_enemy == self:
		main.reset_active_enemy()
	queue_free()
