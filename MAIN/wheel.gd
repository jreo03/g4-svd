extends RayCast3D
class_name SVD_WHEEL
var readyed: bool

@export var Camber: float:
	set(val):
		Camber = val
		if position.x>0:
			$angled/steering_pivot/camber.rotation_degrees.z = -val
		else:
			$angled/steering_pivot/camber.rotation_degrees.z = val
@export var Toe: float:
	set(val):
		Toe = val
		if position.x>0:
			$angled/steering_pivot.rotation_degrees.y = -val
		else:
			$angled/steering_pivot.rotation_degrees.y = val

@export_enum("Single Point", "Multi-Rays", "ShapeCast") var SUS_raytype: int
@export var SUS_shapecast_node: NodePath:
	set(val):
		SUS_shapecast_node = val
		if !readyed:
			await self.ready
		trSUS_shapecast_node = get_node(val)
		trSUS_shapecast_node.add_exception_rid(car.get_rid())
		REFRESH_AXLE()
		
@export var SUS_shapecast_cylinder_width_emulation: float = 0.18
var trSUS_shapecast_node: ShapeCast3D

func REFRESH_AXLE():
	if trSUS_shapecast_node:
		trSUS_shapecast_node.position = Vector3(0.0, -SUS_rest_height, 0.0)
	if SRC_ray:
		SRC_ray.position.y = SUS_compression_length

	
@export_enum("Radial Distance", "Vertical Distance") var SUS_shapecast_compression_mode: int

@export var SUS_multiray_count: int = 5
@export var SUS_multiray_max_sweep_angle: float = 45
@export var SUS_multiray_safe_distance: float = 0.1
@export var SUS_multiray_inset_percent: float = 1.0
@export var SUS_shapecast_hq_detection: bool

@export var SUS_spring_stiffness: float = 40
@export var SUS_dampening: float = 4.5
@export var SUS_compression_length: float = 0.3:
	set(val):
		SUS_compression_length = val
		REFRESH_AXLE()
	
@export var SUS_rest_height: float = 0.05:
	set(val):
		SUS_rest_height = val
		REFRESH_AXLE()

@export var SUS_max_compression_length: float = 0.1

@export var SUS_tyre_stiffness: float
@export var SUS_tyre_damp: float
@export var SUS_tyre_height: float = 0.1

@export_enum("Past Axle Position (Realistic)", "Y Velocity (Absorbs bumps)") var SUS_damper_behaviour: int
@export var SUS_angle_of_attack: Vector3:
	set(val):
		SUS_angle_of_attack = val
		$angled.rotation_degrees = val

@export var SR_SteerAngleDegrees_Left: float
@export var SR_SteerAngleDegrees_Right: float
@export var SR_Contact_Patch_Conditioning: bool
@export var SR_Steering_Pivot_Offset: Vector3:
	set(val):
		SR_Steering_Pivot_Offset = val
		$angled/steering_pivot.position = SR_Steering_Pivot_Offset
		$angled/steering_pivot/camber.position = -SR_Steering_Pivot_Offset

@export var SR_Steering_Caster_Angles: Vector3:
	set(val):
		SR_Steering_Caster_Angles = val
		$angled/steering_pivot/camber/hub.rotation_degrees.x = -val.x

@onready var SR_steering_pivot: Node3D = $angled/steering_pivot
@onready var SR_steering_pivot_base: Node3D = $angled/alignment_reference/steering_pivot_base

@onready var SR_alignment_ref: Node3D = $angled/alignment_ref
@onready var SR_circle_ref: Node3D = $angled/alignment_ref/pitched
@onready var SR_contact_ref: Node3D = $angled/alignment_ref/pitched/contact_point
@onready var SR_difference_ref: Node3D = $contact_point_space_ref
var SR_steer_ref: float

@export var WL_radius: float = 0.29
@export var WL_weight: float = 1.0

@export var TR_Model: SVD_TMODEL:
	set(val):
		TR_Model = val
		TR_MDL_peak_y = val.TR_MDL_peak_y
		TR_MDL_peak_x = val.TR_MDL_peak_x
		TR_MDL_aspect_ratio = val.TR_MDL_aspect_ratio
		TR_MDL_shape_x = val.TR_MDL_shape_x
		TR_MDL_shape_y = val.TR_MDL_shape_y
		TR_MDL_linear = val.TR_MDL_linear
		TR_MDL_friction = val.TR_MDL_friction
		TR_MDL_curving = val.TR_MDL_curving
		TR_MDL_curve_distance = val.TR_MDL_curve_distance

