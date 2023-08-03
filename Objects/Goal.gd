extends SavePoint

var score_tile:PackedScene = preload("res://Objects/ScoreTile.tscn");

@export var id:int = 0; #connected goals should have same id
@export var to_level:int = 0;
@export var spawn_point:Vector2 = Vector2.ZERO;


func _ready():
	if id == GV.goal_id: #spawn player at spawn_point
		var player = score_tile.instantiate();
		player.is_player = true;
		player.power = game.current_level.player_power;
		player.ssign = game.current_level.player_ssign;
		player.position = spawn_point;
		game.current_level.scoretiles.add_child(player);

func _on_body_entered(body):
	if body.is_in_group("player") and not GV.changing_level:
		#save goal id and player value
		GV.goal_id = id;
		game.current_level.player_saved = body;
		game.current_level.player_power = body.power;
		game.current_level.player_ssign = body.ssign;
		
		#change level
		GV.changing_level = true;
		GV.tunneling_goal = true;
		game.change_level_faded(to_level);

		#save level after cleanup work after overlayer turns black
