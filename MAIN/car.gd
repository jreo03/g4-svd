extends RigidBody3D
class_name SVD_BODY
var readied: bool

@export var PHYS_form_factor: float = 1 # (float, 0.0001, 1000)
@export var DB_steer_disabled: bool
@export var DB_forces_visible: bool
var engine_resistance: float
var runtime_engine_resistance: float
var rpm_speed: float
var rpm_windspeed: float
var rpm: float
var past_rpm: float

var wheels: Array
var wheels_count: int
var wheels_position: Vector3
var gear: int
var past_speed: float
var past_rpmspeed: float
var rt_dsweight: float

@export var Controls: Resource

@export var EN_DriveForce: float = 12
@export_enum("Wheels Synced", "Wheels Unsynced") var EN_DriveForceBehavior: int = 0
@export var EN_RevUpSpeed: float = 150
@export var EN_RevDownSpeed: float = 50
@export var EN_RevAlignmentRate: float = 50
@export var EN_IdleRPM: float = 800
@export var EN_MaxRPM: float = 7000
@export var EN_CanStall: bool = false
@export var EN_CanOverRev: bool = false
@export var EN_StallPrevention: float = 2
@export var EN_Torque_Curve: Curve
@export var EN_Decline_Curve: Curve

@export var GB_ForwardGearRatios: Array = [ # (Array, float)
	3.321,
	1.902,
	1.308,
	1.0,
	0.759,
]
@export var GB_FinalDriveRatio: float = 4.083
@export var GB_ReverseGearRatios: Array = [ # (Array, float)
	3.0,
]
@export var GB_clutch_needed: float = 0.25

#export(int, "Clutch-pack", "Viscous") var DIFF_Central_Differential_Behaviour: int
@export var DIFF_Central_Locking_Preload: float = 0
@export var DIFF_Central_Locking_Power: float = 0.0
@export var DIFF_Central_Locking_Coast: float = 0.0


@export var SR_pivot_point: float = -1.151
@export var SR_pivot_node: NodePath: set = XSR_pivot_node
func XSR_pivot_node(val):
	SR_pivot_node = val
	if not readied:
		await self.ready
	if get_node(val) is Node3D:
		SR_pivot_point = get_node(val).position.z
	else:
		printerr("SR_pivot_node is not a Node3D")
	
	
@export var SR_radius: float = 4.0
@export var SR_wheels: Array: set = XSR_wheels
var steer_wheels: Array
func XSR_wheels(val):
	SR_wheels = val
	if not readied:
		await self.ready
	steer_wheels = []
	for i in val:
		steer_wheels.append(get_node(i))
		MEASURE_est_max_steer = max(MEASURE_est_max_steer,abs(rad_to_deg(atan((-SR_pivot_point + get_node(i).position.z)/(SR_radius - get_node(i).position.x)))))

var throttle: float
var IP_throttle: float
var dt_dropping: float
var OUTPUT_total_compressed: float

const rads2rpm: float = 9.549297

func refresh_wheels():
	wheels_count = 0
	wheels = []
	for i in get_children():
		if i is SVD_WHEEL:
			wheels_count += 1
			wheels.append(i)

var PSDB: PhysicsDirectBodyState3D


var steer_input: float
var steer_output: float
var analog_accelerate: float
var analog_decelerate: float
var analog_handbrake: float
var analog_clutching: float

var MEASURE_est_max_steer: float
var MEASURE_assistance_factor: float
var MEASURE_driven_wheel_radius: float
var velocity: Vector3
var rvelocity: Vector3

var AST_clutch_delay: float
var AST_throttle_delay: float
var prev_gear_rpm_speed: float

var target_gear: int

var on_reverse: bool

func _ready():
	readied = true
	refresh_wheels()
#	XSR_wheels(SR_wheels)

