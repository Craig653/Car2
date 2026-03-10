extends Area2D

@export var max_park_speed: float = 100.0 # Speed must be below this to park

var is_target: bool = false
var is_occupied: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func set_as_target(active: bool) -> void:
	is_target = active
	# If a spot becomes a target, it's definitely not occupied yet
	if active: is_occupied = false 
	if has_node("Visual/TargetHighlight"):
		$Visual/TargetHighlight.visible = active
	if has_node("Visual/Lines"):
		$Visual/Lines.default_color = Color.ORANGE if active else Color(1, 1, 1, 0.2)

func _on_body_entered(body: Node2D) -> void:
	if is_target and body.has_method("try_park"):
		_check_park_status(body)

func _physics_process(_delta: float) -> void:
	if not is_target: return
	
	for body in get_overlapping_bodies():
		if body.has_method("try_park") and not body.is_parked:
			_check_park_status(body)

func _check_park_status(body: Node2D) -> void:
	# 1. Check Distance (Increased from 25 to 45)
	var dist = global_position.distance_to(body.global_position)
	if dist > 45.0: 
		return
		
	# 2. Check Rotation (Increased from ~15 deg to ~30 deg)
	var angle_diff = abs(fmod(body.rotation - rotation, PI))
	var is_aligned = angle_diff < 0.52 or angle_diff > PI - 0.52 # Within ~30 degrees
	
	if not is_aligned:
		return

	# 3. Check Speed (via existing car logic)
	if body.try_park(max_park_speed):
		print("SUCCESS! Perfectly Parked.")
		is_occupied = true
		set_as_target(false)
