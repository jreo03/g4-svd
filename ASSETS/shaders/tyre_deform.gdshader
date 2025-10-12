// NOTE: Shader automatically converted from Godot Engine 3.6.stable's SpatialMaterial.

shader_type spatial;
render_mode async_visible,blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform float rotated;
uniform float deflected;
uniform vec3 scale = vec3(1.0);

uniform float diametre;
uniform float rim_diametre;
uniform float deflection_taper;
uniform float compression_taper;

uniform float compressed;
uniform float squish;

uniform float DEBUG_SLIP : hint_range(0,1);

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	
	vec3 affected = vec3(0.0,-diametre*cos(rotated),diametre*sin(rotated));
	if (scale.x<0.0){
		affected = vec3(0.0,diametre*cos(rotated),-diametre*sin(rotated));
	}
	
	float a_d = length(vec3(0.0,VERTEX.y,VERTEX.z) - affected);
	
	vec3 direction = normalize(vec3(0.0,VERTEX.y,VERTEX.z));
	
	if (length(VERTEX.yz)>rim_diametre){
		VERTEX.x += (deflected/scale.x)*max(1.0 -a_d*deflection_taper,0.0);
		VERTEX -= (direction/abs(scale.y))*max(1.0 -a_d*compression_taper,0.0)*compressed;
		VERTEX.x += VERTEX.x*max(1.0 -a_d*compression_taper,0.0)*squish/abs(scale.x);
	}
//	if (length(VERTEX.yz)>rim_diametre){
//		VERTEX.x += (deflected/scale.x)*max(1.0 -a_d*deflection_taper,0.0);
//		VERTEX.x += VERTEX.x*max(1.0 -a_d*compression_taper,0.0)*squish/abs(scale.x);
//		VERTEX.yz -= normalize(VERTEX.yz)*max(length(VERTEX.yz) -(diametre-compressed),0.0)*max(1.0 -a_d*compression_taper,0.0);
//	}
	
	
}




void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALBEDO = mix(ALBEDO,vec3(1.0,0.0,0.0),DEBUG_SLIP);
	
	
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