func shiftgear(direction: int):
	if direction>0:
		if target_gear<len(GB_ForwardGearRatios):
			if Controls.AST_shift_assistance>0:
				if not target_gear == 0:
					AST_clutch_delay = Controls.AST_shifting_clutch_out_time
					AST_throttle_delay = Controls.AST_shifting_off_throttle_time
				target_gear += direction
			elif analog_clutching>GB_clutch_needed:
				target_gear += direction
	else:
		if target_gear>-(len(GB_ReverseGearRatios)):
			if Controls.AST_shift_assistance>0:
				if not target_gear == 0:
					AST_clutch_delay = Controls.AST_shifting_clutch_out_time
					AST_throttle_delay = Controls.AST_shifting_off_throttle_time
				target_gear += direction
			elif analog_clutching>GB_clutch_needed:
				target_gear += direction


func _input(event):
	
	if event.is_action_pressed("kb_shiftup"):
		shiftgear(1)
	elif event.is_action_pressed("kb_shiftdown"):
		shiftgear(-1)
	
	if event.is_action_pressed("debug_key"):
		DB_forces_visible = not DB_forces_visible
		$placeholder.visible = not DB_forces_visible
	# debugs
	if event.is_action_pressed("toggle_steering"):
#		Controls = Controls as ControlSettings
		Controls.UseMouseSteering = not Controls.UseMouseSteering
	# end
		

var prev_g_ratio: float

func gearbox(dt) -> float:
	var rat: float = 1
	
	if Controls.AST_shift_assistance>0:
		if analog_clutching>GB_clutch_needed or gear == 0:
			gear = target_gear
			if gear == 0:
				AST_clutch_delay = -1
				AST_throttle_delay = -1
		if AST_throttle_delay<=0:
			on_reverse = gear<0
	else:
		gear = target_gear
	
	var search: int = abs(gear)-2
	prev_g_ratio = 0.001
	if gear>0:
		if search>=0:
			prev_g_ratio = GB_ForwardGearRatios[search]
		else:
			prev_g_ratio = 0.001
	elif gear<0:
		if search>=0:
			prev_g_ratio = GB_ReverseGearRatios[search]
		else:
			prev_g_ratio = 0.001
		
	if gear>0:
		rat = GB_ForwardGearRatios[gear-1]
	elif gear<0:
		rat = GB_ReverseGearRatios[abs(gear)-1]
		
	prev_g_ratio *= GB_FinalDriveRatio*2.0
	return rat*GB_FinalDriveRatio
	
func engine(dt: float, c_revup: float, c_revdown: float) -> Array:
	
	var hz_scale: float = dt*60.0
	IP_throttle = analog_accelerate
	
	throttle -= (throttle - IP_throttle)*0.5
	
	var midpoint: float = c_revdown/(c_revup +c_revdown)
	var from_idle: float = 1.0 -rpm/EN_IdleRPM
	
	if rpm<EN_IdleRPM+c_revdown:
		if EN_CanStall:
			throttle = max(throttle,min(midpoint*min(EN_StallPrevention,1) +from_idle*max(EN_StallPrevention-1,0),1))
		else:
			rpm = EN_IdleRPM +c_revdown*hz_scale
	elif rpm>EN_MaxRPM-c_revup:
		if EN_CanOverRev:
			throttle = 0.0
		else:
			rpm = EN_MaxRPM -c_revup*hz_scale
	var torque_measure: float = throttle*c_revup - c_revdown*(1.0 -throttle)
	rpm += torque_measure*hz_scale
	if not EN_CanStall and rpm<=EN_IdleRPM:
		torque_measure *= 0
		
	return [torque_measure/rads2rpm,max(c_revup,c_revdown)/rads2rpm,torque_measure]

