extends Level

@onready var score_tiles:Node2D = $ScoreTiles;


func _ready():
	#init random score tiles
	for score_tile in score_tiles.get_children():
		score_tile.power = GV.rng.randi_range(1, 11);
		score_tile.update_texture(score_tile.img);
	
