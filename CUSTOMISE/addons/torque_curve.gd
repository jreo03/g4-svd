extends Node

@export var TEST_disabled: bool
@export var Max_DriveForce: float = 150
@export var Max_RevUpSpeed: float = 150
@export var Max_RevDownSpeed: float = 50

@export var Torque_Curve: Curve
@export var Decline_Curve: Curve

@onready var _car: SVD_BODY = get_parent()

func _physics_process(delta):
	if TEST_disabled:
		return

	var clamped: float = clamp(_car.rpm_scaled, 0.0, 1.0)
	var _tq: float = Torque_Curve.sample_baked(clamped)
	var _dc: float = Decline_Curve.sample_baked(clamped)
	
	_car.EN_DriveForce = Max_DriveForce*_tq
	_car.EN_RevUpSpeed = Max_RevUpSpeed*_tq
	_car.EN_RevDownSpeed = Max_RevDownSpeed*_dc
