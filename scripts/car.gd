extends CharacterBody2D

signal overheated(duration: float)
signal brakes_recovered
signal friction_updated(current: float, max: float)
signal parked_successfully
signal crashed
signal health_updated(current: int, max: int)

enum CarType { SPORTS, LIMO, BEATER, EV, STANDARD }

@export_group("Car Variety")
@export var car_type: CarType = CarType.STANDARD

@export_group("Physics")
@export var max_speed: float = 280.0
@export var min_speed: float = 30.0
@export var acceleration: float = 100.0
@export var braking_force: float = 500.0
@export var steering_speed: float = 3.5

@export_group("Environment Overrides")
@export var friction_multiplier: float = 1.0
@export var drag_multiplier: float = 1.0
@export var external_force: Vector2 = Vector2.ZERO

@export_group("Brakes")
@export var max_friction_units: float = 120.0
@export var brake_drain_rate: float = 15.0
@export var drift_drain_rate: float = 25.0
@export var overheat_duration: float = 2.0

@export_group("Durability")
@export var max_health: int = 3
@export var crash_speed_threshold: float = 120.0

var current_speed: float = 100.0
var current_friction: float = 120.0
var current_health: int = 3
var is_overheated: bool = false
var overheat_timer: float = 0.0
var is_player_controlled: bool = false
var is_parked: bool = false
var is_dead: bool = false
var invul_timer: float = 0.0

var veer_timer: float = 0.0
var slip_timer: float = 0.0

var skid_scene = preload("res://scenes/skidmark.tscn")
var current_skid: Line2D = null

func _ready() -> void:
	_apply_car_type_stats()
	current_friction = max_friction_units
	current_health = max_health
	current_speed = 100.0 

func _apply_car_type_stats() -> void:
	# Reset defaults
	$Body.scale = Vector2(1, 1)
	$Body.color = Color(0.2, 0.5, 0.8) # Default Blue
	
	match car_type:
		CarType.SPORTS:
			max_speed = 450.0
			steering_speed = 4.0
			brake_drain_rate = 40.0
			$Body.color = Color.DARK_RED
		CarType.LIMO:
			max_speed = 250.0
			steering_speed = 1.8
			braking_force = 500.0
			$Body.scale = Vector2(1.1, 1.8)
			$Body.color = Color.BLACK
		CarType.BEATER:
			max_speed = 300.0
			$Body.color = Color.SADDLE_BROWN
		CarType.EV:
			max_speed = 400.0
			acceleration = 60.0
			$Body.color = Color.TEAL
		CarType.STANDARD:
			$Body.color = Color(0.2, 0.5, 0.8)

func _physics_process(delta: float) -> void:
	if is_parked or is_dead:
		velocity = Vector2.ZERO
		_stop_skid()
		move_and_slide()
		return

	if invul_timer > 0:
		invul_timer -= delta
		modulate.a = 0.5 if Engine.get_frames_drawn() % 10 < 5 else 1.0
	else:
		modulate.a = 1.0

	if not is_player_controlled:
		_handle_ai_arrival(delta)
	else:
		_handle_player_input(delta)

	# Movement Calculation
	var forward_vec = Vector2.UP.rotated(rotation)
	velocity = (forward_vec * current_speed) + external_force
	
	if move_and_slide():
		_handle_collision()

func _handle_ai_arrival(delta: float) -> void:
	current_speed = move_toward(current_speed, max_speed * 0.3, acceleration * delta)
	_stop_skid()