func controls(d_scale):
	
	var steer_desired: float = Input.get_action_strength("kb_steer_left") -Input.get_action_strength("kb_steer_right")
	var desired_accelerate: float
	var desired_decelerate: float
	var desired_handbrake: float
	var desired_clutching: float
	
	var raw_accelerate: float
	var raw_decelerate: float
		
	if Controls.UseMouseSteering:
		desired_accelerate = min(Input.get_action_strength("m_accelerate"),1)
		desired_decelerate = min(Input.get_action_strength("m_decelerate"),1)

		raw_accelerate = desired_accelerate
		raw_decelerate = desired_decelerate

		if Controls.AST_shift_assistance == 2 and on_reverse:
			desired_accelerate = min(Input.get_action_strength("m_decelerate"),1)
			desired_decelerate = min(Input.get_action_strength("m_accelerate"),1)

		desired_handbrake = min(Input.get_action_strength("m_handbrake"),1)
		if Controls.AST_shift_assistance>0:
			desired_clutching += Input.get_action_strength("m_handbrake")
		else:
			desired_clutching = Input.get_action_strength("m_clutch")
	else:
		desired_accelerate = min(Input.get_action_strength("kb_accelerate"),1)
		desired_decelerate = min(Input.get_action_strength("kb_decelerate"),1)

		raw_accelerate = desired_accelerate
		raw_decelerate = desired_decelerate

		if Controls.AST_shift_assistance == 2 and on_reverse:
			desired_accelerate = min(Input.get_action_strength("kb_decelerate"),1)
			desired_decelerate = min(Input.get_action_strength("kb_accelerate"),1)
			
		desired_handbrake = min(Input.get_action_strength("kb_handbrake"),1)
		if Controls.AST_shift_assistance>0:
			desired_clutching += Input.get_action_strength("kb_handbrake")
		else:
			desired_clutching = Input.get_action_strength("kb_clutch")
		
	var engagement_rpm: float = EN_IdleRPM + Controls.AST_clutch_in_rpm_offset
	var dist_from_engagement_rpm: float = (engagement_rpm - rpm)/(engagement_rpm -EN_IdleRPM)
		
	if Controls.AST_shift_assistance>0:
		desired_clutching += clamp(dist_from_engagement_rpm,0,1)
		
	desired_clutching = min(desired_clutching,1)

	if AST_throttle_delay>0:
		if rpm<rpm_speed:
			desired_accelerate = 1
			AST_clutch_delay = AST_throttle_delay
		else:
			desired_accelerate = 0
			AST_throttle_delay -= d_scale
	if AST_clutch_delay>0:
		desired_clutching = 1
		AST_clutch_delay -= d_scale

	if analog_accelerate<desired_accelerate -Controls.OnThrottleRate*d_scale:
		analog_accelerate += Controls.OnThrottleRate*d_scale
	elif analog_accelerate>desired_accelerate +Controls.OffThrottleRate*d_scale:
		analog_accelerate -= Controls.OffThrottleRate*d_scale
	else:
		analog_accelerate = desired_accelerate

	if analog_decelerate<desired_decelerate -Controls.OnBrakeRate*d_scale:
		analog_decelerate += Controls.OnBrakeRate*d_scale
	elif analog_decelerate>desired_decelerate +Controls.OffBrakeRate*d_scale:
		analog_decelerate -= Controls.OffBrakeRate*d_scale
	else:
		analog_decelerate = desired_decelerate
	
	if analog_handbrake<desired_handbrake -Controls.OnHandbrakeRate*d_scale:
		analog_handbrake += Controls.OnHandbrakeRate*d_scale
	elif analog_handbrake>desired_handbrake +Controls.OffHandbrakeRate*d_scale:
		analog_handbrake -= Controls.OffHandbrakeRate*d_scale
	else:
		analog_handbrake = desired_handbrake

	if analog_clutching<desired_clutching -Controls.OnClutchRate*d_scale:
		analog_clutching += Controls.OnClutchRate*d_scale
	elif analog_clutching>desired_clutching +Controls.OffClutchRate*d_scale:
		analog_clutching -= Controls.OffClutchRate*d_scale
	else:
		analog_clutching = desired_clutching

	if Controls.UseMouseSteering:
		var mouseposx = 0.0
		var aspect = (get_viewport().size.x / get_viewport().size.y) - (1.0 / 0.75)
		if get_viewport().size.x > 0.0:
			mouseposx = get_viewport().get_mouse_position().x / (aspect * 0.75 + 1.0)
			mouseposx /= 800.0
			mouseposx -= 0.5
			mouseposx *= 2.0
			
		steer_input = -mouseposx
		steer_input *= Controls.SteerSensitivity
		steer_input = clamp(steer_input, - 1.0, 1.0)
		
		var s = abs(steer_input) * 1.0 + 0.5
		if s > 1:
			s = 1
		
		steer_input *= s
	elif Controls.UseAccelerometreSteering:
		steer_input = -Input.get_accelerometer().x / 10.0
		steer_input *= Controls.SteerSensitivity
		steer_input = clamp(steer_input, - 1.0, 1.0)
		
		var s = abs(steer_input) * 1.0 + 0.5
		if s > 1:
			s = 1
		
		steer_input *= s
	else:
		
		# testing
