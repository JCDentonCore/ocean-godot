extends Node3D

const TILE_COUNT := 24
const TILE_SIZE := 2.0
const OCEAN_SIZE := TILE_COUNT * TILE_SIZE
const HALF := OCEAN_SIZE * 0.5
const FISH_COUNT := 110
const BUBBLE_COUNT := 90

var rng := RandomNumberGenerator.new()
var ocean_instance := MeshInstance3D.new()
var floor_instance := MeshInstance3D.new()
var ocean_positions := PackedVector3Array()
var ocean_base := PackedVector3Array()
var fishes := []
var bubbles := []
var fish_mesh := Mesh.new()
var cam: Camera3D
var _cam_yaw := 0.0
var _cam_pitch := -0.55

func _ready() -> void:
	rng.randomize()
	_add_camera_and_lights()
	_build_ocean_mesh()
	_build_sea_floor()
	_build_fish_mesh()
	_spawn_fishes()
	_spawn_bubbles()

func _process(delta: float) -> void:
	_animate_ocean(delta)
	_animate_fishes(delta)
	_animate_bubbles(delta)
	_update_camera(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_F12:
				_save_screenshot()
			elif k.keycode == KEY_ESCAPE:
				get_tree().quit()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var m := event as InputEventMouseMotion
		_cam_yaw -= m.relative.x * 0.003
		_cam_pitch = clampf(_cam_pitch - m.relative.y * 0.003, -1.5, 1.5)

func _save_screenshot() -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://ocean_screenshot.png")
	print("Screenshot saved: ", ProjectSettings.globalize_path("user://ocean_screenshot.png"))

func _update_camera(delta: float) -> void:
	var speed := 18.0 if Input.is_key_pressed(KEY_SHIFT) else 8.0
	var fwd := -cam.basis.z
	var right := cam.basis.x
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move += fwd
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move -= fwd
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move += right
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move -= right
	if Input.is_key_pressed(KEY_SPACE):
		move.y += 1.0
	if Input.is_key_pressed(KEY_C):
		move.y -= 1.0
	cam.position += move * speed * delta
	cam.rotation = Vector3(_cam_pitch, _cam_yaw, 0.0)

func _add_camera_and_lights() -> void:
	cam = Camera3D.new()
	cam.position = Vector3(0.0, 12.0, HALF * 1.5)
	_cam_pitch = -0.55
	cam.rotation = Vector3(_cam_pitch, 0.0, 0.0)
	cam.current = true
	cam.name = "Camera3D"
	add_child(cam)
	
	var dir_light := DirectionalLight3D.new()
	dir_light.rotation = Vector3(-0.9, -0.5, 0.0)
	dir_light.light_color = Color(0.9, 0.95, 1.0)
	dir_light.light_energy = 1.4
	dir_light.shadow_enabled = true
	dir_light.name = "Sun"
	add_child(dir_light)
	
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.4, 0.55)
	env.ambient_light_energy = 0.8
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.05, 0.1)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world_env.name = "WorldEnvironment"
	add_child(world_env)

func _build_ocean_mesh() -> void:
	ocean_positions = PackedVector3Array()
	ocean_base = PackedVector3Array()
	for x in TILE_COUNT:
		for z in TILE_COUNT:
			var px := float(x) * TILE_SIZE - HALF
			var pz := float(z) * TILE_SIZE - HALF
			ocean_positions.append(Vector3(px, 0.0, pz))
			ocean_base.append(Vector3(px, 0.0, pz))
	ocean_instance = _create_mesh_instance(
		_grid_mesh(ocean_positions, Color(0.05, 0.35, 0.6, 0.85)),
		Color(0.05, 0.35, 0.6, 0.85)
	)
	ocean_instance.name = "Ocean"
	add_child(ocean_instance)

func _build_sea_floor() -> void:
	var positions := PackedVector3Array()
	for x in TILE_COUNT:
		for z in TILE_COUNT:
			var px := float(x) * TILE_SIZE - HALF
			var pz := float(z) * TILE_SIZE - HALF
			positions.append(Vector3(px, -4.0, pz))
	floor_instance = _create_mesh_instance(
		_grid_mesh(positions, Color(0.85, 0.75, 0.5)),
		Color(0.85, 0.75, 0.5)
	)
	floor_instance.name = "SeaFloor"
	add_child(floor_instance)

func _build_fish_mesh() -> void:
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var center := Vector3.ZERO
	var body_radius := 0.18
	for i in 12:
		var angle := TAU * float(i) / 12.0
		positions.append(center + Vector3(cos(angle) * body_radius, 0.0, 0.0))
		normals.append(Vector3(1, 0, 0))
		positions.append(center + Vector3(0.0, cos(angle) * body_radius, sin(angle) * body_radius))
		normals.append(Vector3(0, 0, 1))
	for i in 12:
		var a := TAU * float(i) / 12.0
		var b := TAU * float((i + 1) % 12) / 12.0
		positions.append(Vector3(-0.32, 0.0, 0.0))
		normals.append(Vector3(-1, 0, 0))
		positions.append(center + Vector3(0.0, 0.0, sin(a) * body_radius * 0.85))
		normals.append(Vector3(0, 0, 1))
		positions.append(center + Vector3(0.0, 0.0, sin(b) * body_radius * 0.85))
		normals.append(Vector3(0, 0, 1))
	fish_mesh = _array_mesh(positions, normals, _fish_indices())
	fish_mesh.surface_set_material(0, _standard_material(Color(1.0, 0.55, 0.18)))

