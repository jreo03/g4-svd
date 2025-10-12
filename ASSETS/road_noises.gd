extends Node3D

@onready var wheels: Array = [
	$"../fl",
	$"../fr",
	$"../rl",
	$"../rr",
	]

func _physics_process(delta):
	var total_rolling: float
	var total_skidding: float
	var total_rubbing: float
	for i in wheels:
		i = i as SVD_WHEEL
		total_rolling += abs(i.spin)
		total_skidding += abs(i.OUTPUT_skidding)
		total_rubbing += abs(i.OUTPUT_stressing)
	
	total_skidding = max(total_skidding -20,0)*0.25
	total_rubbing = max(total_rubbing -10,0)
	
	$rolling.pitch_scale = 1.0 +total_rolling/1000
	$rolling.volume_db = clamp(linear_to_db(max(total_rolling/1000.0,0)),-80,6)
	$rolling.max_db = $rolling.volume_db

	$rub.volume_db = clamp(linear_to_db((max(total_rubbing-total_skidding,0))/300.0),-80,0)
	$rub.max_db = $rub.volume_db

	$skid.volume_db = clamp(linear_to_db(max(total_skidding,0)/30.0),-80,6)
	$skid.max_db = $skid.volume_db
	