#		var mouseposx: float = 0.0
#		var aspect: float = (get_viewport().size.x / get_viewport().size.y) - (1.0 / 0.75)
#		if get_viewport().size.x > 0.0:
#			mouseposx = get_viewport().get_mouse_position().x / (aspect * 0.75 + 1.0)
#			mouseposx /= 800.0
#			mouseposx -= 0.5
#			mouseposx *= 2.0
#
#		steer_desired = -mouseposx
#		steer_desired *= Controls.SteerSensitivity
#		steer_desired = clamp(steer_desired, - 1.0, 1.0)
		# end test
		
		var s_dist: float = steer_input - steer_desired
		
		var s_force: float
		if steer_desired>Controls.KeyboardSteerSpeed:
			if steer_input>steer_desired:
				s_force = Controls.KeyboardReturnSpeed
			elif abs(s_dist)>1:
				s_force = Controls.KeyboardCompensateSpeed
			else:
				s_force = Controls.KeyboardSteerSpeed
		elif steer_desired<-Controls.KeyboardSteerSpeed:
			if steer_input<steer_desired:
				s_force = Controls.KeyboardReturnSpeed
			elif abs(s_dist)>1:
				s_force = Controls.KeyboardCompensateSpeed
			else:
				s_force = Controls.KeyboardSteerSpeed
		else:
			s_force = Controls.KeyboardReturnSpeed
		
		s_force *= d_scale
		
		if s_force>0:
			steer_input -= s_dist/(abs(s_dist)/s_force +1)
		
		steer_input = clamp(steer_input, - 1.0, 1.0)

	velocity = linear_velocity * global_transform.basis.orthonormalized() 
	rvelocity = angular_velocity * global_transform.basis.orthonormalized()

	var siding = abs(velocity.x)

	if velocity.x > 0 and steer_input<0 or velocity.x < 0 and steer_input>0:
		siding = 0.0
		
	MEASURE_assistance_factor = 90.0/max(MEASURE_est_max_steer,1)
	var assist_commence = clamp((linear_velocity.length() -Controls.SteerAssistThreshold)/max(Controls.SteerAssistThreshold,1),0,1)

	_debug.queue[" MEASURE_est_max_steer"] = MEASURE_est_max_steer

	var going = max(velocity.z / (siding + 1.0), 0)

	var maxsteer = 1.0 / (going*assist_commence * (Controls.SteerAmountDecay / MEASURE_assistance_factor) + 1.0)

	steer_output = clamp(steer_input*maxsteer +(velocity.normalized().x*assist_commence)*(Controls.SteeringAssistance*MEASURE_assistance_factor) -rvelocity.y*(Controls.SteeringAssistanceAngular*MEASURE_assistance_factor*assist_commence),-1,1)


	if Controls.AST_shift_assistance == 2:
		var upshift_point: float = (EN_MaxRPM +Controls.AST_upshift_threshold)*max(MEASURE_driven_wheel_radius,0.1)/rads2rpm
		var downshift_point: float = (EN_MaxRPM +Controls.AST_downshift_threshold)*max(MEASURE_driven_wheel_radius,0.1)/rads2rpm
		var up_target: int = 1
		var down_target: int = 1
		for i in GB_ForwardGearRatios:
			var iratio: float = i*GB_FinalDriveRatio*4.0
			var ok: float = upshift_point/iratio
			var not_ok: float = downshift_point/iratio
			
			if linear_velocity.length()>ok:
				up_target += 1
			if linear_velocity.length()>not_ok:
				down_target += 1
		
		_debug.queue[" up_target"] = up_target
		_debug.queue[" down_target"] = down_target

		if target_gear == 0:
			target_gear = 1
		elif target_gear<0:
			if raw_accelerate>0.5 and rpm_windspeed<EN_IdleRPM - Controls.AST_standstill_threshold or velocity.z>0 and raw_accelerate>0.5:
				if Controls.AST_instant_reverse:
					target_gear = 1
					gear = target_gear
				else:
					target_gear = 0
					gear = target_gear
					shiftgear(1)
					AST_throttle_delay = Controls.AST_reverse_delay
					AST_clutch_delay = Controls.AST_reverse_delay
		else:
			if target_gear>0:
				if rpm_windspeed>EN_MaxRPM + Controls.AST_upshift_threshold and AST_clutch_delay<=0:
					shiftgear(1)
					target_gear = up_target
				elif prev_gear_rpm_speed<EN_MaxRPM + Controls.AST_downshift_threshold and AST_clutch_delay<=0 and target_gear>1:
					shiftgear(-1)
					target_gear = down_target
			if raw_decelerate>0.5 and rpm_windspeed<EN_IdleRPM - Controls.AST_standstill_threshold or velocity.z<0 and raw_decelerate>0.5:
				if Controls.AST_instant_reverse:
					target_gear = -1
					gear = target_gear
				else:
					target_gear = 0
					gear = target_gear
					shiftgear(-1)
					AST_throttle_delay = Controls.AST_reverse_delay
					AST_clutch_delay = Controls.AST_reverse_delay
		gear = clamp(gear,-GB_ReverseGearRatios.size(),GB_ForwardGearRatios.size())