@export var TR_vertical_softness: bool
@export var TR_elasticity_physics: bool
@export var TR_simplified: bool
@export var TR_stiffness: float = 40
@export var TR_deform_factor: float = 1
@export var TR_deform_threshold: float = 1
@export var TR_spin_resistence_rate: float = 20
@export var TR_friction_multiplier: float = 1
@export var TR_height: float = 0.1
@export var TR_soft_tyre: bool
@export var TR_elasticity: float = 2500
@export var TR_dampening: float = 25
@export var TR_grip_response: float = 100

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
var TR_MDL_curving: float = 1
var TR_MDL_curve_distance: float = 1

var SP_resource: SVD_surface
var SP_roll_resist: float
var SP_roll_resist_constant: float
var SP_max_roll_resist: float # 0 = infinite
var SP_friction: float = 1.0
var SP_fake_bump_height: float
var SP_fake_bump_frequency: float
var SP_dampening: float

var STATE_surface_checked: bool


@export var DT_influence: float = 1
@export var DT_BrakeTorque: float = 5000
@export var DT_BrakeBias: float = 1
@export var DT_HandbrakeBias: float = 0

@export var AN_spinning_meshes: Array # (Array, NodePath)
@export var AN_fixed_meshes: Array # (Array, NodePath)
#export(Array, NodePath) var AN_steering_meshes: Array
var a_s_m: Array
var a_f_m: Array
#var a_s2_m: Array

@onready var car: RigidBody3D = get_parent()

var spin: float
var diff_spin: float
var total_w_weight: float

var SRC_ray: RayCast3D
var MRC_past_bottom_compressed: float


var prev_compressed: float
var predict_prev_compressed: float

var HUB_pos: float
var HUB_velocity: float
var HUB_thrust: float
var HUB_inertia_thrust: float
var HUB_inertia: float
var HUB_past_pos: float
@export var AR_swaybar_link: NodePath:
	set(val):
		AR_swaybar_link = val
		if !readyed:
			await self.ready
		rtAR_swaybar_link = get_node(val)
	
var rtAR_swaybar_link: SVD_WHEEL
@export var AR_swaybar_stiffness: float = 0
@export var AR_swaybar_dampening: float = 0
var AR_hub_difference: float
var AR_hub_difference_past: float
@onready var P_angled: Marker3D = $angled
@onready var P_steer: Marker3D = $angled/steering_pivot
@onready var P_camber: Marker3D = $angled/steering_pivot/camber
@onready var SR_alignment_axis: Marker3D = $angled/alignment_axis

@export var HUB_max_travel: float = 0.3
@export var HUB_min_travel: float = -10.1
@export var HUB_spring_rest: float = 0.45
@onready var AN_hub: Marker3D = $angled/steering_pivot/camber/hub
@onready var AN_spin: Marker3D = $angled/steering_pivot/camber/hub/spin
@onready var AN_fixed: Marker3D = $angled/steering_pivot/camber/hub/fixed

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
var MEASURE_travelled_awd: float

var dt_overdrive: float
var dt_torque: float
var dt_substantialtorque: float
var dt_braking: float

const newton: float = 0.0169946645619466

@onready var c_v: Marker3D = $angled/c_v
@onready var p_p: MeshInstance3D = $angled/c_v/patch_pos

var impulse: Array = [Vector3(),Vector3()]
var predict_impulse: Array = [Vector3(),Vector3()]

var patch_pos: Vector3

var OUTPUT_skidding: float
var OUTPUT_difference: float
var OUTPUT_stressing: float
var OUTPUT_grip: float
var OUTPUT_compressed: float
var OUTPUT_hub_vertical_velocity: float
var OUTPUT_aligned_spin: float
var past_global_axle_pos: Vector3
var predicted_s_force: float
var past_point: float

var df_lockto: SVD_WHEEL
@export var DIFF_lock_to: NodePath:
	set(val):
		DIFF_lock_to = val
		if !readyed:
			await self.ready
		df_lockto = get_node(DIFF_lock_to)

@export var DIFF_Locking_Preload: float
@export_range(0,1) var DIFF_Locking_Power: float
@export_range(0,1) var DIFF_Locking_Coast: float
@export var DIFF_Viscousity: float = 2.0

var rt_instanced_rays: Array

