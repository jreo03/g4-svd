extends RayCast3D
class_name SVD_WHEEL

@export var Camber: float: set = XCamber
func XCamber(val):
	Camber = val
	if position.x>0:
		$hub.rotation_degrees.z = -val
	else:
		$hub.rotation_degrees.z = val


@export var SUS_spring_stiffness: float = 40
@export var SUS_dampening: float = 4.5
@export var SUS_rest_length: float = 0.3
@export var SUS_tyre_stiffness: float
@export var SUS_tyre_height: float
@export var WL_size: float = 0.55
@export var WL_weight: float = 1.0

@export var TR_Tire_Model: Resource: set = xtr_mdl
func xtr_mdl(val: SVD_TMODEL):
	TR_Tire_Model = val
	TR_MDL_peak_y = val.TR_MDL_peak_y
	TR_MDL_peak_x = val.TR_MDL_peak_x
	TR_MDL_aspect_ratio = val.TR_MDL_aspect_ratio
	TR_MDL_shape_x = val.TR_MDL_shape_x
	TR_MDL_shape_y = val.TR_MDL_shape_y
	TR_MDL_linear = val.TR_MDL_linear
	TR_MDL_friction = val.TR_MDL_friction

@export var TR_stiffness: float = 40
@export var TR_deform_factor: float = 4
@export var TR_deform_threshold: float = 1
@export var TR_spin_resistence_rate: float = 20
@export var TR_friction_multiplier: float = 1
@export var TR_height: float = 0.1
@export var TR_soft_tyre: bool
@export var TR_elasticity: float = 2500
@export var TR_dampening: float = 25

@export var Signals_ABS: bool
@export var Signals_ABS_Sensitivity: float = 2
@export var Signals_TCS: bool


var TR_MDL_peak_y: float = 1
var TR_MDL_peak_x: float = 1
var TR_MDL_aspect_ratio: float = 1
var TR_MDL_shape_x: float = 1
var TR_MDL_shape_y: float = 1
var TR_MDL_linear: float = 1
var TR_MDL_friction: float = 1

	

@export var DT_influence: float = 1
@export var DT_BrakeTorque: float = 5
@export var DT_HandbrakeBias: float = 0
@export var DT_BrakeBias: float = 1
@export var curb_step_behaviour = 1 # (int, "Bump", "Absorb")

@export var AN_spinning_meshes: Array # (Array, NodePath)
@export var AN_fixed_meshes: Array # (Array, NodePath)
#export(Array, NodePath) var AN_steering_meshes: Array
var a_s_m: Array
var a_f_m: Array
#var a_s2_m: Array

@onready var car: RigidBody3D = get_parent()

var spin: float = 0
var total_w_weight: float
var prev_compressed: float
var predict_prev_compressed: float

var HUB_pos: float
var HUB_velocity: float
var HUB_thrust: float
var HUB_inertia_thrust: float
var HUB_inertia: float
var HUB_past_pos: float
@export var HUB_max_travel: float = 0.3
@export var HUB_min_travel: float = -10.1
@export var HUB_spring_rest: float = 0.45
@onready var AN_hub: Marker3D = $hub
@onready var AN_spin: Marker3D = $hub/spin
@onready var AN_steer: Marker3D = $hub/steer
@onready var AN_fixed: Marker3D = $hub/fixed

var TYRE_deflated: float
var TYRE_vertical_v: float
var TYRE_past_deflated: float
@export var TYRE_elasticity: float = 50.0
@export var TYRE_damp: float = 50.0
@export var WHEEL_weight: float = 14.0

var STATE_grounded: bool
var STATE_arm_limited: bool
var STATE_arm_limited2: bool
var STATE_brake_locked: bool
var MEASURE_aligning: float
var MEASURE_travelled: float

var dt_overdrive: float
var dt_torque: float
var dt_substantialtorque: float
var dt_braking: float

const newton: float = 0.0169946645619466

@onready var c_v: Marker3D = $c_v
@onready var p_p: MeshInstance3D = $c_v/patch_pos

var impulse: Array = [Vector3(),Vector3()]

var patch_pos: Vector3

