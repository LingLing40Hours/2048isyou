extends Level

var score_tile:PackedScene = preload("res://Objects/ScoreTile.tscn");
var tile_noise = FastNoiseLite.new();
var wall_noise = FastNoiseLite.new();
var difficulty:float = 0; #probability of hostile, noise roughness


func _ready():
	super._ready();
	
	#randomize();
	tile_noise.set_seed(2);
	wall_noise.set_seed(2);
	#tile_noise.set_seed(randi());
	#wall_noise.set_seed(randi());
	tile_noise.set_frequency(0.07); #default 0.01
	wall_noise.set_frequency(0.03);
	tile_noise.set_fractal_octaves(3); #number of layers, default 5
	wall_noise.set_fractal_octaves(3);
	tile_noise.set_fractal_lacunarity(2); #frequency multiplier for subsequent layers, default 2.0
	wall_noise.set_fractal_lacunarity(2);
	tile_noise.set_fractal_gain(0.5); #strength of subsequent layers, default 0.5
	wall_noise.set_fractal_gain(0.3);
	#tile_noise.set_fractal_ping_pong_strength(10);
	#tile_noise.set_domain_warp_enabled(true);
	#wall_noise.set_domain_warp_enabled(true);
	for tx in 3:
		for ty in 2:
			generate_chunk(Vector2i(tx, ty));
	
func generate_chunk(chunk_pos:Vector2i):
	var tile_start_pos:Vector2i = GV.CHUNK_WIDTH * chunk_pos;
	for tx in range(tile_start_pos.x, tile_start_pos.x + GV.CHUNK_WIDTH):
		for ty in range(tile_start_pos.y, tile_start_pos.y + GV.CHUNK_WIDTH):
			generate_tile(tx, ty);

func generate_tile(tx, ty):
	if Vector2i(tx, ty) == Vector2i.ZERO:
		return;
	if tx >= GV.RESOLUTION_T.x or ty >= GV.RESOLUTION_T.y:
		return;
	
	var n_wall:float = wall_noise.get_noise_2d(tx, ty); #[-1, 1]
	if abs(n_wall) < 0.009:
		$Walls.set_cell(0, Vector2i(tx, ty), 0, Vector2i.ZERO);
	elif abs(n_wall) < 0.02:
		$Walls.set_cell(0, Vector2i(tx, ty), 1, Vector2i.ZERO);
	else:
		var n_tile:float = tile_noise.get_noise_2d(tx, ty); #[-1, 1]
		#var temp_n_tile = n_tile;
		var ssign:int = sign(n_tile);
		n_tile = pow(abs(n_tile), 1);
		
		var power:int = -1;
		if n_tile == 1.0:
			power = GV.TILE_GEN_POW_MAX;
		else:
			power = int((GV.TILE_GEN_POW_MAX + 2) * n_tile) - 1;
		#print("n_tile: ", temp_n_tile, "  power: ", power);
		
		var tile = score_tile.instantiate();
		tile.position = GV.TILE_WIDTH * Vector2(tx + 0.5, ty + 0.5);
		tile.power = power;
		tile.ssign = ssign;
		#if Vector2i(tx, ty) == Vector2i(0, 1):
		#	tile.debug = true;
		scoretiles.add_child(tile);
