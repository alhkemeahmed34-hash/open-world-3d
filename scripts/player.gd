extends CharacterBody3D

@export var move_speed: float = 6.0
@export var acceleration: float = 18.0
@export var jump_velocity: float = 5.0
@onready var spring_arm: SpringArm3D = $SpringArm3D

var look_touch_id: int = -1
var last_touch_position: Vector2 = Vector2.ZERO
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.42:
            look_touch_id = event.index
            last_touch_position = event.position
        elif not event.pressed and event.index == look_touch_id:
            look_touch_id = -1
    elif event is InputEventScreenDrag and event.index == look_touch_id:
        var delta := event.position - last_touch_position
        rotation.y -= delta.x * 0.006
        spring_arm.rotation.x = clampf(spring_arm.rotation.x - delta.y * 0.004, -0.75, 0.35)
        last_touch_position = event.position
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        rotation.y -= event.relative.x * 0.006
        spring_arm.rotation.x = clampf(spring_arm.rotation.x - event.relative.y * 0.004, -0.75, 0.35)

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity

    var input_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (global_transform.basis * Vector3(input_2d.x, 0.0, input_2d.y)).normalized()
    var target_x := direction.x * move_speed
    var target_z := direction.z * move_speed
    velocity.x = move_toward(velocity.x, target_x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target_z, acceleration * delta)
    move_and_slide()