var OUTPUT_skidding: float
var OUTPUT_stressing: float
var OUTPUT_grip: float
var OUTPUT_compressed: float
var past_global_axle_pos: Vector3
var predicted_s_force: float

@export var DIFF_lock_to: NodePath
@export var DIFF_Locking_Preload: float = 70
@export var DIFF_Locking_Power: float = 0.3
@export var DIFF_Locking_Coast: float = 0.3
var df_lockto: SVD_WHEEL

func _ready():
	df_lockto = get_node(DIFF_lock_to)
	for i in AN_spinning_meshes:
		a_s_m.append(get_node(i))
	for i in AN_fixed_meshes:
		a_f_m.append(get_node(i))
#	for i in AN_steering_meshes:
#		a_s2_m.append(get_node(i))

	for i in a_s_m:
		remove_child(i)
		AN_spin.add_child(i)

	for i in a_f_m:
		remove_child(i)
		AN_fixed.add_child(i)

var tyre_density: float = 100.0
var tyre_elasticity: float = 30.0
var tyre_damp: float = 60.0
var tyre_v_velocity: float
var tyre_height: float = 0.5

func _physics_process(delta):
	if not car.PSDB:
		return
		
	MEASURE_aligning = 0
	$c_v.visible = car.DB_forces_visible
		
	var hz_scale: float = delta*60.0
	spin += dt_torque/(dt_overdrive +1.0)
	spin += dt_substantialtorque
	MEASURE_aligning += dt_substantialtorque
	if dt_braking>0:
		spin -= spin/max(abs(spin)/(dt_braking/(dt_overdrive +1.0)),1)
		MEASURE_aligning -= spin/max(abs(spin)/(dt_braking/(dt_overdrive +1.0)),1)
		
	var thing: float = 1.0/(dt_overdrive +1.0)
	
	var real_wheelsize: float = WL_size/2.0
	
	target_position.y = -(SUS_rest_length + WL_size*0.5)
	
	var velocity: Vector3 = car.PSDB.get_velocity_at_local_position(global_position - car.global_position)
	var local_velocity: Vector3 = velocity*global_transform.basis.orthonormalized()
	
	if STATE_brake_locked:
		AN_spin.rotate_x(spin*delta*2.0)
	
	total_w_weight = WL_weight*1.0
	
	var c_normal: Vector3
	var c_point: Vector3 = global_position +global_transform.basis.orthonormalized() * target_position
	var c_axis: Basis


	if is_colliding():
		c_normal = get_collision_normal()
		c_point = get_collision_point()
		c_axis = Basis(c_normal.cross(global_transform.basis.z),c_normal,global_transform.basis.x.cross(c_normal)).orthonormalized()
		
		var world_offsetted: Vector3 = c_v.global_position - car.global_position
		var patch_global_velocity: Vector3 = car.PSDB.get_velocity_at_local_position(world_offsetted)
		
		var patch_velocity: Vector3 = patch_global_velocity*c_axis.orthonormalized()
		
		c_v.global_position = c_point
		c_v.global_transform.basis = c_axis
		
		HUB_past_pos = HUB_pos
		
		var spring_force: float
		var t_stiff_y: float = TR_elasticity
		var t_damp_y: float = TR_dampening
		var t_stiff_x: float = t_stiff_y*TR_MDL_aspect_ratio
		var t_damp_x: float = t_damp_y*TR_MDL_aspect_ratio

		var predict_vector: Vector2 = Vector2(patch_velocity.x,(spin - patch_velocity.z/WL_size))

		var vector_p: float = patch_pos.length()
		var vector_d: float = predict_vector.length()
		
		var travel_angle: float = min(abs(patch_velocity.x)/(abs(spin*WL_size) +1),1)

		var compressed: float = max(SUS_rest_length - HUB_pos,0)
		#var compressed_bottomed: float = max(SUS_min_length - HUB_pos,0)

		var axle_vel: float = HUB_past_pos - HUB_pos

		OUTPUT_compressed = compressed

		var damp: float = SUS_dampening
		var stiff: float = SUS_spring_stiffness*newton*1000.0
		var t_vstiff: float = max(SUS_tyre_stiffness*newton*1000.0,0.0001)
		
		var t_strength: float = 1
		
		if t_vstiff>0 and stiff>0:
			t_strength = min(t_vstiff/stiff,1)

		var t_t: float = WL_size/2.0 - global_position.distance_to(c_point)
		
		HUB_pos = lerp(SUS_rest_length,-t_t,t_strength)

		var tyre_fell: float = max(t_t + HUB_pos -SUS_tyre_height,0)
		
		HUB_pos -= tyre_fell

		compressed = max(SUS_rest_length - HUB_pos,0)
		#compressed_bottomed = max(SUS_min_length - HUB_pos,0)
		axle_vel = HUB_past_pos - HUB_pos

		spring_force = max(0.0,compressed*stiff + (damp*1000.0)*axle_vel)

		var byproduct: float
		# LOOHAHEAD
		
		var Agrip: float = INF
		
		if SUS_tyre_height>0:
			byproduct = (stiff/t_vstiff)/SUS_tyre_height
			var Amaxextends: float = SUS_rest_length
			
			var APOS = lerp(0.0,Amaxextends,t_strength)
			
			var Atyre_fell: float = max(Amaxextends - APOS + -SUS_tyre_height,0.0)
			APOS += Atyre_fell
			
			var As_compressed: float = max(APOS,0.0)
			var As_force: float = max(As_compressed*stiff,0.0)
			
			var Abyproduct: float = (stiff/t_vstiff)/SUS_tyre_height
			Agrip = As_force/(Atyre_fell*Abyproduct +1)

		# END

		var grip: float = min(spring_force,Agrip)*TR_MDL_friction*TR_friction_multiplier
