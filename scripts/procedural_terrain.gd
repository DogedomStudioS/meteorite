extends Spatial

const NOISE_AMPLITUDE = 10
const PLAINS_LEVEL = -4.0
const PLAINS_EXTENTS = -200
const MOUNTAINS_PEAK = 80
const MOUNTAINS_AXIS = 50
const PLAINS_SLOPE = 70 # how many meters until plans flatten out

func _ready():
	var noise = OpenSimplexNoise.new()
	noise.period = 100
	noise.octaves = 6
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(600, 600)
	plane_mesh.subdivide_depth = 300
	plane_mesh.subdivide_width = 300
	
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(plane_mesh, 0)
	
	var array_plane = surface_tool.commit()
	
	var data_tool = MeshDataTool.new()
	data_tool.create_from_surface(array_plane, 0)
	
	var counter = 0
	for i in range(data_tool.get_vertex_count()):
		counter += 1
		var vertex = data_tool.get_vertex(i)
		vertex.y = noise.get_noise_3d(vertex.x, vertex.y, vertex.z) * NOISE_AMPLITUDE
		if vertex.x >= MOUNTAINS_AXIS and vertex.x - MOUNTAINS_AXIS < PLAINS_SLOPE or vertex.x < MOUNTAINS_AXIS and MOUNTAINS_AXIS - vertex.x < PLAINS_SLOPE:
			var mountains_distance = 0
			if vertex.x >= MOUNTAINS_AXIS: 
				mountains_distance = vertex.x - MOUNTAINS_AXIS
			else:
				mountains_distance = MOUNTAINS_AXIS - vertex.x
			vertex.y = lerp(vertex.y * (MOUNTAINS_PEAK / NOISE_AMPLITUDE), vertex.y,  mountains_distance / PLAINS_SLOPE)
		if vertex.z < PLAINS_EXTENTS + PLAINS_SLOPE and vertex.z > PLAINS_EXTENTS:
			var plains_distance = vertex.z - PLAINS_EXTENTS
			vertex.y = lerp(PLAINS_LEVEL, vertex.y, plains_distance / PLAINS_SLOPE)
		elif vertex.z < PLAINS_EXTENTS:
			vertex.y = PLAINS_LEVEL

		data_tool.set_vertex(i, vertex)

	
	for i in range(array_plane.get_surface_count()):
		array_plane.surface_remove(i)
	
	data_tool.commit_to_surface(array_plane)
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(array_plane, 0)
	surface_tool.generate_normals()
	
	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = surface_tool.commit()
	mesh_instance.create_trimesh_collision()
	mesh_instance.set_surface_material(0, load("res://scenes/levels/bazoik.material"))
	
	var collision_body = mesh_instance.get_children()[0]
	collision_body.set_collision_layer_bit(0, true)
	collision_body.set_collision_layer_bit(1, true)
	collision_body.set_collision_mask_bit(0, true)
	
	add_child(mesh_instance)