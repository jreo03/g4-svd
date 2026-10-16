extends Resource
class_name SVD_TMODEL

@export var model_name: String = "Default (Linear)"

@export_range(0.001, 5) var TR_MDL_peak_y: float = 1
@export_range(0.001, 5) var TR_MDL_peak_x: float = 1
@export_range(0.001, 1) var TR_MDL_aspect_ratio: float = 1
@export_range(0, 10) var TR_MDL_shape_x: float = 1
@export_range(0, 10) var TR_MDL_shape_y: float = 1
@export_range(0, 1) var TR_MDL_linear: float = 1
@export_range(0, 1) var TR_MDL_curving: float = 1
@export var TR_MDL_curve_distance: float = 1
@export var TR_MDL_friction: float = 1
