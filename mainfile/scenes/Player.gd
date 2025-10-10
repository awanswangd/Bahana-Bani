extends KinematicBody2D

# Player variables
var speed = 200
var jump_speed = -400
var gravity = 1000
var slide_speed = 300

var velocity = Vector2()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    velocity.x = 0 # Reset horizontal velocity

    if Input.is_action_pressed("ui_right"):
        velocity.x += speed
    if Input.is_action_pressed("ui_left"):
        velocity.x -= speed

    if is_on_floor() and Input.is_action_just_pressed("ui_up"):
        velocity.y = jump_speed

    # Sliding functionality
    if Input.is_action_pressed("ui_down"):
        velocity.x = slide_speed * (velocity.x < 0 ? -1 : 1)

    velocity.y += gravity * delta # Apply gravity

    # Move the player
    velocity = move_and_slide(velocity, Vector2.UP)