func _integrate_forces(state: PhysicsDirectBodyState3D):
	PSDB = state

	var delta: float = state.step
	var hz_scale: float = delta*60.0
	var ds_weight: float
	controls(hz_scale)
	rpm_speed = 0
	prev_gear_rpm_speed = 0
	
	
	var rpm_progress: float = (rpm -EN_IdleRPM)/(EN_MaxRPM -EN_IdleRPM)
	var _tq = 1
	var _dc = 1
	
	if EN_Torque_Curve:
		_tq = EN_Torque_Curve.sample_baked(rpm_progress)
	if EN_Decline_Curve:
		_dc = EN_Decline_Curve.sample_baked(rpm_progress)
	
	var c_revup: float = EN_RevUpSpeed*_tq
	var c_revdown: float = EN_RevDownSpeed*_dc
	
	var g_ratio: float = gearbox(delta)*2.0
	
	apply_central_impulse(PSDB.total_gravity*mass*delta)
	
	var test_maxtorque: float = 10.0/g_ratio
	
	var test_drive_torque: float = 0.2
	test_drive_torque *= g_ratio
	
	var test_overdrive: float = max(test_drive_torque/test_maxtorque -1.0,0)
	var test_cgrip: float = max(EN_RevUpSpeed,EN_RevDownSpeed) + EN_RevAlignmentRate
	if gear == 0:
		test_cgrip = 0
	else:
		test_cgrip *= 1.0 -analog_clutching
	
	test_cgrip *= hz_scale
	var test_cstab: float = 1
	var test_cstab_rads: float = test_cstab*rads2rpm
	var test_cgrip_rads: float = test_cgrip/rads2rpm
	var test_dsweight: float = EN_RevUpSpeed/(EN_DriveForce*hz_scale)

	_debug.queue[" gm/s"] = linear_velocity.length()
	_debug.queue[" gkm/h"] = int(linear_velocity.length()*3.6)
	_debug.queue[" gs"] = (linear_velocity.length()/hz_scale - past_speed)/9.8/delta
	_debug.queue[" gs target"] = 0.0
	if gear == 1:
		_debug.queue[" gs target"] = 0.619686
	elif gear == 2:
		_debug.queue[" gs target"] = 0.358457
	elif gear == 3:
		_debug.queue[" gs target"] = 0.246538
	elif gear == 4:
		_debug.queue[" gs target"] = 0.188477
	elif gear == 5:
		_debug.queue[" gs target"] = 0.143074
	past_speed = linear_velocity.length()/hz_scale
	var cs_rads: float = rpm/rads2rpm
	var torque_data: Array = engine(delta,c_revup,c_revdown)
	
	rt_dsweight = max(rt_dsweight,1)
	
	
	
	# steering
	var steer: float = steer_output
	var turnradius: float = SR_radius

	if abs(steer)>0 and not DB_steer_disabled:
		turnradius /= abs(steer)
		if steer<0:
			turnradius *= -1.0
		for w in steer_wheels:
			w.rotation_degrees.y = rad_to_deg(atan((-SR_pivot_point + w.position.z)/(turnradius - w.position.x)))
	else:
		for w in steer_wheels:
			w.rotation.y = 0

	$"../sw".rotation = deg_to_rad(-steer_output*420)
	$"../sw_desired".rotation = deg_to_rad(-steer_input*420)

	var drive_median: float
	var central_median: float
	var central_travel_median: float
	var fastest_wheel: float
	
	if EN_DriveForceBehavior == 1:
		var count: float
		for wheel in wheels:
			wheel = wheel as SVD_WHEEL # cast placeholder
			count += wheel.DT_influence
			drive_median += wheel.spin*wheel.DT_influence
			central_median += wheel.spin
			central_travel_median += wheel.MEASURE_travelled
			fastest_wheel = max(fastest_wheel,abs(wheel.spin))
		
		central_median /= wheels_count
		drive_median /= count
		central_travel_median /= wheels_count
	
	var DB_SLIP: float
	
	OUTPUT_total_compressed = 0
	
	MEASURE_driven_wheel_radius = 0
	wheels_position = Vector3.ZERO
	
	var rev_down_difference: float = c_revdown/c_revup
	var abs_thresholded: float = 1

	for wheel in wheels:
		wheel = wheel as SVD_WHEEL # cast placeholder
		
		if wheel.Signals_ABS:
			abs_thresholded -= abs(abs(wheel.spin +wheel.MEASURE_aligning) - fastest_wheel)*wheel.Signals_ABS_Sensitivity*wheels_count/100.0

	abs_thresholded = lerp(max(abs_thresholded,0.0),1.0,analog_handbrake)
	for wheel in wheels:
		wheel = wheel as SVD_WHEEL # cast placeholder
		
		ds_weight += wheel.DT_influence
		rpm_speed += wheel.spin*wheel.DT_influence
		var w_torque_est: float = (torque_data[1]*wheel.DT_influence*g_ratio/rt_dsweight)/test_dsweight
		w_torque_est = min(w_torque_est,test_cgrip_rads*test_dsweight)
		