func _ready():
	if SUS_raytype == 1:
		for i in range(SUS_multiray_count):
			var it: float
			var c_ang: float
			
			if SUS_multiray_count<=1:
				it = 1
				c_ang = 0
			else:
				it = float(i)/float(SUS_multiray_count -1)
				c_ang = lerp(-SUS_multiray_max_sweep_angle,SUS_multiray_max_sweep_angle,it)
			
			var r: RayCast3D = RayCast3D.new()
			r.process_physics_priority = process_physics_priority -1
			AN_hub.add_child(r)
			r.enabled = true
			r.rotation_degrees.x = c_ang
			r.target_position.y = -WL_radius - SUS_multiray_safe_distance -(WL_radius*SUS_multiray_inset_percent)
			r.translate_object_local(Vector3(0,WL_radius*SUS_multiray_inset_percent,0))
			r.add_exception_rid(car.get_rid())
			rt_instanced_rays.append(r)
	
	SRC_ray = RayCast3D.new()
	SRC_ray.process_physics_priority = process_physics_priority -1
	P_angled.call_deferred("add_child", SRC_ray)
	SRC_ray.add_exception_rid(car.get_rid())
	SRC_ray.enabled = SUS_raytype == 0
	
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

	REFRESH_AXLE()
	readyed = true

var tyre_density: float = 100.0
var tyre_elasticity: float = 30.0
var tyre_damp: float = 60.0
var tyre_v_velocity: float
var tyre_height: float = 0.5

var psdb: PhysicsDirectBodyState3D

func _physics_process(delta):
	if not car.PSDB:
		return

	var radius_mod: float = WL_radius
	var added_rest: float = SUS_compression_length + SUS_rest_height
	var comp_max_pos: float = SUS_compression_length - SUS_max_compression_length

	var SP_bump_dipped: float = SP_fake_bump_height*(sin(global_position.x*SP_fake_bump_frequency) + cos(global_position.z*SP_fake_bump_frequency) +2)/4.0

	var sus_direction: Basis = global_transform.basis.orthonormalized()
	psdb = car.PSDB
	MEASURE_aligning = 0.0
	$angled/c_v.visible = car.DB_forces_visible
	
	var real_torque: float = dt_torque
	var real_brake: float = dt_braking
	var real_dt_overdrive: float = dt_overdrive#/(delta*(TR_spin_resistence_rate/60.0))
	
	if dt_braking>0:
		real_torque -= real_torque/max(abs(real_torque)/dt_braking,1)

	if OUTPUT_aligned_spin>0:
		real_brake = clampf(dt_braking - dt_torque, 0, dt_braking)
	else:
		real_brake = clampf(dt_braking + dt_torque, 0, dt_braking)

	real_torque *= delta*(TR_spin_resistence_rate/60.0)
	real_brake *= delta*(TR_spin_resistence_rate/60.0)

	#_debug.queue["%s DIFF_Locking_Power" % name] = DIFF_Locking_Power
	#_debug.queue["%s DIFF_Locking_Coast" % name] = DIFF_Locking_Coast
	#_debug.queue["%s DIFF_Locking_Preload" % name] = DIFF_Locking_Preload

	var hz_scale: float = delta*60.0
	spin += real_torque/(real_dt_overdrive +1.0)
	spin += dt_substantialtorque
	MEASURE_aligning += dt_substantialtorque
	if real_brake>0:
		spin -= spin/max(abs(spin)/(real_brake/(real_dt_overdrive +1.0)),1)
		MEASURE_aligning -= spin/max(abs(spin)/(real_brake/(real_dt_overdrive +1.0)),1)
		
	var thing: float = 1.0/(real_dt_overdrive +1.0)
	
	var real_wheelsize: float = WL_radius
	
	SRC_ray.target_position.y = -(added_rest + WL_radius)
	
	var velocity: Vector3 = psdb.get_velocity_at_local_position(global_position - car.global_position)
	var local_velocity: Vector3 = velocity*sus_direction
	
	if STATE_brake_locked:
		AN_spin.rotate_x(spin*delta)
	
	total_w_weight = WL_weight*1.0
	
	var c_normal: Vector3 = Vector3(0,1,0)
	var c_point: Vector3 = global_position +sus_direction*SRC_ray.target_position +sus_direction.y*SUS_compression_length
	var c_axis: Basis

	diff_spin = spin
	
	# apply suspension
	var grounded: bool
	if SUS_raytype == 0:
		grounded = SRC_ray.is_colliding()
	elif SUS_raytype == 2:
		grounded = trSUS_shapecast_node.is_colliding()
	
	HUB_past_pos = HUB_pos
	
	var mrmax_compress: float = -INF
	var mr_maxc_ray: RayCast3D
	var RLENGTH: float = WL_radius# + WL_size*SUS_multiray_inset_percent/2.0
	var bottomed_compressed: float
	var bottomed: bool
	var rim_collided: bool
	var rim_compressed: float
	var mrc_bottom_damp_needed: float
	var surface_body: PhysicsBody3D

	if SUS_raytype == 1:
		for ray in rt_instanced_rays:
			var rdist: float = RLENGTH - AN_hub.global_position.distance_to(ray.get_collision_point()) - SP_bump_dipped
			if rdist>mrmax_compress:
				mrmax_compress = rdist
				mr_maxc_ray = ray
				c_normal = ray.get_collision_normal()
				c_point = ray.get_collision_point() -c_normal*SP_bump_dipped

				if not surface_body:
					surface_body = ray.get_collider()
			if ray.is_colliding():
				grounded = true

		var comped: float = HUB_pos - mrmax_compress
		bottomed_compressed = max(-(HUB_pos - mrmax_compress - comp_max_pos), 0)
		bottomed = bottomed_compressed>0.0
		rim_collided = (bottomed_compressed>SUS_tyre_height/2.0 and TR_vertical_softness) or (bottomed_compressed>0 and !TR_vertical_softness)
		
		mrc_bottom_damp_needed = bottomed_compressed - MRC_past_bottom_compressed
		
		MRC_past_bottom_compressed = bottomed_compressed
	
	var stiff: float = SUS_spring_stiffness*newton*1000.0
	var ar_stiff: float = AR_swaybar_stiffness*newton*1000.0
	var ar_damp: float = AR_swaybar_dampening*1000.0
	var damp: float = SUS_dampening*1000.0
	
	var t_vstiff: float = max(SUS_tyre_stiffness*newton*1000.0,0.0001)
	var t_vdamp: float = SUS_tyre_damp*1000.0
	
	var t_strength: float = 1.0
	var t_dampmod: float = 1.0
	
	if TR_vertical_softness:
		if t_vstiff>0 and stiff>0:
			t_strength = t_vstiff/(stiff + t_vstiff)
			t_dampmod = max(t_vdamp/(damp + t_vdamp),delta)

	var t_strength_inv: float = 1.0 -t_strength
	
	if mr_maxc_ray:
		var decomp_dist: float = RLENGTH - AN_hub.global_position.distance_to(mr_maxc_ray.get_collision_point())
		var decompress: float = -min(decomp_dist,0)
		var hubdist: float = max(added_rest - HUB_pos,0)
		
		if TR_vertical_softness:
			HUB_pos += decompress - lerp(mrmax_compress, -hubdist, t_strength_inv)*t_dampmod
		else:
			HUB_pos += decompress - mrmax_compress
	
		HUB_pos = max(HUB_pos, comp_max_pos)
	
	HUB_pos = min(HUB_pos, added_rest)
	
	if SR_Contact_Patch_Conditioning:
		trSUS_shapecast_node.global_position = P_camber.global_position
		trSUS_shapecast_node.global_rotation = P_camber.global_rotation
		trSUS_shapecast_node.position += P_angled.transform.basis.y*(-P_steer.position.y -SUS_rest_height)
		
		SR_alignment_ref.global_position = P_camber.global_position
		SR_alignment_ref.position.y += -P_steer.position.y
		SR_alignment_ref.rotation_degrees = SR_Steering_Caster_Angles
		SR_alignment_ref.rotation_degrees.z += P_camber.rotation_degrees.z
		
		SR_circle_ref.rotation_degrees.x = -SR_alignment_ref.rotation_degrees.x
		
		SR_circle_ref.rotation.y = SR_steer_ref
		
		SR_contact_ref.position.y = -WL_radius

		SRC_ray.global_position = SR_contact_ref.global_position
		SRC_ray.position.y += SUS_compression_length + WL_radius
		
		SR_alignment_axis.global_rotation = AN_hub.global_rotation