#		if name == "fl":
#			print([grip,Agrip])
		
		OUTPUT_grip = grip
		var curved_grip_y: float = grip*(TR_MDL_peak_y*(1.0-TR_MDL_linear) +TR_MDL_linear)
		var peaked_grip_y: float = (grip*TR_MDL_peak_y)/TR_MDL_peak_y
		var curved_grip_x: float = grip*(TR_MDL_peak_x*(1.0-TR_MDL_linear) +TR_MDL_linear)
		var peaked_grip_x: float = (grip*TR_MDL_peak_x)/TR_MDL_peak_x

		var TR_MDL_shape: float = lerp(TR_MDL_shape_y,TR_MDL_shape_x,travel_angle)
		var TR_MDL_peak: float = lerp(TR_MDL_peak_y,TR_MDL_peak_x,travel_angle)
		
		var peaked_grip: float = lerp(peaked_grip_y,peaked_grip_x,travel_angle)
		var curved_grip: float = lerp(curved_grip_y,curved_grip_x,travel_angle)
		
		# WHEEL
		var w_dist: float = (spin - patch_velocity.z/WL_size)
		var predict_dist_x: float = patch_velocity.x
		var predict_slip: float

		STATE_brake_locked = dt_braking>(grip*((TR_spin_resistence_rate*delta)*(dt_overdrive +1.0)))
#		STATE_brake_locked = true
		if grip>0:
#			predict_slip = max(sqrt(pow(abs(w_dist),2.0) + pow(abs(predict_dist_x),2.0))/(grip*((TR_spin_resistence_rate*delta)/(dt_overdrive +1.0))) -1.0,0)
			var modifier: float = ((TR_spin_resistence_rate*delta)/(dt_overdrive +1.0))
#			predict_slip = max(sqrt(pow(abs(w_dist/modifier),2.0) + pow(abs(predict_dist_x/modifier),2.0))/curved_grip_y -TR_MDL_slip_range_y,0)

			predict_slip = max((Vector2(w_dist,predict_dist_x).length()/modifier)/curved_grip_y -1,0)

			var predict_peaked: float = 1.0 -(1.0/(max(sqrt(pow(abs(w_dist),2.0) + pow(abs(predict_dist_x),2.0))/peaked_grip_y/modifier -1,0) +1.0))
