extends Pathfinder


func _ready():
	set_gv(GV);
	get_hash_arrays();
	set_max_depth(500);
	set_tile_push_limit(GV.abilities["tile_push_limit"]);
	set_tile_pow_max(GV.TILE_POW_MAX);
	set_is_player(true);