#		SR_alignment_axis.rotate_object_local(Vector3.RIGHT, deg2rad(-SR_Steering_Caster_Angles.x))

	STATE_grounded = grounded
	
	if grounded:
		var c_point_dist: float
		if SUS_raytype == 0:
			surface_body = SRC_ray.get_collider()
			c_normal = SRC_ray.get_collision_normal()
			c_point = SRC_ray.get_collision_point() - c_normal*SP_bump_dipped
			c_point_dist = SRC_ray.global_position.distance_to(c_point)
		elif SUS_raytype == 2:
#			sus_direction = trSUS_shapecast_node.global_transform.basis.orthonormalized()
			surface_body = trSUS_shapecast_node.get_collider(0)
			var artificial_pos: Vector3 = SRC_ray.global_position - sus_direction.y*added_rest
			if SUS_shapecast_hq_detection:
				var colliders: Array
				c_normal = Vector3.ZERO
				c_point = -c_normal*SP_bump_dipped
				var sum: float
				for i in range(trSUS_shapecast_node.get_collision_count()):
					var i_comp: float = WL_radius -artificial_pos.distance_to(trSUS_shapecast_node.get_collision_point(i))
#					var i_comp: float = WL_radius -sus_direction.xform_inv(artificial_pos - c_point).y

					i_comp -= (abs(((artificial_pos - trSUS_shapecast_node.get_collision_point(i))*sus_direction).x)*WL_radius)/SUS_shapecast_cylinder_width_emulation
					if i_comp>0:
						sum += i_comp
						colliders.append([trSUS_shapecast_node.get_collision_normal(i), trSUS_shapecast_node.get_collision_point(i), i_comp])
				
				if sum>0:
					for i in colliders:
						c_normal += i[0]*i[2]
						c_point += i[1]*i[2]/sum
					c_normal = c_normal.normalized()
				else:
					c_point = trSUS_shapecast_node.get_collision_point(0) -c_normal*SP_bump_dipped
					c_normal = trSUS_shapecast_node.get_collision_normal(0)
				
