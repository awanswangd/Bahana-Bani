extends Control

@onready var container = $CenterContainer/VBoxContainer
@onready var back_button = $BackButton

var main_menu_scene = "res://MainMenu/main_menu.tscn"

func _ready():
	var scores = GameData.scores
	var insert_position = 1 
	
	for i in range(scores.size()):
		var score_val = scores[i]
		
		var lbl = Label.new()
		lbl.text = "%d.  %d" % [i + 1, score_val] 
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		lbl.add_theme_font_size_override("font_size", 32)
		
		if i == 0: 
			lbl.modulate = Color.GOLD
		
		container.add_child(lbl)
		container.move_child(lbl, insert_position)
		insert_position += 1
		
	back_button.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed():
	Transition.change_scene_to_file(main_menu_scene)
