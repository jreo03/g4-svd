@tool
extends Node2D

@export var load_test: float = 1: set = Xload_test
func Xload_test(val):
	load_test = val
	refresh()
	
@export var load_index: float = 5: set = Xload_index
func Xload_index(val):
	load_index = val
	refresh()

@export var shape_load: float = 1.0

@export var grip: float = 10: set = Xgrip
func Xgrip(val):
	grip = val
	refresh()
	
@export var stiffness: float = 1: set = Xstiffness
func Xstiffness(val):
	stiffness = val
	refresh()

@export var peak_y: float = 1: set = Xpeak_y
func Xpeak_y(val):
	peak_y = val
	refresh()

@export var peak_x: float = 1: set = Xpeak_x
func Xpeak_x(val):
	peak_x = val
	refresh()

@export var linear: float: set = Xlinear
func Xlinear(val):
	linear = val
	refresh()

@export var aspect_ratio: float = 1: set = Xaspect_ratio
func Xaspect_ratio(val):
	aspect_ratio = val
	refresh()

@export var shape_x: float = 1: set = Xshape_x
func Xshape_x(val):
	shape_x = val
	refresh()

@export var shape_y: float = 1: set = Xshape_y
func Xshape_y(val):
	shape_y = val
	refresh()

@export var TEST_conflict: float: set = XTEST_conflict
func XTEST_conflict(val):
	TEST_conflict = val
	refresh()

@export var TEST_resolution: int = 100: set = XTEST_resolution
func XTEST_resolution(val):
	TEST_resolution = val
	refresh()

@export var angle_test: float = 0: set = Xangle_test
func Xangle_test(val):
	angle_test = val
	refresh()

func refresh():
	$graph.clear_points()
	$linear_graph.clear_points()
	
	var c_grip: float = grip*load_test
	
	var loaded: float = load_test/load_index
	
	for i in range(TEST_resolution):
		
		var disty: float = i/100.0
		var distx: float = i*TEST_conflict/100.0
		
		var c_shape: float = lerp(shape_y,shape_x,angle_test)
		var c_peak: float = lerp(peak_y,peak_x,angle_test)
		var c_stiff: float = lerp(stiffness,stiffness*aspect_ratio,pow(angle_test,0.5))
		
		disty *= c_stiff
		distx *= c_stiff
		
		var slip: float = max(Vector2(distx,disty).length()/(c_grip*(c_peak*(1.0-linear) +linear)) -1,0)
		var peaked: float = 1.0 -(1.0/(max(Vector2(distx,disty).length()/(c_grip*c_peak)/c_peak -1,0) +1.0))
		
		var forcey: float = disty/(slip*((peaked/c_shape)*c_peak*(1.0-linear) + linear) +1)
		
		$graph.add_point(Vector2(i/100.0,-forcey)*1000.0)
	
	for i in range(TEST_resolution):
		
		var disty: float = i*stiffness/100.0
		var distx: float = i*TEST_conflict/stiffness/100.0
		
		var slip: float = max(Vector2(distx,disty).length()/c_grip -1,0)
		
		var forcey: float = disty/(slip +1)
		
		$linear_graph.add_point(Vector2(i/100.0,-forcey)*1000.0)