#			var predict_peaked: float = 1.0 -(1.0/(max(Vector2(w_dist/modifier,predict_dist_x/modifier).length()/peaked_grip_y -TR_MDL_slip_range_y,0) +1.0))
			if not STATE_brake_locked:
				var p: float = predict_slip*((predict_peaked/TR_MDL_shape_y)*TR_MDL_peak_y*(1.0-TR_MDL_linear) + TR_MDL_linear) +1.0
#				var p: float = predict_slip +1
				if name == "rl":
					_debug.queue[" returning"] = p
					_debug.queue[" predict_peaked"] = predict_peaked
				spin -= w_dist/p
				MEASURE_aligning -= w_dist/p
				
#		slip_y = max(dist_y.length()/curved_grip_y -TR_MDL_slip_range_y,0)
#		peaked_y = 1.0 -(1.0/(max(dist_y.length()/peaked_grip_y -TR_MDL_slip_range_y,0) +1.0))
#		dist_y /= slip_y*((peaked_y/TR_MDL_shape_y)*TR_MDL_peak_y*(1.0-TR_MDL_linear) + TR_MDL_linear) +1

		var t_stiff: float = lerp(t_stiff_y,t_stiff_x,pow(travel_angle,0.5))
		var t_damp: float = lerp(t_damp_y,t_damp_x,pow(travel_angle,0.5))
		
		# GROUND
		var b_force: float = (dt_braking/(t_stiff*delta))/(TR_spin_resistence_rate)
		var t_force: float = (dt_torque/(t_stiff*delta))/(TR_spin_resistence_rate)
#		if not spin == 0:
#			t_force += dt_substantialtorque*delta

		# y
		patch_pos.x -= patch_global_velocity.x*delta
		patch_pos.z -= patch_global_velocity.z*delta
		patch_pos -= c_axis.y*(patch_pos*c_axis).y

		var patch_dist: Vector3 = patch_pos*c_axis
		
		#Vector3(
#			patch_pos.x*c_axis[0].x + patch_pos.y*c_axis[0].y + patch_pos.z*c_axis[0].z,
#			patch_pos.x*c_axis[1].x + patch_pos.y*c_axis[1].y + patch_pos.z*c_axis[1].z,
#			patch_pos.x*c_axis[2].x + patch_pos.y*c_axis[2].y + patch_pos.z*c_axis[2].z
#			)


		var standstill: float = 1.0
		
#		standstill /= abs(patch_velocity.z/60.0)*TR_deform_factor +1
#		if name == "fl":
#			print(standstill)

		if spring_force>0:
			standstill /= abs(spin*TR_deform_factor/1.5)/spring_force +1

		#if name == "fl":
			#print(standstill)

		patch_pos -= Vector3(c_axis[0].x,c_axis[0].y,c_axis[0].z)*patch_dist.x*(1.0 -standstill)

		var patch_slip: float
		var patch_peaked: float

		if not STATE_brake_locked:
			var patch_clamp_z_amount: float = b_force
			var patch_clamp_z: float = max(abs(patch_dist.z) -patch_clamp_z_amount,0)


			if patch_dist.z<0:
				patch_pos += Vector3(c_axis[2].x,c_axis[2].y,c_axis[2].z)*patch_clamp_z
			else:
				patch_pos -= Vector3(c_axis[2].x,c_axis[2].y,c_axis[2].z)*patch_clamp_z
		
		if grip>0:
			patch_slip = max(patch_pos.length()/(curved_grip_y/t_stiff) -1,0)
			patch_peaked = 1.0 -(1.0/(max(patch_pos.length()/(peaked_grip/t_stiff) -1,0) +1.0))
		
		patch_pos /= patch_slip*((patch_peaked/TR_MDL_shape)*TR_MDL_peak*(1.0-TR_MDL_linear) + TR_MDL_linear) +1