#		w_torque_est /= torque_data[1]*delta
		
		var w_overdrive: float = max(w_torque_est/(torque_data[1]/(g_ratio/hz_scale)) -1.0,0)
#		w_overdrive = 10

		var weighed_grip: float = (test_cgrip_rads*wheel.DT_influence*g_ratio/rt_dsweight)/test_dsweight

		var c_grip_od: float = test_cgrip_rads/(1.0/(w_overdrive/wheel.TR_spin_resistence_rate +1))
#		var c_grip_od: float = weighed_grip/(1.0/(w_overdrive +1))
		var acceleration: float = clamp(torque_data[0],-c_grip_od,c_grip_od)

		var dt_dist: float
		if EN_DriveForceBehavior == 1:
			var predicted_spin: float
			if gear<0:
				predicted_spin = drive_median +acceleration/g_ratio -wheel.MEASURE_aligning
				dt_dist = ((cs_rads/g_ratio + predicted_spin)/test_cstab)
			else:
				predicted_spin = drive_median -acceleration/g_ratio -wheel.MEASURE_aligning
				dt_dist = ((cs_rads/g_ratio - predicted_spin)/test_cstab)
		else:
			var predicted_spin: float
		
			if gear<0:
				predicted_spin = wheel.spin +acceleration/g_ratio -wheel.MEASURE_aligning
				dt_dist = ((cs_rads/g_ratio + predicted_spin)/test_cstab)
			else:
				predicted_spin = wheel.spin -acceleration/g_ratio -wheel.MEASURE_aligning
				dt_dist = ((cs_rads/g_ratio - predicted_spin)/test_cstab)

		if not EN_CanStall and rpm<=EN_IdleRPM:
			dt_dist *= 0
			
		var align_t: float = clamp(dt_dist*min(g_ratio -1.0,rads2rpm) +acceleration,-c_grip_od,c_grip_od)
		
		var od_red: float = max(abs(align_t/rads2rpm) -w_torque_est/rads2rpm,0)
		
		wheel.dt_overdrive = w_overdrive
