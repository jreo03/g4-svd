extends Resource
class_name SVD_TMODEL

@export var model_name: String = "Default (Linear)"

@export var TR_MDL_peak_y: float = 1 # pacejka = 1 # default = 0.748 # (float,0.001,1)
@export var TR_MDL_peak_x: float = 1 # pacejka = 0.936 # default = 0.748 # (float,0.001,1)
@export var TR_MDL_aspect_ratio: float = 1 # pacejka = 0.228 # default = 1 # (float,0.001,1)
@export var TR_MDL_shape_x: float =1 # pacejka = 0.855 # default = 1 # (float,0,1)
@export var TR_MDL_shape_y: float = 1 # pacejka = 0.975 # default = 1 # (float,0,1)
@export var TR_MDL_linear: float = 1 # (float,0,1)
@export var TR_MDL_friction: float = 1