func _spawn_fishes() -> void:
	for i in FISH_COUNT:
		var fish := Node3D.new()
		var body := MeshInstance3D.new()
		body.mesh = fish_mesh
		var scale := rng.randf_range(0.6, 1.6)
		body.scale = Vector3(scale, scale, scale)
		fish.add_child(body)
		fish.position = Vector3(
			rng.randf_range(-HALF * 0.85, HALF * 0.85),
			rng.randf_range(-3.0, 1.5),
			rng.randf_range(-HALF * 0.85, HALF * 0.85)
		)
		fish.rotation.y = rng.randf_range(0.0, TAU)
		add_child(fish)
		fishes.append({
			"node": fish,
			"speed": rng.randf_range(1.2, 3.2) * scale,
			"turn": rng.randf_range(0.4, 1.2),
			"bob": rng.randf_range(0.0, TAU)
		})

func _spawn_bubbles() -> void:
	for i in BUBBLE_COUNT:
		var bubble := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(0.02, 0.08)
		sphere.height = sphere.radius * 2.0
		bubble.mesh = sphere
		bubble.material_override = _standard_material(Color(0.75, 0.92, 1.0, 0.65))
		bubble.position = Vector3(
			rng.randf_range(-HALF * 0.85, HALF * 0.85),
			rng.randf_range(-4.0, 1.5),
			rng.randf_range(-HALF * 0.85, HALF * 0.85)
		)
		add_child(bubble)
		bubbles.append({
			"node": bubble,
			"speed": rng.randf_range(0.4, 1.4),
			"wobble": rng.randf_range(0.0, TAU)
		})

func _animate_ocean(delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	for i in ocean_positions.size():
		var bx: float = ocean_base[i].x
		var bz: float = ocean_base[i].z
		ocean_positions[i] = Vector3(
			bx,
			sin(bx * 0.35 + time * 1.3) * 0.22 + cos(bz * 0.31 + time) * 0.22,
			bz
		)
	ocean_instance.mesh = _grid_mesh(ocean_positions, Color(0.05, 0.35, 0.6, 0.85))

# --- animation ---

func _animate_fishes(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for fish in fishes:
		var node: Node3D = fish["node"]
		var speed: float = fish["speed"]
		var turn: float = fish["turn"]
		var bob: float = fish["bob"]
		node.rotation.y += turn * delta * 0.6 * sin(t * 0.9 + bob)
		node.position += node.basis.z * speed * delta
		node.position.y = clampf(node.position.y + sin(t * 2.0 + bob) * 0.15 * delta, -3.6, 1.2)
		if absf(node.position.x) > HALF * 0.9:
			node.position.x = -signf(node.position.x) * HALF * 0.85
		if absf(node.position.z) > HALF * 0.9:
			node.position.z = -signf(node.position.z) * HALF * 0.85

func _animate_bubbles(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for bubble in bubbles:
		var node: Node3D = bubble["node"]
		var speed: float = bubble["speed"]
		var wobble: float = bubble["wobble"]
		node.position.y += speed * delta
		node.position.x += sin(t * 2.0 + wobble) * 0.12 * delta
		if node.position.y > 2.0:
			node.position.y = -4.0
			node.position.x = rng.randf_range(-HALF * 0.85, HALF * 0.85)
			node.position.z = rng.randf_range(-HALF * 0.85, HALF * 0.85)

# --- Mesh builders (official ArrayMesh pattern) ---

func _grid_mesh(positions: PackedVector3Array, color: Color) -> Mesh:
	var verts := positions
	var normals := PackedVector3Array()
	for i in positions.size():
		normals.append(Vector3.UP)
	var uvs := PackedVector2Array()
	for z in TILE_COUNT:
		for x in TILE_COUNT:
			uvs.append(Vector2(float(x), float(z)))
	var indices := PackedInt32Array()
	for z in TILE_COUNT - 1:
		for x in TILE_COUNT - 1:
			var i00 := z * TILE_COUNT + x
			var i10 := i00 + 1
			var i01 := i00 + TILE_COUNT
			var i11 := i01 + 1
			indices.append(i00)
			indices.append(i11)
			indices.append(i10)
			indices.append(i00)
			indices.append(i01)
			indices.append(i11)
	var surface_array := []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_INDEX] = indices
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	am.surface_set_material(0, _standard_material(color))
	return am

func _array_mesh(positions: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	var surface_array := []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = positions
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	return am

func _fish_indices() -> PackedInt32Array:
	var indices := PackedInt32Array()
	for i in 12:
		indices.append(i)
		indices.append(i + 12)
		indices.append(i + 1)
		indices.append(i + 12)
		indices.append(i + 12 + 1)
		indices.append(i + 1)
	for i in 12:
		var idx_a := 24 + i
		var idx_b := 24 + ((i + 1) % 12)
		indices.append(idx_a)
		indices.append(idx_b)
		indices.append(idx_a + 1)
		indices.append(idx_b)
		indices.append(idx_b + 1)
		indices.append(idx_a + 1)
	return indices

func _create_mesh_instance(mesh: Mesh, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _standard_material(color)
	return instance

func _standard_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 0.55
	mat.metallic = 0.05
	return mat