#				c_point -= sus_direction.x*sus_direction.xform_inv(c_point - artificial_pos).x
			else:
				c_point = trSUS_shapecast_node.get_collision_point(0) -c_normal*SP_bump_dipped
				c_normal = trSUS_shapecast_node.get_collision_normal(0)
			
			c_point -= c_normal*SP_bump_dipped
			
			#$_touches.global_position = c_point
			
			if SUS_shapecast_compression_mode == 0:
				c_point_dist = max(artificial_pos.distance_to(c_point), 0.0) # distance to shape
			else:
				var circled: float = min(abs(((artificial_pos - c_point)*sus_direction).z)/WL_radius + max(abs(((artificial_pos - c_point)*sus_direction).x) -SUS_shapecast_cylinder_width_emulation, 0)*90.0, 1.0)
				c_point_dist = ((artificial_pos - c_point)*sus_direction).y + WL_radius*(asin(circled)/(PI/2.0)) # distance to spring mount
				if ((artificial_pos - c_point)*sus_direction).y<0:
					c_normal *= -1.0

		c_axis = Basis(c_normal.cross(SR_alignment_axis.global_transform.basis.z), c_normal, SR_alignment_axis.global_transform.basis.x.cross(c_normal)).orthonormalized()
 		
		c_v.global_position = c_point
		c_v.global_transform.basis = c_axis

		var world_offsetted: Vector3 = c_v.global_position - car.global_position
		var patch_global_velocity: Vector3 = psdb.get_velocity_at_local_position(world_offsetted)
		patch_global_velocity += (SR_contact_ref.global_position - SR_difference_ref.global_position)/delta
		
		var patch_velocity: Vector3 = patch_global_velocity*(c_axis.orthonormalized())
		
		if !STATE_surface_checked:
			STATE_surface_checked = true
			
		if surface_body and "surface_properties" in surface_body and !SP_resource == surface_body.surface_properties:
			SP_resource = surface_body.surface_properties
			SP_roll_resist = surface_body.surface_properties.roll_resist
			SP_roll_resist_constant = surface_body.surface_properties.roll_resist_constant
			SP_max_roll_resist = surface_body.surface_properties.max_roll_resist
			SP_friction = surface_body.surface_properties.friction
			SP_dampening = surface_body.surface_properties.dampening
			SP_fake_bump_height = surface_body.surface_properties.fake_bump_height
			SP_fake_bump_frequency = surface_body.surface_properties.fake_bump_frequency

		real_brake += min(SP_roll_resist*abs(spin) + SP_roll_resist_constant, SP_max_roll_resist)

		var spring_force: float
		var t_stiff_y: float = TR_elasticity
		var t_damp_y: float = TR_dampening
		var t_stiff_x: float = t_stiff_y*TR_MDL_aspect_ratio
		var t_damp_x: float = t_damp_y*TR_MDL_aspect_ratio

		var travel_angle: float = min(abs(patch_velocity.x)/(abs(spin*(WL_radius*2.0)) +1),1)
		
		var compressed: float = max(added_rest - HUB_pos,0)

		var axle_vel: float = HUB_past_pos - HUB_pos

		OUTPUT_compressed = compressed

		if SUS_raytype == 0:
			var t_t: float = WL_radius - c_point_dist
			if t_t>-comp_max_pos:
				bottomed = true
				t_t = -comp_max_pos
			if TR_vertical_softness:
				var HUB_target: float = lerp(added_rest, -t_t, t_strength)
				
				HUB_pos = lerp(HUB_pos, HUB_target, t_dampmod)

				var tyre_fell: float = max(t_t + HUB_pos -SUS_tyre_height,0.0)
				
				HUB_pos -= tyre_fell
				HUB_pos = max(HUB_pos, -t_t)
				