func _handle_player_input(delta: float) -> void:
	var is_skidding = false
	var steer_input = Input.get_axis("steer_left", "steer_right")
	var drift_input = Input.is_action_pressed("drift")
	
	# Drifting / Swivel
	if drift_input and current_friction > 0 and not is_overheated:
		is_skidding = true
		rotation += steer_input * steering_speed * friction_multiplier * 2.0 * delta
		current_speed = move_toward(current_speed, min_speed, braking_force * delta)
		current_friction -= drift_drain_rate * delta
		friction_updated.emit(current_friction, max_friction_units)
		if AudioManager.has_method("play_brake"): AudioManager.play_brake()
		if current_friction <= 0:
			is_overheated = true
			overheat_timer = overheat_duration
			overheated.emit(overheat_duration)
	else:
		rotation += steer_input * steering_speed * friction_multiplier * delta

	# Detect Cornering Skid
	if abs(steer_input) > 0.5 and current_speed > max_speed * 0.6:
		is_skidding = true

	# Brakes
	var brake_input = Input.get_action_strength("brake")
	
	# Visuals: Brake lights
	var brake_color = Color(0.5, 0, 0)
	if is_overheated: brake_color = Color(1, 0, 0)
	elif brake_input > 0.1 or drift_input: brake_color = Color(2, 0.2, 0.2)
	%BrakeLightL.color = brake_color
	%BrakeLightR.color = brake_color

	if is_overheated:
		overheat_timer -= delta
		if overheat_timer <= 0:
			is_overheated = false
			current_friction = 20.0
			brakes_recovered.emit()
			if AudioManager.has_method("play_ding"): AudioManager.play_ding()
		current_speed = move_toward(current_speed, max_speed / drag_multiplier, acceleration * delta)
	elif not drift_input and brake_input > 0 and current_friction > 0:
		var effective_braking = braking_force * friction_multiplier
		current_speed = move_toward(current_speed, min_speed, brake_input * effective_braking * delta)
		current_friction -= brake_input * brake_drain_rate * delta
		friction_updated.emit(current_friction, max_friction_units)
		
		if current_speed > min_speed * 1.5:
			is_skidding = true
			if AudioManager.has_method("play_brake"): AudioManager.play_brake()
			
		if current_friction <= 0:
			is_overheated = true
			overheat_timer = overheat_duration
			overheated.emit(overheat_duration)
			if AudioManager.has_method("play_crash"): AudioManager.play_crash()
	elif not drift_input:
		current_speed = move_toward(current_speed, max_speed / drag_multiplier, (acceleration / drag_multiplier) * delta)

	# Skid Marks
	if is_skidding and friction_multiplier >= 0.5:
		_update_skid()
	else:
		_stop_skid()

func _update_skid() -> void:
	if not current_skid or current_skid.fading:
		current_skid = skid_scene.instantiate()
		get_parent().add_child(current_skid)
	current_skid.add_point(global_position)
	if current_skid.get_point_count() > 50:
		current_skid.remove_point(0)

func _stop_skid() -> void:
	if current_skid and not current_skid.fading:
		current_skid.fading = true
		current_skid = null

func _handle_collision() -> void:
	if is_dead or invul_timer > 0: return
	if current_speed > crash_speed_threshold:
		if AudioManager.has_method("play_crash"): AudioManager.play_crash()
		if get_parent().has_method("shake_screen"): get_parent().shake_screen(10.0, 0.3)
		current_health -= 1
		health_updated.emit(current_health, max_health)
		invul_timer = 1.5
		current_speed *= 0.4 
		if current_health <= 0:
			is_dead = true
			crashed.emit()
	else:
		current_speed = move_toward(current_speed, current_speed * 0.8, 50.0)

func take_control() -> void:
	is_player_controlled = true
	health_updated.emit(current_health, max_health)

func try_park(target_velocity_max: float) -> bool:
	if current_speed <= target_velocity_max:
		is_parked = true
		_stop_skid()
		if AudioManager.has_method("play_ding"): AudioManager.play_ding()
		parked_successfully.emit()
		return true
	return false

func take_damage(amount: int = 1) -> void:
	if invul_timer > 0: return
	current_health -= amount
	health_updated.emit(current_health, max_health)
	invul_timer = 1.0
	if AudioManager.has_method("play_crash"): AudioManager.play_crash()
	if get_parent().has_method("shake_screen"): get_parent().shake_screen(15.0, 0.4)
	if current_health <= 0:
		is_dead = true
		crashed.emit()
