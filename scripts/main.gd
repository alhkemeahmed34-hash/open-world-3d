extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
var time_label: Label
var mission_label: Label
var mission_area: Area3D
var mission_stage: int = 0

func _ready() -> void:
    _create_environment()
    _create_city()
    var player = PLAYER_SCENE.instantiate()
    player.position = Vector3(0, 0.15, 10)
    player.add_to_group("player")
    add_child(player)
    _create_hud()
    _create_mission()

func _process(_delta: float) -> void:
    if is_instance_valid(time_label):
        var clock := Time.get_datetime_dict_from_system()
        time_label.text = "OPEN WORLD 3D   |   %02d:%02d" % [clock.hour, clock.minute]

func _create_environment() -> void:
    var world_env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.sky = Sky.new()
    environment.sky.sky_material = ProceduralSkyMaterial.new()
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.78, 0.88)
    environment.ambient_light_energy = 0.7
    world_env.environment = environment
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)

    var ground_body := StaticBody3D.new()
    ground_body.name = "Ground"
    var ground_mesh := MeshInstance3D.new()
    var plane := BoxMesh.new()
    plane.size = Vector3(260, 1, 260)
    ground_mesh.mesh = plane
    ground_mesh.position.y = -0.5
    var ground_mat := StandardMaterial3D.new()
    ground_mat.albedo_color = Color(0.20, 0.31, 0.23)
    ground_mesh.material_override = ground_mat
    ground_body.add_child(ground_mesh)
    var ground_collision := CollisionShape3D.new()
    var ground_shape := BoxShape3D.new()
    ground_shape.size = Vector3(260, 1, 260)
    ground_collision.shape = ground_shape
    ground_collision.position.y = -0.5
    ground_body.add_child(ground_collision)
    add_child(ground_body)

func _create_city() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 84219
    for x in range(-4, 5):
        for z in range(-4, 5):
            if abs(x) <= 1 or abs(z) <= 1:
                continue
            var height := rng.randf_range(5.0, 22.0)
            var width := rng.randf_range(7.0, 11.0)
            var depth := rng.randf_range(7.0, 11.0)
            var building := StaticBody3D.new()
            building.position = Vector3(x * 24.0, height * 0.5, z * 24.0)
            var mesh_instance := MeshInstance3D.new()
            var box := BoxMesh.new()
            box.size = Vector3(width, height, depth)
            mesh_instance.mesh = box
            var mat := StandardMaterial3D.new()
            var shade := rng.randf_range(0.25, 0.65)
            mat.albedo_color = Color(shade, shade * 1.08, shade * 1.18)
            mesh_instance.material_override = mat
            building.add_child(mesh_instance)
            var collision := CollisionShape3D.new()
            var shape := BoxShape3D.new()
            shape.size = box.size
            collision.shape = shape
            building.add_child(collision)
            add_child(building)

    _add_road(Vector3(0, 0.015, 0), Vector3(260, 0.03, 13))
    _add_road(Vector3(0, 0.02, 0), Vector3(13, 0.03, 260))
    for i in range(-3, 4):
        _add_road(Vector3(i * 48.0, 0.012, 0), Vector3(7, 0.025, 260))
        _add_road(Vector3(0, 0.013, i * 48.0), Vector3(260, 0.025, 7))

func _add_road(pos: Vector3, size: Vector3) -> void:
    var road := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    road.mesh = mesh
    road.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.075, 0.085, 0.10)
    road.material_override = mat
    add_child(road)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 14)
    panel.size = Vector2(290, 48)
    layer.add_child(panel)
    var hud_column := VBoxContainer.new()
    panel.add_child(hud_column)
    time_label = Label.new()
    time_label.text = "OPEN WORLD 3D"
    time_label.add_theme_font_size_override("font_size", 18)
    hud_column.add_child(time_label)
    mission_label = Label.new()
    mission_label.text = "المهمة: توجّه إلى نقطة التجمع"
    mission_label.add_theme_font_size_override("font_size", 15)
    hud_column.add_child(mission_label)

    _make_control_button(layer, "↑", Vector2(82, -270), "move_forward")
    _make_control_button(layer, "↓", Vector2(82, -130), "move_back")
    _make_control_button(layer, "←", Vector2(12, -200), "move_left")
    _make_control_button(layer, "→", Vector2(152, -200), "move_right")
    _make_control_button(layer, "قفز", Vector2.ZERO, "jump")

func _make_control_button(layer: CanvasLayer, caption: String, offset: Vector2, action: String) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(64, 64)
    var viewport_size := get_viewport().get_visible_rect().size
    button.position = Vector2(offset.x, viewport_size.y + offset.y)
    if action == "jump":
        button.position = Vector2(viewport_size.x - 100, viewport_size.y - 120)
    button.add_theme_font_size_override("font_size", 22)
    button.modulate = Color(1, 1, 1, 0.82)
    layer.add_child(button)
    button.button_down.connect(func(): Input.action_press(action))
    button.button_up.connect(func(): Input.action_release(action))


func _create_mission() -> void:
    mission_area = Area3D.new()
    mission_area.name = "MissionCheckpoint"
    mission_area.position = Vector3(0, 1.0, -35)
    var ring := MeshInstance3D.new()
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 1.65
    ring_mesh.outer_radius = 2.0
    ring.mesh = ring_mesh
    var ring_material := StandardMaterial3D.new()
    ring_material.albedo_color = Color(1.0, 0.72, 0.12)
    ring_material.emission_enabled = true
    ring_material.emission = Color(1.0, 0.48, 0.04)
    ring_material.emission_energy_multiplier = 1.4
    ring.material_override = ring_material
    mission_area.add_child(ring)
    var trigger := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 2.8
    trigger.shape = sphere
    mission_area.add_child(trigger)
    mission_area.body_entered.connect(_on_mission_checkpoint_entered)
    add_child(mission_area)

func _on_mission_checkpoint_entered(body: Node3D) -> void:
    if not body.is_in_group("player"):
        return
    if mission_stage == 0:
        mission_stage = 1
        mission_label.text = "أحسنت! المهمة 1 اكتملت — توجّه للنقطة التالية"
        mission_area.position = Vector3(45, 1.0, -35)
    elif mission_stage == 1:
        mission_stage = 2
        mission_label.text = "تم إنجاز المهمتين! استكشف المدينة"
        mission_area.queue_free()
