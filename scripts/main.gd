extends Node2D

@export var cars_to_park: int = 10
@export var next_level_scene: String = ""
@export var spawn_position: Vector2 = Vector2(100, 100)
@export var spawn_rotation: float = 1.5708

@export_group("Environmental Overrides")
@export var friction_mult: float = 1.0
@export var drag_mult: float = 1.0
@export var wind_force: Vector2 = Vector2.ZERO
@export var ambient_type: AudioManager.AmbientType = AudioManager.AmbientType.NONE

@onready var brake_bar = $CanvasLayer/UI/BrakeBar
@onready var status_label = $CanvasLayer/UI/StatusLabel
@onready var instructions = $CanvasLayer/UI/Instructions
@onready var car_count_label = $CanvasLayer/UI/CarCountLabel
@onready var health_label = $CanvasLayer/UI/HealthLabel

var car_scene = preload("res://scenes/car.tscn")
var current_car: CharacterBody2D = null
var cars_parked_count: int = 0
var game_started: bool = false
var waiting_for_next: bool = false
var all_spots: Array = []
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
@onready var main_camera = $Camera2D if has_node("Camera2D") else null

func _ready() -> void:
	AudioManager.set_ambient(ambient_type)
	
	if not main_camera:
		main_camera = Camera2D.new()
		main_camera.position = Vector2(640, 360) # Center of screen
		add_child(main_camera)

	if has_node("ParkingSpots"):
		_find_spots_recursive($ParkingSpots)
	
	_spawn_new_car()
	_update_ui()

func _find_spots_recursive(node: Node) -> void:
	for child in node.get_children():
		if child.has_method("set_as_target"):
			all_spots.append(child)
			child.set_as_target(false)
		else:
			_find_spots_recursive(child)

func _process(delta: float) -> void:
	if main_camera and shake_timer > 0:
		shake_timer -= delta
		main_camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		if shake_timer <= 0:
			main_camera.offset = Vector2.ZERO

	if Input.is_action_just_pressed("menu"):
		AudioManager.set_ambient(AudioManager.AmbientType.NONE)
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return

	if waiting_for_next:
		if Input.is_action_just_pressed("interact"):
			if cars_parked_count >= cars_to_park:
				_load_next_level()
			else:
				_spawn_new_car()
		return

	if current_car and not game_started:
		if Input.is_action_just_pressed("interact"):
			_start_handoff()

func shake_screen(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration

func _spawn_new_car() -> void:
	waiting_for_next = false
	game_started = true
	
	# Select new unoccupied target spot
	if all_spots.size() > 0:
		for s in all_spots: s.set_as_target(false)
		
		# Filter unoccupied spots
		var available_spots = all_spots.filter(func(s): return not s.is_occupied)
		
		if available_spots.size() > 0:
			var target = available_spots.pick_random()
			target.set_as_target(true)
		else:
			print("No spots left!")
	
	current_car = car_scene.instantiate()
	current_car.position = spawn_position
	current_car.rotation = spawn_rotation
	current_car.car_type = randi() % 5
	
	add_child(current_car)
	
	# Apply Level Overrides
	current_car.friction_multiplier = friction_mult
	current_car.drag_multiplier = drag_mult
	current_car.external_force = wind_force
	
	current_car.friction_updated.connect(_on_friction_updated)
	current_car.overheated.connect(_on_overheated)
	current_car.brakes_recovered.connect(_on_brakes_recovered)
	current_car.parked_successfully.connect(_on_parked)
	current_car.crashed.connect(_on_crashed)
	current_car.health_updated.connect(_on_health_updated)
	
	# Start with player control immediately
	current_car.take_control()
	
	brake_bar.value = 100
	brake_bar.modulate = Color.WHITE
	status_label.text = "PARK IT!" # Update status immediately
	status_label.modulate = Color.WHITE
	instructions.hide() # No need for instructions
	_update_ui()

func _start_handoff() -> void:
	game_started = true
	current_car.take_control()
	status_label.text = "PARK IT!"
	instructions.hide()

func _update_ui() -> void:
	car_count_label.text = "CARS PARKED: %d / %d" % [cars_parked_count, cars_to_park]

func _on_friction_updated(current: float, max_val: float) -> void:
	brake_bar.value = (current / max_val) * 100.0

func _on_health_updated(current: int, max_val: int) -> void:
	var h_text = "CONDITION: "
	for i in range(max_val):
		h_text += "■" if i < current else "□"
	health_label.text = h_text
	health_label.modulate = Color.RED if current <= 1 else Color.WHITE

func _on_overheated(_duration: float) -> void:
	status_label.text = "BRAKES OVERHEATED!"
	brake_bar.modulate = Color.RED

func _on_brakes_recovered() -> void:
	status_label.text = "BRAKES RECOVERED"
	brake_bar.modulate = Color.WHITE

func _on_parked() -> void:
	cars_parked_count += 1
	status_label.text = "PARKED!"
	status_label.modulate = Color.GREEN
	waiting_for_next = true
	_update_ui()
	
	if cars_parked_count >= cars_to_park:
		instructions.text = "LEVEL COMPLETE!\nPRESS [E] FOR NEXT LEVEL"
	else:
		instructions.text = "WELL DONE!\nPRESS [E] FOR NEXT CAR"
	instructions.show()

func _on_crashed() -> void:
	status_label.text = "TOTALED! RESTARTING..."
	status_label.modulate = Color.RED
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func _load_next_level() -> void:
	if next_level_scene != "":
		get_tree().change_scene_to_file(next_level_scene)
	else:
		status_label.text = "ALL LEVELS COMPLETE!"