#				radius_mod -= HUB_pos +t_t

			else:
				HUB_pos = -t_t
			
		elif SUS_raytype == 2:
			var t_t: float = -(added_rest -WL_radius) - c_point_dist
			if t_t>-comp_max_pos:
				bottomed = true
				t_t = -comp_max_pos
			if TR_vertical_softness:
				
				var HUB_target: float = lerp(added_rest, -t_t, t_strength)
				
				HUB_pos = lerp(HUB_pos, HUB_target, t_dampmod)

				var tyre_fell: float = max(t_t + HUB_pos -SUS_tyre_height, 0.0)
				
				HUB_pos -= tyre_fell

				HUB_pos = max(HUB_pos,-t_t)
			else:
				HUB_pos = -t_t
		
		HUB_pos = min(HUB_pos, added_rest)
		
		compressed = max(added_rest - HUB_pos,0)

		if SUS_raytype == 0:
			bottomed_compressed = max(comp_max_pos - c_point_dist + WL_radius,0)
			rim_compressed = max(bottomed_compressed -SUS_tyre_height/2.0,0)
			rim_collided = bottomed_compressed>SUS_tyre_height/2.0
		elif SUS_raytype == 2:
			bottomed_compressed = max(comp_max_pos - (added_rest - (WL_radius -c_point_dist)), 0)
			rim_compressed = max(bottomed_compressed -SUS_tyre_height/2.0,0)
			rim_collided = bottomed_compressed>SUS_tyre_height/2.0
		
		axle_vel = HUB_past_pos - HUB_pos
		var bottomed_axle_vel: float = past_point - c_point_dist
		past_point = c_point_dist
		
		if SUS_damper_behaviour == 1:
			axle_vel = -patch_velocity.y*delta
		
		var AR_hub_difference_vel: float = AR_hub_difference - AR_hub_difference_past
		
		spring_force = max(0.0, compressed*stiff + damp*axle_vel -AR_hub_difference*ar_stiff - ar_damp*AR_hub_difference_vel)
		if SUS_raytype == 0:
			if TR_vertical_softness:
				if rim_collided:
					spring_force = max(0.0, (bottomed_compressed - TR_height/2.0)*stiff + bottomed_compressed*t_vstiff + (car.mass/car.wheels_count)*-patch_velocity.y)
					psdb.transform.origin += c_normal*rim_compressed/car.wheels_count
				elif bottomed:
					spring_force += max(0.0, bottomed_compressed*t_vstiff + t_vdamp*bottomed_axle_vel)
			else:
				if bottomed:
					spring_force = max(0.0, bottomed_compressed*stiff + compressed*stiff + (car.mass/car.wheels_count)*-patch_velocity.y)
					psdb.transform.origin += c_normal*bottomed_compressed/car.wheels_count
		elif SUS_raytype == 2:
			bottomed_axle_vel = -patch_velocity.y/60.0
			if TR_vertical_softness:
				if rim_collided:
					spring_force = max(0.0, (bottomed_compressed - TR_height/2.0)*stiff + bottomed_compressed*t_vstiff + (car.mass/car.wheels_count)*-patch_velocity.y)
					psdb.transform.origin += c_normal*rim_compressed/car.wheels_count
				elif bottomed:
					spring_force += max(0.0, bottomed_compressed*t_vstiff + t_vdamp*bottomed_axle_vel)
			else:
				if bottomed:
					spring_force = max(0.0, bottomed_compressed*stiff + compressed*stiff + (car.mass/car.wheels_count)*-patch_velocity.y)
					psdb.transform.origin += c_normal*bottomed_compressed/car.wheels_count
		else:
			if TR_vertical_softness:
				if rim_collided:
					spring_force = max(0.0, bottomed_compressed*t_vstiff + compressed*stiff + (car.mass/car.wheels_count)*-patch_velocity.y)
					psdb.transform.origin += c_normal*rim_compressed/car.wheels_count
				elif bottomed:
					spring_force += max(0.0,bottomed_compressed*t_vstiff + t_vdamp*mrc_bottom_damp_needed)
			else:
				if bottomed:
					spring_force += max(0.0, bottomed_compressed*stiff + (car.mass/car.wheels_count)*-patch_velocity.y)
					psdb.transform.origin += c_normal*bottomed_compressed/car.wheels_count
			
		
		var byproduct: float
		# LOOHAHEAD
		
		var Agrip: float = INF

		# END

		var grip: float = min(spring_force ,Agrip)*TR_MDL_friction*TR_friction_multiplier*SP_friction
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
		var w_dist: float = (spin - patch_velocity.z/radius_mod)
		var predict_dist_x: float = patch_velocity.x/radius_mod
		var predict_slip: float

		STATE_brake_locked = real_brake>(grip*((TR_spin_resistence_rate*delta)))
