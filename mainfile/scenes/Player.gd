extends CharacterBody2D

# Player Stat
var max_health: int = 100
var current_health: int = max_health

# Movement parameters
const speed =50.0
const jump_height = -400.0
const slide_speed_multiplier = 5
const slide_duration = 0.2

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_sliding = false
var slide_timer = 0.0
var facing_right = true  # To track which direction player is facing

@onready var animated_sprite = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
# func _ready() -> void:
	 # Start with the idle animation (Animasi character idle)
#	animated_sprite.play("Idle")
	
	# Animasi lain yang belum ada:
	# - "Run" - for moving left/right
	# - "Jump" - for jumping
	# - "Slide" - for sliding
	# Floor baru placeholder, nanti diganti pake asset

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_height
		#animated_sprite.play("Jump")

	# Handle slide
	if Input.is_action_just_pressed("slide") and is_on_floor() and not is_sliding:
		start_slide()

	# Update slide state if active
	if is_sliding:
		slide_timer += delta
		if slide_timer >= slide_duration:
			end_slide()
		
		# During slide, maintain horizontal momentum but allow for some control
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * speed * slide_speed_multiplier
			
	# Normal movement (when not sliding)
	else:
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * speed
			#animated_sprite.play("Run")
			
			# Flip sprite based on direction
			if direction > 0:
				animated_sprite.flip_h = false
				facing_right = true
			else:
				animated_sprite.flip_h = true
				facing_right = false
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			if is_on_floor():
				animated_sprite.play("Idle")

	# Apply the calculated velocity
	move_and_slide()

func start_slide():
	is_sliding = true
	slide_timer = 0.0
	#animated_sprite.play("Slide")
	
	# Optional: you might want to change the collision shape during slide
	# to make it shorter/wider
	$CollisionShape2D.scale.y = 0.5  # Make the collision shape half as tall
	$CollisionShape2D.position.y += 3  # Adjust position to account for lower height

func end_slide():
	is_sliding = false
	
	# Reset collision shape if you modified it
	$CollisionShape2D.scale.y = 1.0
	$CollisionShape2D.position.y -= 3  # Reset the position adjustment
