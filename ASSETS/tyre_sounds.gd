extends Node3D

@onready var car: RigidBody3D = get_parent()

func _ready():
	for i in get_children():
		i.play()
		
func set_volume(sound: AudioStreamPlayer3D, volume: float):
	volume = max(volume/2.0,0)
	sound.unit_db = linear_to_db(volume)
	sound.max_db = linear_to_db(volume)

func set_pitch(sound: AudioStreamPlayer3D, pitch: float):
	sound.pitch_scale = max(pitch,.01)

static func curve(amount,direction):
	if direction == "in":
		amount *= amount
	elif direction == "out":
		var a = 1.0 -amount*amount
		amount = 1.0 - a
		
	return amount
	
func _physics_process(delta):
	
	var base_skid: float = car.fx_skid/max(car.fx_wheel_weight,1)/1.0

	if base_skid<1:
		base_skid *= base_skid

	var base_lockup: float = (car.fx_lockup/(car.fx_skid +1))/max(car.fx_wheel_weight,1)/3.0
	if base_lockup<1 and car.fx_lockup>0:
		base_lockup = min(base_lockup*10,1)
	
	var skid_lockup: float = clamp(base_skid -1,0,1)*base_lockup

	var going: float = clamp(car.linear_velocity.length()/50.0,0,1)
	var hard = clamp(base_skid -2,0,1)

	var skid_fast: float = clamp(base_skid -1.0,0,1)*(1.0 -hard)*going
	var skid_slow: float = clamp(base_skid -1.0,0,1)*(1.0 -hard)*(1.0-going)

	var skid_fast_hard: float = clamp(base_skid -1.0,0,1)*hard*going*(1.0-skid_lockup)
	var skid_slow_hard: float = clamp(base_skid -1.0,0,1)*hard*(1.0-going)*(1.0-skid_lockup)

	var crunch: float = clamp(base_skid -0,0,1.0 -(skid_slow + skid_fast))
	

	var fxw: float = car.fx_wheelspin/(car.fx_skid +1)
	var fxr: float = car.fx_reversespin/(car.fx_skid +1)
	
	var base_wheelspin: float = fxw/max(car.fx_wheel_weight,1)/3.0
	if base_wheelspin<1 and fxw>0:
		base_wheelspin = min(base_wheelspin*10,1)

	var base_reversespin: float = fxr/max(car.fx_wheel_weight,1)/3.0
	if base_reversespin<1 and fxr>0:
		base_reversespin = min(base_reversespin*10,1)
	
#	base_wheelspin = max(base_wheelspin - car.fx_skid,0)
#	base_reversespin = max(base_reversespin - car.fx_skid,0)
	
	var hard_spin: float = clamp(base_wheelspin -1, 0, 1)
	var reverse_spin: float = clamp(base_reversespin -1, 0, 1)
	
	var slow_spin: float = clamp((base_wheelspin + base_reversespin),0,1)
	var fast_spin: float = clamp((base_wheelspin + base_reversespin),0,1)
	
	slow_spin = max(slow_spin -curve(hard_spin + reverse_spin,"in") -car.linear_velocity.length()/5.0 ,0)
	fast_spin = max(fast_spin -curve(hard_spin + reverse_spin,"in") - slow_spin,0)
	
	hard_spin = curve(hard_spin,"out")
	reverse_spin = curve(reverse_spin,"out")
	
	var lockup_hard: float = clamp(base_lockup -1,0,1)
	var lockup: float = clamp(base_lockup,0,1) -lockup_hard*lockup_hard
	lockup = curve(lockup,"out")
#	lockup_hard = curve(lockup_hard,"out")
	
	
#	slow_spin = max(slow_spin -1,0)
	
	set_pitch($slow_launch,1)
	set_pitch($fast_launch,1)
	set_pitch($hard_launch,1)
	set_pitch($reverse_wheelspin,1)
	set_pitch($lockup,1)
	set_pitch($lockup_hard,1)
	set_pitch($skid_slow,1)
	set_pitch($skid_slow_hard,1)
	set_pitch($skid_fast,1)
	set_pitch($skid_fast_hard,1)
	set_pitch($skid_lockup,1)
	set_pitch($crunch,0.7)
	set_volume($slow_launch,slow_spin*0)
	set_volume($fast_launch,fast_spin/1.5)
	set_volume($hard_launch,hard_spin)
	set_volume($reverse_wheelspin,reverse_spin/1.5)
	set_volume($lockup,lockup)
	set_volume($lockup_hard,lockup_hard*1.4)
	set_volume($crunch,min(crunch +slow_spin,1)/4.0)
	set_volume($skid_slow,skid_slow/1.25)
	set_volume($skid_fast,skid_fast)
	set_volume($skid_slow_hard,skid_slow_hard*1.7)
	set_volume($skid_fast_hard,skid_fast_hard*1.7)
	set_volume($skid_lockup,skid_lockup*1.4)
