extends CanvasLayer
@onready var anim = $AnimationPlayer

func change_scene_to_file(target: String) -> void:
	anim.play('Dissolve')
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(target)
	anim.play_backwards('Dissolve')