#		STATE_brake_locked = true
		var predicted_grip: float
		if grip>0:
			var modifier: float = ((TR_spin_resistence_rate*delta)/(real_dt_overdrive +1.0))

			predict_slip = max((Vector2(w_dist,predict_dist_x).length()/modifier)/curved_grip_y -1,0)

			var predict_peaked: float = 1.0 -(1.0/(max(sqrt(pow(abs(w_dist),2.0) + pow(abs(predict_dist_x),2.0))/peaked_grip_y/modifier -1,0) +1.0))
			if not STATE_brake_locked:
				var p: float = predict_slip*((predict_peaked/TR_MDL_shape_y)*TR_MDL_peak_y*(1.0-TR_MDL_linear) + TR_MDL_linear) +1.0
				spin -= w_dist/p
				OUTPUT_aligned_spin = spin
				MEASURE_aligning -= w_dist/p
		
		var t_stiff: float = lerp(t_stiff_y,t_stiff_x,pow(travel_angle,0.5))
		var t_damp: float = lerp(t_damp_y,t_damp_x,pow(travel_angle,0.5))
		var t_response: float = lerp(TR_grip_response,TR_grip_response*TR_MDL_aspect_ratio,pow(travel_angle,0.5))
		
		var t_slip_raw: float = Vector2(patch_pos.x*t_stiff,patch_pos.z*t_stiff).length()/max(grip, 0.0001)
		var d_slip_raw: float = Vector2(patch_velocity.x*t_damp, (patch_velocity.z - spin*radius_mod)*t_damp).length()/max(grip, 0.0001)
		t_stiff /= min(TR_MDL_curving + t_slip_raw/TR_MDL_curve_distance, 1.0)
		t_damp /= min(TR_MDL_curving + d_slip_raw/TR_MDL_curve_distance, 1.0)

		# GROUND
		var b_force: float = (real_brake/(t_stiff*delta))/(TR_spin_resistence_rate)
		var t_force: float = (real_torque/(t_stiff*delta))/(TR_spin_resistence_rate)
		#_debug.queue["%s b_force" % name] = b_force

		# y
		var dist: Vector3
		var standstill: float = 1.0
		
		if spring_force>0:
			standstill /= abs(spin*TR_deform_factor/30.0)*(SP_dampening +1) +1.0
			
		standstill = clampf(standstill,delta,1)
		var patch_slip: float
		var patch_peaked: float
		
		var p_v_off: Vector3 = patch_velocity
		
		if TR_elasticity_physics:
			patch_pos.x -= patch_global_velocity.x*delta
			patch_pos.z -= patch_global_velocity.z*delta
			patch_pos -= c_axis.y*(patch_pos*c_axis).y

			var patch_dist: Vector3 = (patch_pos*c_axis)
			
			
			patch_pos -= c_axis[0]*patch_dist.x*(1.0 -standstill)

			if not STATE_brake_locked:
				var patch_clamp_z_amount: float = b_force
				var patch_clamp_z: float = max(abs(patch_dist.z) -patch_clamp_z_amount,0)
				if patch_dist.z<0:
					patch_pos += c_axis[2]*patch_clamp_z
				else:
					patch_pos -= c_axis[2]*patch_clamp_z
			
			if grip>0:
				patch_slip = max(patch_pos.length()/(curved_grip_y/t_stiff) -1,0)
				patch_peaked = 1.0 -(1.0/(max(patch_pos.length()/(peaked_grip/t_stiff) -1,0) +1.0))
				patch_pos /= patch_slip*((patch_peaked/TR_MDL_shape)*TR_MDL_peak*(1.0-TR_MDL_linear) + TR_MDL_linear) +1
			else:
				patch_pos.x = 0.0
				patch_pos.z = 0.0

			var spin_difference: float = (spin - patch_velocity.z/radius_mod)
			var spin_thrust: float = spin_difference*standstill/radius_mod


			if not STATE_brake_locked:
				if (spin_difference + real_torque)>0:
					spin_thrust = max(spin_thrust, real_torque)
				else:
					spin_thrust = min(spin_thrust, real_torque)
				
				var stiff_force: float = ((spin_thrust)/(t_stiff*delta))/(TR_spin_resistence_rate)
