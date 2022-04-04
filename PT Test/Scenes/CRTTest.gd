extends Spatial

export var ray_randomness = 0.3
export var create_ray_count = 16
export var minimum_fps_count = 17
export var maximum_rays_per_calculation = 4
export var ray_ticks = 128
export var env_fog = 3
export var reflections_limit = 2

var skip_time = 1000 / minimum_fps_count

var first_frame = true

onready var torus = $ViewPanel
var torus_crt_image = Image.new()
var torus_crt_texture = ImageTexture.new()

# x, y, z, xvel, yvel, zvel, color, reflections
var ray_queue = []
var ray_velocity = Vector3.ZERO

func set_ray_queue():
	ray_queue = [[0, 0, 0, 0.03, 0, 0, Color.white, 0], [0, 0, 0, -0.03, 0, 0, Color.white, 0], [0, 0, 0, 0, 0, 0.03, Color.white, 0], [0, 0, 0, 0, 0, -0.03, Color.white, 0]]

func add_randomized_ray(pos, vel, color, reflections):
	var new_vel = vel + Vector3(vel.x + rand_range(-1 * ray_randomness, ray_randomness), vel.y + rand_range(-1 * ray_randomness, ray_randomness), vel.z + rand_range(-1 * ray_randomness, ray_randomness))

	ray_queue.append([pos.x, pos.y, pos.z, new_vel.x, new_vel.y, new_vel.z, color, reflections])
	
func _ready():
	torus_crt_image.create(768, 415, false, Image.FORMAT_RGB8)
	
	set_ray_queue()
	for i in range(0, create_ray_count):
		for i2 in range(0, create_ray_count):
			var current_ray = ray_queue[i]
			var pos = Vector3(current_ray[0], current_ray[1], current_ray[2])
			var vel = Vector3(current_ray[3], current_ray[4], current_ray[5])
			
			add_randomized_ray(pos, vel, current_ray[6] - Color8(env_fog, env_fog, env_fog), current_ray[7])
		print("Row Finished")
	
	print(skip_time)

func set_texture_pixel(x, y, color):
	torus_crt_image.lock()
	torus_crt_image.set_pixel(x, y, color)
	torus_crt_image.unlock()
	
func reflect(id):
	var pos = Vector3(ray_queue[id][0], ray_queue[id][1], ray_queue[id][2])
	var vel = Vector3(ray_queue[id][3], ray_queue[id][4], ray_queue[id][5])
	
	add_randomized_ray(pos, vel, ray_queue[id][6] - Color8(env_fog, env_fog, env_fog), ray_queue[id][7] + 1)
	
	ray_queue.remove(id)
	
func _process(delta):
	if not first_frame:
		torus_crt_texture.create_from_image(torus_crt_image)
		torus.texture = torus_crt_texture
		
		for i2 in range(0, maximum_rays_per_calculation):
			for i in range(0, ray_ticks):
				ray_queue[i2][0] += ray_queue[i2][3]
				ray_queue[i2][1] += ray_queue[i2][4]
				ray_queue[i2][2] += ray_queue[i2][5]
				
				var ray_pos = Vector3(ray_queue[i2][0], ray_queue[i2][1], ray_queue[i2][2])
				
				var space = get_world().get_direct_space_state()
				var results = space.intersect_point(ray_pos)
				
				if results != [] and ray_queue[i2][7] < reflections_limit:
					reflect(0)
				elif ray_queue[i2][7] > reflections_limit:
					ray_queue.remove(i2)
					
				if (ray_pos.z - torus.translation.z) < 0.000001:
					set_texture_pixel(ray_pos.x + 384, ray_pos.y + 207, ray_queue[i2][6])
					ray_queue.remove(i2)
					print("Changed Pixel")
	first_frame = false