#		wheel.dt_overdrive = 1
		if wheel.name == "rl":
			_debug.queue[" dt_dist"] = dt_dist
			_debug.queue[" w_overdrive"] = w_overdrive

		var w_torque: float = (align_t*wheel.DT_influence*g_ratio/rt_dsweight)/test_dsweight
#		w_torque = clamp(w_torque,-test_cgrip_rads,test_cgrip_rads)

		if gear<0:
			wheel.dt_torque = -w_torque
		else:
			wheel.dt_torque = w_torque
			
		
			
		if wheel.df_lockto:
			# bar
			var diff_median: float = (wheel.spin + wheel.df_lockto.spin)/2.0
			var diff_wheel_travel_distance: float = (wheel.MEASURE_travelled - wheel.df_lockto.MEASURE_travelled)/2.0
			var diff_dampening_torque: float = wheel.spin - diff_median
			var diff_stabilise: float = (1.0 -(1.0/(abs(diff_median*delta*wheel.WL_size) +1)))
			
			var locking_torque: float = wheel.DIFF_Locking_Preload/60.0
			if w_torque>0:
				locking_torque += w_torque*wheel.DIFF_Locking_Power*(w_overdrive +1)
			else:
				locking_torque -= w_torque*wheel.DIFF_Locking_Coast*rev_down_difference*(w_overdrive +1)
				
			locking_torque /= w_overdrive +1
			
			diff_wheel_travel_distance = clamp(diff_wheel_travel_distance,-locking_torque,locking_torque)
			diff_dampening_torque = clamp(diff_dampening_torque,-locking_torque,locking_torque)
			
			wheel.MEASURE_travelled -= diff_wheel_travel_distance*diff_stabilise
			wheel.dt_torque -= diff_wheel_travel_distance
			wheel.dt_torque -= diff_dampening_torque*(w_overdrive +1)
			
			# central
			var awd_diff_dampening_torque: float = diff_median - central_median
			var awd_diff_central_travelled: float = (wheel.MEASURE_travelled + wheel.df_lockto.MEASURE_travelled)/2.0
			var awd_diff_wheel_travel_distance: float = awd_diff_central_travelled - central_travel_median
			var awd_diff_stabilise: float = (1.0 -(1.0/(abs(central_median*delta*wheel.WL_size) +1)))

			var awd_locking_torque: float = DIFF_Central_Locking_Preload/60.0
			if w_torque>0:
				awd_locking_torque += w_torque*DIFF_Central_Locking_Power*(w_overdrive +1)
			else:
				awd_locking_torque -= w_torque*DIFF_Central_Locking_Coast*rev_down_difference*(w_overdrive +1)

			awd_locking_torque /= w_overdrive +1

			awd_diff_wheel_travel_distance = clamp(awd_diff_wheel_travel_distance,-awd_locking_torque,awd_locking_torque)
			awd_diff_dampening_torque = clamp(awd_diff_dampening_torque,-awd_locking_torque,awd_locking_torque)

			wheel.MEASURE_travelled -= awd_diff_wheel_travel_distance*awd_diff_stabilise
			wheel.dt_torque -= awd_diff_wheel_travel_distance/2.0
			wheel.dt_torque -= awd_diff_dampening_torque*(w_overdrive +1)
			