#				patch_pos += c_axis.z*spin_difference*radius_mod*delta
				patch_pos += c_axis.z*stiff_force
			
			var patch_dist_global: Vector3 = patch_pos*c_axis
	#		var patch_dist_global: Vector3 = patch_pos*c_axis # godot 4
			
			#_debug.queue["%s STATE_brake_locked" % name] = STATE_brake_locked
			
			dist = Vector3(
				p_v_off.x*t_damp*standstill -patch_dist_global.x*t_stiff,
				0,
				(p_v_off.z - spin*radius_mod)*t_damp*standstill  -patch_dist_global.z*t_stiff
	#			yd*t_damp -patch_dist_global.z*t_stiff
				)
		else:
			var ne_b_force: float = (real_brake/(t_response*delta))/(TR_spin_resistence_rate)
			var ne_t_force: float = (real_torque/(t_response*delta))/(TR_spin_resistence_rate)
			var braked: float

			if TR_simplified:
				var patch_clamp_z_amount: float = ne_b_force
				braked = clampf(-patch_velocity.z,-patch_clamp_z_amount,patch_clamp_z_amount)
			
				dist = Vector3(
					p_v_off.x*t_response*standstill,
					0,
					-ne_t_force*t_response  -braked*t_response
					)
			else:
				if not STATE_brake_locked:
					var patch_clamp_z_amount: float = ne_b_force
					braked = clampf(-patch_velocity.z,-patch_clamp_z_amount,patch_clamp_z_amount)
				
				dist = Vector3(
					p_v_off.x*t_response*standstill,
					0,
					(p_v_off.z - spin*radius_mod)*t_response*standstill -ne_t_force*t_response  -braked*t_response
					)


		if grip>0:
			if STATE_brake_locked:
				spin -= w_dist/(predict_slip +1)
				MEASURE_aligning -= w_dist/(predict_slip +1)

		var slip: float
		var peaked: float
		if grip>0:
			slip = max(dist.length()/curved_grip -1,0)
			peaked = 1.0 -(1.0/(max(dist.length()/peaked_grip -1,0) +1.0))
			
			OUTPUT_skidding = max((slip*curved_grip)*0.025*grip + (patch_slip*curved_grip)*0.05*grip,0)
			OUTPUT_difference = dist.length()
			OUTPUT_stressing = dist.length()*min(abs(spin),1)

		dist /= slip*((peaked/TR_MDL_shape)*TR_MDL_peak*(1.0-TR_MDL_linear) + TR_MDL_linear) +1

		if grip>0:
			$angled/c_v/lateral.scale.y = dist.x/40.0
			if $angled/c_v/lateral.scale.y>0:
				$angled/c_v/lateral.rotation_degrees.x = 91
			else:
				$angled/c_v/lateral.rotation_degrees.x = 89
			if slip>0:
				$angled/c_v/lateral.modulate = Color(1,0,0)
			else:
				var debug_effective: float = 1.0 +((dist.length() -curved_grip)/(curved_grip))
				var green: float = debug_effective
				var blue: float = 1.0 - debug_effective
				$angled/c_v/lateral.modulate = Color(0,green,blue)
			
			$angled/c_v/longitudinal.scale.y = dist.z/40.0
			if $angled/c_v/longitudinal.scale.y>0:
				$angled/c_v/longitudinal.rotation_degrees.x = 91
			else:
				$angled/c_v/longitudinal.rotation_degrees.x = 89
			if slip>0:
				$angled/c_v/longitudinal.modulate = Color(1,0,0)
			else:
				var debug_effective: float = 1.0 +((dist.length() -curved_grip)/(curved_grip))
				var green: float = debug_effective
				var blue: float = 1.0 - debug_effective
				$angled/c_v/longitudinal.modulate = Color(0,green,blue)

		$angled/c_v/suspforce.scale.y = spring_force/40.0

#		dist = dist.limit_length(grip)
		
		var forces: Vector3
		forces += c_axis.y*spring_force#*0.0
		var pforces: Vector3
		if grip>0:
			forces -= c_axis.x*dist.x
			forces -= c_axis.z*dist.z
			pforces -= c_axis.z*dist.z
		
#		var point: Vector3 = c_point-car.global_position
		var point: Vector3 = psdb.center_of_mass
		
		point -= (point - (c_point-car.global_position))/car.PHYS_form_factor
		
		$angled/imp_point.global_position = point +car.global_position
		
#		predict_impulse(point,pforces*hz_scale)
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
		HUB_pos = added_rest
		past_point = abs(SRC_ray.target_position.y)
		STATE_surface_checked = false
		HUB_pos -= AR_hub_difference/SUS_spring_stiffness
		
	AR_hub_difference_past = AR_hub_difference
	
	SR_difference_ref.global_position = SR_contact_ref.global_position
	
#	_debug.queue[" %s AR_hub_difference" % name] = AR_hub_difference
	
	p_p.position.x = patch_pos.x*c_axis[0].x + patch_pos.y*c_axis[0].z
	p_p.position.z = patch_pos.x*c_axis[2].x + patch_pos.y*c_axis[2].z

#	HUB_pos = min(HUB_pos,SUS_compression_length)
	
	# vv 2.0
	past_global_axle_pos = SRC_ray.global_position
	# end
	
	P_steer.position.y = -HUB_pos +SUS_compression_length
	if not STATE_brake_locked:
		AN_spin.rotate_x(spin*delta)

	MEASURE_travelled += spin
	MEASURE_travelled_awd += spin
