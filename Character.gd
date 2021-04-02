extends RigidBody

const JUMP_IMPULSE: float = 8.0
const MOVE_FORCE: float = 15.0

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	if Input.is_action_just_pressed("jump"):
		apply_central_impulse(Vector3(0.0, JUMP_IMPULSE, 0.0))
	var move: Vector3 = Vector3()
	move.x += Input.get_action_strength("move_right")
	move.x -= Input.get_action_strength("move_left")
	move.z += Input.get_action_strength("move_down")
	move.z -= Input.get_action_strength("move_up")
	add_central_force(move * MOVE_FORCE)
