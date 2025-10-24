extends Node

const newton: float = 0.0169946645619466

static func rads_to_rpm(val):
	return (val/6.28319)*60.0
static func rpm_to_rads(val):
	return (val/60.0)*6.28319

static func alignAxisToVector(xform, norm): # i named this literally out of blender
	xform.basis.y = norm
	xform.basis.x = -xform.basis.z.cross(norm)
	xform.basis = xform.basis.orthonormalized()
	return xform
