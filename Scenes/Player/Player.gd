extends RigidBody2D

export var max_speed : float = 400.0

export var max_health : int = 100
var health : int = max_health


func _init():
	game.player = self

func _ready() -> void:
	call_deferred("deferred_ready")

func deferred_ready() -> void:
#	if game.black_hole:
#		accel_radius = game.black_hole.accel_radius
	$CanvasLayer/UI.show()

#warning-ignore:unused_argument
func _process(delta) -> void:
	pass # physics moved into bullet engine


func die():
	# change this to spawn the lose screen
	game.main.lose()

func _on_draggable_dropped(velocity):
	linear_velocity += -velocity/4.0
	clamp_linear_velocity()

func clamp_linear_velocity():
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func _on_hit(damage):
	health -= damage
	if health <= 0:
		die()