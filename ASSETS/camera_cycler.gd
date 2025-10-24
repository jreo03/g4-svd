@tool
extends Node

@export var cameras: Array[NodePath]
@export var cycle: int: set = xc
func xc(val):
		cycle = wrapi(val,0,len(cameras))
		for i in cameras:
			if has_node(i):
				get_node(i).current = get_node(i) == get_node(cameras[cycle])
			else:
				break
				return

@export var change_cam_key: String


func _input(event):
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed(change_cam_key):
		cycle += 1 ; xc(cycle)
