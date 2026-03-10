extends Line2D

var fading: bool = false
var alpha: float = 0.4

func _ready() -> void:
	$Timer.timeout.connect(_on_timeout)

func _process(delta: float) -> void:
	if fading:
		alpha -= delta * 0.5
		default_color.a = max(0.0, alpha)
		if alpha <= 0:
			queue_free()

func _on_timeout() -> void:
	fading = true
