extends Node3D

@onready var car: SVD_BODY = get_parent()
@export var disabled: bool

func _process(delta):
	if disabled:
		$enoff.stop()
		$enon.stop()
		return
	
	$enon.volume_db = max(linear_to_db(car.throttle),-80.0)
	$enoff.volume_db = max(linear_to_db(1.0 -car.throttle),-80.0)
	$enon.max_db = $enon.volume_db
	$enoff.max_db = $enoff.volume_db
	
	$enon.pitch_scale = max(car.rpm,800)/7800.0
	$enoff.pitch_scale = max(car.rpm,800)/7800.0
