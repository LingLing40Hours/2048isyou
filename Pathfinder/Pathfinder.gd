extends Pathfinder

var cells:TileMap;


func _ready():
	cells = get_parent().get_node("Cells");
#	#set_gv(GV);
#	set_max_depth(500);
#	set_tile_push_limit(GV.abilities["tile_push_limit"]);
#	set_tile_pow_max(GV.TILE_POW_MAX);
#	set_is_player(true);

func pathfind(search_id, min, max, start, end):
	match search_id:
		GV.SearchId.DIJKSTRA:
			return pathfind_dijkstra(min, max, start, end);
		GV.SearchId.ASTAR:
			pass;
		GV.SearchId.IDASTAR:
			pass;
		_:
			pass;

func pathfind_dijkstra(min, max, start, end):
	var wavefront:Array;
	