#		t_stiff *= standstill
#		t_damp *= standstill

		if not STATE_brake_locked:
			patch_pos += c_axis.z*t_force
		
		var patch_dist_global: Vector3 = patch_pos*c_axis

		var p_v_off: Vector3 = patch_velocity
		
		p_v_off.x *= standstill
		
		var dist: Vector3 = Vector3(
			p_v_off.x*t_damp -patch_dist_global.x*t_stiff,
			0,
			(p_v_off.z - spin*WL_size)*t_damp -patch_dist_global.z*t_stiff
#			yd*t_damp -patch_dist_global.z*t_stiff
			)
		if grip>0:
			if STATE_brake_locked:
				spin -= w_dist/(predict_slip +1)
				MEASURE_aligning -= w_dist/(predict_slip +1)

#		dist.y += ((dt_braking/hz_scale)*clamp(patch_velocity.z*t_damp,-1,1))/(TR_spin_resistence_rate/60.0)

		var slip: float
		var peaked: float
		if grip>0:
			slip = max(dist.length()/curved_grip -1,0)
			peaked = 1.0 -(1.0/(max(dist.length()/peaked_grip -1,0) +1.0))
			
			OUTPUT_skidding = max((slip*curved_grip)*0.025*grip + (patch_slip*curved_grip)*0.05*grip,0)
			OUTPUT_stressing = dist.length()*min(abs(spin),1)
			if name == "fl":
				_debug.queue["OUTPUT_skidding"] = OUTPUT_skidding
				_debug.queue["OUTPUT_stressing"] = OUTPUT_stressing
	

		dist /= slip*((peaked/TR_MDL_shape)*TR_MDL_peak*(1.0-TR_MDL_linear) + TR_MDL_linear) +1

		if grip>0:
			$c_v/lateral.scale.y = dist.x/40.0
			if $c_v/lateral.scale.y>0:
				$c_v/lateral.rotation_degrees.x = 91
			else:
				$c_v/lateral.rotation_degrees.x = 89
			if slip>0:
				$c_v/lateral.modulate = Color(1,0,0)
			else:
				var debug_effective: float = 1.0 +((dist.length() -curved_grip)/(curved_grip))
				var green: float = debug_effective
				var blue: float = 1.0 - debug_effective
				$c_v/lateral.modulate = Color(0,green,blue)
			
			$c_v/longitudinal.scale.y = dist.z/40.0
			if $c_v/longitudinal.scale.y>0:
				$c_v/longitudinal.rotation_degrees.x = 91
			else:
				$c_v/longitudinal.rotation_degrees.x = 89
			if slip>0:
				$c_v/longitudinal.modulate = Color(1,0,0)
			else:
				var debug_effective: float = 1.0 +((dist.length() -curved_grip)/(curved_grip))
				var green: float = debug_effective
				var blue: float = 1.0 - debug_effective
				$c_v/longitudinal.modulate = Color(0,green,blue)

		$c_v/suspforce.scale.y = spring_force/40.0

#		dist = dist.limit_length(grip)
		
		var forces: Vector3
		forces += c_axis.y*spring_force
		if grip>0:
			forces -= c_axis.x*dist.x
			forces -= c_axis.z*dist.z
		
#		var point: Vector3 = c_point-car.global_position
		var point: Vector3 = car.PSDB.center_of_mass
		
		point -= (point - (c_point-car.global_position))/car.PHYS_form_factor
		
		$imp_point.global_position = point +car.global_position
		
		impulse = [point,forces*hz_scale]
	else:
		OUTPUT_compressed = 0
		OUTPUT_skidding = 0
		OUTPUT_grip = 0
		OUTPUT_stressing = 0
		TYRE_deflated = 0
		TYRE_vertical_v = 0
		c_v.global_position = c_point
		impulse = [Vector3(),Vector3()]
		patch_pos *= 0
		HUB_pos = SUS_rest_length
		
	p_p.position.x = patch_pos.x*c_axis[0].x + patch_pos.y*c_axis[0].z
	p_p.position.z = patch_pos.x*c_axis[2].x + patch_pos.y*c_axis[2].z

#	HUB_pos = min(HUB_pos,SUS_rest_length)
	
	# vv 2.0
	past_global_axle_pos = global_position
	# end
	
	AN_hub.position.y = -HUB_pos
	if not STATE_brake_locked:
		AN_spin.rotate_x(spin*delta*2.0)

	MEASURE_travelled += spin
