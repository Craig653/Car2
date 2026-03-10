extends Control

func _ready() -> void:
	$Grid/Standard.pressed.connect(func(): _on_level_button_pressed("res://scenes/mega_lot.tscn"))
	$Grid/Rain.pressed.connect(func(): _on_level_button_pressed("res://scenes/rain_lot.tscn"))
	$Grid/Snow.pressed.connect(func(): _on_level_button_pressed("res://scenes/snow_lot.tscn"))
	$Grid/Windy.pressed.connect(func(): _on_level_button_pressed("res://scenes/windy_lot.tscn"))
	$Grid/Muddy.pressed.connect(func(): _on_level_button_pressed("res://scenes/muddy_lot.tscn"))
	$Grid/Incline.pressed.connect(func(): _on_level_button_pressed("res://scenes/incline_lot.tscn"))
	$Grid/Lava.pressed.connect(func(): _on_level_button_pressed("res://scenes/lava_lot.tscn"))
	$Grid/Quit.pressed.connect(_on_quit_pressed)

func _on_level_button_pressed(level_path: String) -> void:
	get_tree().change_scene_to_file(level_path)

func _on_quit_pressed() -> void:
	get_tree().quit()
