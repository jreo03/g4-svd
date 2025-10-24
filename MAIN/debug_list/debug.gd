extends CanvasLayer
class_name bge

var queue: Dictionary

var phys_delta: float

func _init():
	queue["profile"] = ""
	queue[" frames per second"] = float(0)
	queue[" delta_hz"] = float(0)
	queue[" physics_delta_hz"] = float(0)
	queue[""] = ""
	queue["debug properties"] = ""

func _physics_process(delta):
	phys_delta = delta

func _process(delta):
	queue["profile"] = ""
	queue[" frames per second"] = Engine.get_frames_per_second()
	queue[" delta_hz"] = 1.0/delta
	queue[" physics_delta_hz"] = 1.0/phys_delta
	queue["debug properties"] = ""
	
	var buffer: String
	
	for i in queue:
		if i == "":
			buffer += "\n"
		else:
			buffer += i +str(": ") +str(queue[i]) +str("\n")
	
	$disp.text = buffer
	
#	queue.clear()
