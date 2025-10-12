extends Control

@export var Scale = 1.0
@export var MaxG = 0.75

@export var gforce = Vector2(0,0)

@onready var wheel = $wheel.duplicate()

var glength = 0.0

var appended = []

func _ready():
	$wheel.queue_free()
	
func clear():
	for i in appended:
		i.queue_free()
	appended = []
	
	
func append_wheel(position,settings,node):
	var w_size = ((abs(int(settings["Width (mm)"]))*((abs(int(settings["Aspect Ratio"]))*2.0)/100.0) + abs(int(settings["Rim Size (in)"]))*25.4)*0.003269)/2.0
	var width = (abs(int(settings["Width (mm)"]))*0.003269)/2.0
	
	var w = wheel.duplicate()
	add_child(w)
	w.pos = -Vector2(position.x,position.z)*2.0
	w.setting = settings
	w.node = node
	
	w.scale.x = (width*2.0)/(Scale/2.0)
	w.scale.y = w_size/(Scale/2.0)
	
	appended.append(w)

func _process(delta):
	
	
	
	for i in appended:
		i.position = size/2
		i.position += ((i.pos*(64.0/Scale))/9.806)
		
		i.get_node("slippage").scale.y = (i.node.slip_percpre)*0.8

		i.rotation = -i.node.rotation.y

		i.self_modulate = Color(1,1,1)
		if i.get_node("slippage").scale.y<0.0:
			i.get_node("slippage").scale.y = 0.0
		elif i.get_node("slippage").scale.y>0.8:
			i.get_node("slippage").scale.y = 0.8
			if abs(i.node.wv*i.node.w_size)>i.node.velocity.length():
				i.self_modulate = Color(1,0,0)
			
	
	glength = Vector2(abs(gforce.x),abs(gforce.y)).length()/Scale -1.0
	if Vector2(abs(gforce.x),abs(gforce.y)).length()>MaxG:
		$centre/Circle.modulate = Color(1.0,1.0,0.5,1.0)
	else:
		$centre/Circle.modulate = Color(1.0,0.75,0.0,1.0)

	if glength<0.0:
		glength = 0.0
	
	gforce /= glength +1.0
	
	$centre.position = size/2 +gforce*(64.0/Scale)
	$field.position = size/2
	
