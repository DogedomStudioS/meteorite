extends Spatial

export var freezes_player: bool = true
signal unfreeze_player

const NOISE_AMPLITUDE = 10
const PLAINS_LEVEL = -4.0
const PLAINS_EXTENTS = -900
const MOUNTAINS_PEAK = 120
const MOUNTAINS_AXIS = 50
const PLAINS_SLOPE = 140 # how many meters until plans flatten out
const NOISE_MULTIPLIER = 0.15
const WORLD_CHUNK_SIZE = 64
const CHUNK_SIDE_METERS = 200
const HOME_CHUNK_X = 0
const HOME_CHUNK_Z = 0
const bazoik = preload("res://scenes/levels/bazoik.material")

var chunks = []
var chunkThreads = []
var chunk_mutex = Mutex.new()
var chunk_count = 0
var noise = OpenSimplexNoise.new()

func _new_surface(userdata):
	var size = userdata['size']
	var offsetX = userdata['offsetX']
	var offsetZ = userdata['offsetZ']
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = size
	plane_mesh.subdivide_depth = 50
	plane_mesh.subdivide_width = 50
	
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(plane_mesh, 0)
	
	var array_plane = surface_tool.commit()
	
	var data_tool = MeshDataTool.new()
	data_tool.create_from_surface(array_plane, 0)
	
	var mountains_offset = MOUNTAINS_AXIS - offsetX
	var plains_offset = PLAINS_EXTENTS + offsetZ
	var mountains_distance = 0
	for i in range(data_tool.get_vertex_count()):
		var vertex = data_tool.get_vertex(i)
		vertex.y = noise.get_noise_3d(vertex.x + offsetX, vertex.y, vertex.z + offsetZ) * NOISE_AMPLITUDE
		if vertex.x >= mountains_offset and vertex.x - mountains_offset < PLAINS_SLOPE or vertex.x < mountains_offset and mountains_offset - vertex.x < PLAINS_SLOPE:
			if vertex.x >= mountains_offset: 
				mountains_distance = vertex.x - mountains_offset
			else:
				mountains_distance = mountains_offset - vertex.x
			vertex.y = lerp(vertex.y * (MOUNTAINS_PEAK / NOISE_AMPLITUDE), vertex.y,  mountains_distance / PLAINS_SLOPE)

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
	mesh_instance.set_surface_material(0, bazoik)
	
	var collision_body = mesh_instance.get_children()[0]
	collision_body.set_collision_layer_bit(0, true)
	collision_body.set_collision_layer_bit(1, true)
	collision_body.set_collision_mask_bit(0, true)
	mesh_instance.translate(Vector3(offsetX, 0.0, offsetZ))
	chunk_finished()
	call_deferred('add_child', mesh_instance)



func _ready():
	noise.period = 100
	noise.octaves = 6
	init_chunks()

func get_chunk_at(x: float, z: float):
	return chunks[x][z]


func init_chunks():
	var player_coords = Vector3(0.0, 0.0, 0.0)
	var new_origin_x = floor(player_coords.x / CHUNK_SIDE_METERS)
	var new_origin_z = floor(player_coords.z / CHUNK_SIDE_METERS)
	for x in range(-4, 4):
		for z in range(-4, 4):
			var chunk = { 'size': Vector2(CHUNK_SIDE_METERS, CHUNK_SIDE_METERS), 'offsetX': float(x * CHUNK_SIDE_METERS) + new_origin_x, 'offsetZ': float(z * CHUNK_SIDE_METERS) + new_origin_z }
			var chunkThread = Thread.new()
			chunkThreads.append(chunkThread)
			chunkThread.start(self, '_new_surface', chunk)
	chunk_count = chunkThreads.size()

func chunk_finished():
	chunk_mutex.lock()
	chunk_count -= 1
	if chunk_count <= 0:
		emit_signal('unfreeze_player')
	chunk_mutex.unlock()


func _exit_tree():
	for i in chunkThreads:
    	i.wait_to_finish()