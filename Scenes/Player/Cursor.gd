"""
Cursor is a targeting reticle which follows the mouse.
It's used to detect mouse-over type events using collision signals

It also has a Path2D which should always go between the cursor position and the player position.
Creatures which latch onto the line can follow the PathFollow2D node.

"""

extends Area2D

#var mouse_over_node : Node2D = null
var object_hooked : Node2D = null

export var max_range : float = 1500.0

enum states { IDLE, HOOKED }
var state = states.IDLE

var time_elapsed : float = 0.0

func _init() -> void:
	game.cursor = self

func _ready() ->void:
	if OS.get_name() == "Android":
		$Sprite.hide()
		$AndroidSprite.show()
	else:
		$Sprite.show()
		$AndroidSprite.hide()

#warning-ignore:unused_argument
func _process(delta : float) -> void:
	time_elapsed += delta
	game.score["Time_Elapsed"] = time_elapsed
	follow_mouse(delta)
	unhook_freed_nodes()
	update() # calls _draw()


func follow_mouse(delta : float):
	var my_pos : Vector2 = get_global_position()
	var mouse_pos : Vector2 = get_global_mouse_position()
	var player_pos : Vector2 = game.player.get_transform().origin

	if player_pos.distance_squared_to(mouse_pos) <= max_range * max_range:
		set_global_position(lerp(my_pos, mouse_pos, 0.8))
	else:
		var vector_to_cursor = (mouse_pos - player_pos).normalized() * max_range
		set_global_position(lerp(my_pos, player_pos + vector_to_cursor, 0.8))


func unhook_freed_nodes() -> void:
	if object_hooked != null and is_instance_valid(object_hooked) == false:
		object_hooked = null
		if state == states.HOOKED:
			state = states.IDLE
			$RayGunNoise.stop()

#warning-ignore:unused_argument
func _input(event : InputEvent) -> void:
	# any way to figure out if OS is windows or android?
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		touch_input(event)
	else:
		desktop_input(event)

func touch_input(event) -> void:
	# Let's change how it works..
		# mouse over autograbs
		# if the mouse passes a certain range, it autoflings
		# then, no mouse-clicks will be required
		# we might need a stunlock on the draggable objects, so they don't get grabbed right after flinging.



	"""
	There's a bug: on mobile device, single tap doesn't grab the object. Need to double-tap to grab objects.
	I don't know why.
	"""
	if state == states.IDLE:
		if event is InputEventScreenTouch and event.is_pressed():

			# VVVV Maybe the problem was the cursor lagging behind in the previous location?
			#follow_mouse(1.0)
			# ^^^^ I thought this would solve the double-tap problem, but it doesn't

			var potential_bodies : Array = get_overlapping_bodies()
			potential_bodies.erase(game.player)
			if potential_bodies.size() > 0:
				grab(potential_bodies)
			else:
				var potential_areas = get_overlapping_areas()
				if potential_areas.size() > 0:
					grab(potential_areas)

	elif state == states.HOOKED and object_hooked != null:
		if event is InputEventScreenTouch and event.is_pressed() == false:
			drop(object_hooked)

	# consider using InputEventScreenDrag to set the drag velocity. It's probably better than grabbing the delta of the final frame before release

func desktop_input(event) -> void:
	if state == states.IDLE:
		if Input.is_action_pressed("BUTTON_LEFT"):
			var potential_bodies : Array = get_overlapping_bodies()
			potential_bodies.erase(game.player)
			if potential_bodies.size() > 0:
				grab(potential_bodies)
			else:
				var potential_areas = get_overlapping_areas()
				if potential_areas.size() > 0:
					grab(potential_areas)

	elif state == states.HOOKED and object_hooked != null:
		if Input.is_action_just_released("BUTTON_LEFT"):
			drop(object_hooked)

func grab(potential_objects : Array):
	for object in potential_objects:
		if object.has_method("pickup"):
			object.pickup()
			state = states.HOOKED
			object_hooked = object
			$RayGunNoise.play()
			return object
	return null

func drop(object : Object):
	$RayGunNoise.stop()
	if is_instance_valid(object):
		if object.has_method("drop"):
			object.drop()
		object_hooked = null
		state = states.IDLE

func _draw() -> void:
	# draw a line between the player and the targeting reticle
	if object_hooked != null and Input.is_action_pressed("BUTTON_LEFT"):
		draw_tether()

func draw_tether():
	var my_pos : Vector2 = to_local(get_global_position())
	var player_pos : Vector2 = to_local(game.player.get_global_position())
	var vector_to_cursor : Vector2 = my_pos - player_pos
	var tangent_vector : Vector2 = vector_to_cursor.normalized().rotated(PI / 2)

	var distance : float = vector_to_cursor.length()
	var num_segments : float = distance / 5.0
	var amplitude : float = 30
	var frequency : float = 0.2
	var speed : float = 100.0
	var wave_points : Array = []
	#warning-ignore:unused_variable
	for i in range(num_segments):
		var base_distance : float = distance / num_segments * i
		var base_location : Vector2 = vector_to_cursor/num_segments * i
		var location : Vector2 = player_pos + base_location + (tangent_vector * \
				sin( (time_elapsed * speed + base_distance) * frequency) * \
				amplitude * (1 - base_distance / distance))
		wave_points.push_back(location)

	var width : float = 3.0
	var antialias : bool = true
	var i : int = 0
	var last_pos : Vector2 = player_pos
	for point in wave_points:
		draw_line(last_pos, point, Color.blueviolet, width, antialias)
		last_pos = point
	draw_line(my_pos, player_pos, Color.antiquewhite, width, antialias)

func _on_creature_escaped() -> void:
	object_hooked = null