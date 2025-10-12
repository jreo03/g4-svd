extends Node3D

var pitch = 0.0
var volume = 0.0
var fade = 0.0

var vacuum = 0.0
var maxfades = 0.0

@export var settings: Resource

var pitch_influence = 1.0

func play():
	for i in get_children():
		i.play()
#	stop()
		
func stop():
	for i in get_children():
		i.stop()

var childcount = 0

func _ready():
	play()
	childcount = get_child_count()
	maxfades = float(childcount-1.0)

func _physics_process(_delta):


	pitch = abs(Maths.rads_to_rpm(get_parent().engine_rads)*pitch_influence)/settings.pitch_calibrate
	
	volume = settings.off_volume +(get_parent().throttle*(1.0-settings.off_volume))
	fade = (get_node("100500").pitch_scale  -0.22222)*(settings.crossfade_influence +float(get_parent().gas)*settings.crossfade_throttle +float(Maths.rads_to_rpm(get_parent().engine_rads)>get_parent().vvt_rpm and get_parent().mimick_vvt)*settings.crossfade_vvt)
		
	if fade<0.0:
		fade = 0.0
	elif fade>childcount-1.0:
		fade = childcount-1.0
	
	vacuum = (get_parent().throttle-get_parent().gas)*4
	
	if get_parent().gas>get_parent().throttle:
		vacuum /= 2.0

	if vacuum<-1:
		 vacuum = -1.0
	if vacuum>1:
		 vacuum = 1.0
		

	var sfk = 1.0-(abs(vacuum)*get_parent().gas)
	
	if sfk<settings.vacuum_crossfade:
		 sfk = settings.vacuum_crossfade
	
	if vacuum>0:
		fade *= sfk
		volume += (1.0-sfk)*settings.vacuum_loudness
	else:
		fade -= fade*abs(vacuum)
#		fade += (7.0 -fade)*abs(vacuum)
		volume += 0.0

	
	
	for i in get_children():
		var maxvol = float(i.get_child(0).name)/100.0
		var maxpitch = float(i.name)/100000.0
		
		var index = float(i.get_index())
		var dist = abs(index-fade)
		
		dist *= abs(dist)
		
		var vol = 1.0-dist
		if vol<0.0:
			vol = 0.0
		elif vol>1.0:
			vol = 1.0
		var db = linear_to_db((vol*maxvol)*(volume*(settings.overall_volume)))
		if db<-60.0:
			db = -60.0
			
		i.volume_db = db
		i.max_db = i.volume_db
		var pit = abs(pitch*maxpitch)
		if pit>5.0:
			pit = 5.0
		elif pit<0.01:
			pit = 0.01
		i.pitch_scale = pit
	
		