#		wheel.spin = 20
		wheel.dt_braking = wheel.DT_BrakeTorque*min(wheel.DT_BrakeBias*analog_decelerate + wheel.DT_HandbrakeBias*analog_handbrake,1)*abs_thresholded

		apply_impulse(wheel.impulse[1], wheel.impulse[0])
		
		OUTPUT_total_compressed += wheel.OUTPUT_compressed
		MEASURE_driven_wheel_radius += wheel.WL_size*wheel.DT_influence
		
		wheels_position += wheel.AN_hub.global_position
	
	wheels_position /= wheels_count
	MEASURE_driven_wheel_radius /= ds_weight/2.0
	
	rpm_windspeed = (linear_velocity.length()*g_ratio/MEASURE_driven_wheel_radius)*rads2rpm*2.0
	prev_gear_rpm_speed = (linear_velocity.length()*prev_g_ratio/MEASURE_driven_wheel_radius)*rads2rpm*2.0
	_debug.queue[" prev_gear_rpm_speed"] = prev_gear_rpm_speed

	OUTPUT_total_compressed /= wheels_count
	
	$DB_clutchslip.volume_db = max(linear_to_db(DB_SLIP*0.5),-80)
	rt_dsweight = ds_weight
	rpm_speed *= (rads2rpm/ds_weight)*g_ratio
#	rpm_speed = (central_median*rads2rpm)*g_ratio
	if gear<0:
		rpm_speed = -rpm_speed
	
	var est_rpm_dist: float = rpm - rpm_speed
	rpm -= clamp(est_rpm_dist,-test_cgrip,test_cgrip)
	if est_rpm_dist>test_cgrip:
		dt_dropping = 1
	elif est_rpm_dist<-test_cgrip:
		dt_dropping = -1
	else:
		dt_dropping = 0
	rpm += clamp(est_rpm_dist,-test_cgrip,test_cgrip)
	
	if not EN_CanOverRev and rpm_speed>EN_MaxRPM:
		rpm_speed = EN_MaxRPM
	elif not EN_CanStall and rpm_speed<EN_IdleRPM:
		rpm_speed = EN_IdleRPM
		
	var rpm_dist: float = rpm - rpm_speed
	rpm -= clamp(rpm_dist,-test_cgrip,test_cgrip)
	
#	rpm = 20000
	
	_debug.queue[" gear"] = gear
	_debug.queue[" rpm"] = rpm
	_debug.queue[" rpmspeed"] = rpm_speed
	_debug.queue[" rpm gs"] = rpm - past_rpm
	past_rpm = rpm
	$enon.volume_db = max(linear_to_db(throttle),-80.0)
	$enoff.volume_db = max(linear_to_db(1.0 -throttle),-80.0)
	$enon.max_db = $enon.volume_db
	$enoff.max_db = $enoff.volume_db
	
	$enon.pitch_scale = max(rpm,800)/8000.0
	$enoff.pitch_scale = max(rpm,800)/8000.0
#	print(rpm_speed)
