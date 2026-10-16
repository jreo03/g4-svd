extends Node3D

@onready var wheels: Array = [
	$"../fl",
	$"../fr",
	$"../rl",
	$"../rr",
	]

@export var asphalt_materials: Array[SVD_surface]

func _physics_process(delta):
	var total_rolling: float
	var total_skidding: float
	var total_diff: float
	var total_rubbing: float
	var collided_wheels: Array
	var asphalt: float = 1.0
	var collided_count: int
	for i in wheels:
		i = i as SVD_WHEEL
		total_rolling += abs(i.spin)
		total_skidding += abs(i.OUTPUT_skidding)
		total_diff += abs(i.OUTPUT_difference)
		total_rubbing += abs(i.OUTPUT_stressing)
		if i.STATE_grounded:
			collided_wheels.append(i)
			collided_count += 1
	
	for i in collided_wheels:
		i = i as SVD_WHEEL
		if not i.SP_resource in asphalt_materials:
			asphalt -= 1.0/float(collided_count)
	
	var offroad: float = 1.0-asphalt
	
	
	total_skidding = max(total_skidding -20,0)*0.25
	total_rubbing = max(total_rubbing -10,0)
	
	$rolling.pitch_scale = 1.0 +total_rolling/1000
	$rolling.volume_db = clampf(linear_to_db(max(total_rolling/1000.0,0)*0.86*asphalt),-80,0)
	$rolling.max_db = $rolling.volume_db

	$rub.volume_db = clampf(linear_to_db((max(total_rubbing-total_skidding,0) *0.86*asphalt)/300.0),-80,0)
	$rub.max_db = $rub.volume_db

	$skid.pitch_scale = min(0.8 +total_diff/500.0, 1.5)
	$skid.volume_db = clampf(linear_to_db(max(total_skidding,0)/30.0 *0.75*asphalt),-80,5)
	$skid.max_db = $skid.volume_db
	
	$offroad_roll.pitch_scale = 0.25 +total_rolling/1000.0
	$offroad_roll.volume_db = clampf(linear_to_db(max(total_rolling/1000.0,0)*1.0*offroad), -80, 0)
	$offroad_roll.max_db = $offroad_roll.volume_db

	offroad *= min(total_rolling/10.0, 1)

	$offroad_skid.pitch_scale = 1.0 +total_diff/1000.0
	$offroad_skid.volume_db = clampf(linear_to_db(max(total_diff,0)/100.0 *0.75*offroad), -80, 0)
	$offroad_skid.max_db = $offroad_skid.volume_db
