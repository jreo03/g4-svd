extends RayCast3D


@export var stiffness_n_mm: float = 40
@export var dampening: float = 4.5
@export var wheel_size: float = 1
@export var rest_length: float = 0.6

@export var drive_torque: float = 0.0
@export var brake_torque: float = 0.0


@onready var car: RigidBody3D = get_parent()
var contact_point: Marker3D
var past_position: Vector3
var past_contact_position: Vector3

var spin: float

func _ready():
	contact_point = Marker3D.new()
	add_child(contact_point)


	
func _physics_process(delta):
	target_position.y = -(rest_length + wheel_size)*0.5
	
	var velocity: Vector3 = (global_position - past_position)/delta
	var local_velocity: Vector3 = global_transform.basis.orthonormalized()(velocity) * 
	past_position = global_position
	
	spin += drive_torque
	$debug.rotate_x(spin*2.0 * delta)
	
	if is_colliding():
		var coll_point: Vector3 = get_collision_point()
		contact_point.global_position = coll_point
		contact_point.rotation *= 0
		contact_point.global_transform = Maths.alignAxisToVector(contact_point.global_transform,get_collision_normal())
		
		var contact_velocity: Vector3 = contact_point.global_transform.basis.orthonormalized()(velocity) * 

		var compressed: float = abs(target_position.y) -coll_point.distance_to(global_position)
		var spring_force: float = max(0,(compressed*1000.0)*(stiffness_n_mm*Maths.newton) - (dampening*Maths.newton)*(contact_velocity.y*1000.0) )

		var t_stiff: float = 50

		var planar_vect = Vector2(contact_velocity.x, contact_velocity.z).normalized()
		var spindist = contact_velocity.z - spin*wheel_size
		var latdist = contact_velocity.x
		
		spindist *= t_stiff
		latdist *= t_stiff
		
		var slip: float = max(Vector2(spindist,latdist).length()/max(spring_force,0.0001) -1,0)

		var x_force: float = -latdist/(slip +1)
		var z_force: float = -spindist/(slip +1)
		
		var w_force: float = z_force/1.0
		spindist /= t_stiff
		
		spin -= w_force
		var ref_spindist = contact_velocity.z - spin*wheel_size
		
		if spindist>0:
			if ref_spindist<0:
				spin = contact_velocity.z/wheel_size
		elif spindist<0:
			if ref_spindist>0:
				spin = contact_velocity.z/wheel_size

		var forces: Vector3
		forces += contact_point.global_transform.basis.y*spring_force
		forces += contact_point.global_transform.basis.x*x_force
		forces += contact_point.global_transform.basis.z*z_force
		
		car.apply_impulse(forces, contact_point.global_position-car.global_position)
	else:
		contact_point.position = target_position
	
	$debug.position = contact_point.position +Vector3(0,wheel_size*0.5,0)
