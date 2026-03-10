extends Node2D

@export var cars_to_park: int = 10
@export var next_level_scene: String = ""
@export var spawn_position: Vector2 = Vector2(150, 150)
@export var spawn_rotation: float = 1.5708

@export_group("Environmental Overrides")
@export var friction_mult: float = 1.0
@export var drag_mult: float = 1.0
@export var wind_force: Vector2 = Vector2.ZERO
@export var ambient_type: int = 0

@onready var brake_bar = get_node_or_null("CanvasLayer/UI/BrakeBar")
@onready var status_label = get_node_or_null("CanvasLayer/UI/StatusLabel")
@onready var car_count_label = get_node_or_null("CanvasLayer/UI/CarCountLabel")
@onready var health_label = get_node_or_null("CanvasLayer/UI/HealthLabel")
@onready var instructions = get_node_or_null("CanvasLayer/UI/Instructions")

var car_scene = load("res://scenes/car.tscn")
var current_car: CharacterBody2D = null
var cars_parked_count: int = 0
var waiting_for_next: bool = false
var all_spots: Array = []
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var main_camera: Camera2D = null

func _ready() -> void:
	print("--- Level Start: ", name, " ---")
	randomize() # Ensure fresh random seed
	
	# Ambient Audio
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").set_ambient(ambient_type)
	
	# Camera
	main_camera = Camera2D.new()
	main_camera.position = Vector2(640, 360)
	add_child(main_camera)
	main_camera.make_current()

	# Find Spots
	all_spots.clear()
	var spots_node = get_node_or_null("ParkingSpots")
	if spots_node:
		_find_spots_recursive(spots_node)
	print("Found ", all_spots.size(), " spots.")
	
	# Spawn first car
	_spawn_new_car()
	_update_ui()

func _find_spots_recursive(node: Node) -> void:
	for child in node.get_children():
		if child.has_method("set_as_target"):
			all_spots.append(child)
			child.set_as_target(false)
		_find_spots_recursive(child)

func _process(delta: float) -> void:
	if main_camera and shake_timer > 0:
		shake_timer -= delta
		main_camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		if shake_timer <= 0: main_camera.offset = Vector2.ZERO

	if Input.is_action_just_pressed("menu"):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").set_ambient(0)
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

	if waiting_for_next:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("drift") or Input.is_action_just_pressed("ui_accept"):
			if cars_parked_count >= cars_to_park:
				if next_level_scene != "":
					get_tree().change_scene_to_file(next_level_scene)
			else:
				_spawn_new_car()

func _spawn_new_car() -> void:
	print("Spawning car...")
	waiting_for_next = false
	
	# UI Reset
	if status_label: 
		status_label.text = "PARK IT!"
		status_label.modulate = Color.WHITE
	if instructions: instructions.hide()
	if brake_bar: brake_bar.modulate = Color.WHITE
	
	# Pick Spot
	if all_spots.size() > 0:
		for s in all_spots: s.set_as_target(false)
		var available = all_spots.filter(func(s): return not s.is_occupied)
		if available.size() > 0:
			available.pick_random().set_as_target(true)
	
	# Create Car
	if not car_scene:
		print("CRITICAL: car_scene is null!")
		return
		
	current_car = car_scene.instantiate()
	current_car.position = spawn_position
	current_car.rotation = spawn_rotation
	current_car.car_type = randi() % 5 # Randomly pick 0-4 (SPORTS, LIMO, BEATER, EV, STANDARD)
	print("Spawning Car Type index: ", current_car.car_type)
	
	add_child(current_car)
	
	# Setup Connections
	current_car.friction_updated.connect(_on_friction_updated)
	current_car.overheated.connect(_on_overheated)
	current_car.brakes_recovered.connect(_on_brakes_recovered)
	current_car.parked_successfully.connect(_on_parked)
	current_car.crashed.connect(_on_crashed)
	current_car.health_updated.connect(_on_health_updated)
	
	# Apply Physics
	current_car.friction_multiplier = friction_mult
	current_car.drag_multiplier = drag_mult
	current_car.external_force = wind_force
	
	current_car.take_control()
	print("Car spawned and control given.")

func _update_ui() -> void:
	if car_count_label:
		car_count_label.text = "CARS PARKED: %d / %d" % [cars_parked_count, cars_to_park]

func shake_screen(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration

func _on_friction_updated(current: float, max_val: float) -> void:
	if brake_bar: brake_bar.value = (current / max_val) * 100.0

func _on_health_updated(current: int, max_val: int) -> void:
	if health_label:
		var h = ""
		for i in range(max_val): h += "■" if i < current else "□"
		health_label.text = "CONDITION: " + h
		health_label.modulate = Color.RED if current <= 1 else Color.WHITE

func _on_overheated(_dur: float) -> void:
	if status_label: status_label.text = "OVERHEATED!"
	if brake_bar: brake_bar.modulate = Color.RED

func _on_brakes_recovered() -> void:
	if status_label: status_label.text = "PARK IT!"
	if brake_bar: brake_bar.modulate = Color.WHITE

func _on_parked() -> void:
	cars_parked_count += 1
	waiting_for_next = true
	if status_label: 
		status_label.text = "PARKED!"
		status_label.modulate = Color.GREEN
	if instructions:
		instructions.text = "WELL DONE! PRESS [A / SHIFT]"
		instructions.show()
	_update_ui()

func _on_crashed() -> void:
	if status_label: 
		status_label.text = "CRASHED!"
		status_label.modulate = Color.RED
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
