extends Control

@onready var container = $CenterContainer/VBoxContainer
@onready var back_button = $BackButton

var main_menu_scene = "res://MainMenu/main_menu.tscn"

const COLUMNS := 3
const ROWS := 10
const FONT_SIZE := 32

func _ready():
	var scores = GameData.scores

	var grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 120)
	grid.add_theme_constant_override("v_separation", 12)

	# GridContainer mengisi per baris, jadi hitung peringkat secara manual
	# supaya urutannya turun per kolom (1-10, 11-20, 21-30)
	for row in range(ROWS):
		for col in range(COLUMNS):
			var i = col * ROWS + row
			var lbl = Label.new()
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.custom_minimum_size.x = 300
			lbl.add_theme_font_size_override("font_size", FONT_SIZE)

			if i < scores.size():
				lbl.text = "%d.  %d" % [i + 1, scores[i]]
				if i == 0:
					lbl.modulate = Color.GOLD
			else:
				lbl.text = ""  # slot kosong, layout tetap rapi

			grid.add_child(lbl)

	container.add_child(grid)
	container.move_child(grid, 1)

	back_button.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed():
	Transition.change_scene_to_file(main_menu_scene)
