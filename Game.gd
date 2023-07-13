extends Node2D

@onready var GV:Node = $"/root/GV";
@onready var current_level:Node2D;
@onready var fader:AnimationPlayer = $"CanvasLayer/AnimationPlayer";
var levels = [];
var next_level_index:int;

func _ready():
	#load levels
	for i in range(GV.LEVEL_COUNT):
		levels.append(load("res://Levels/Level "+str(i)+".tscn"));
	add_level(GV.current_level_index);

#defer this until previous level has been freed
func add_level(n):
	var level:Node2D = levels[n].instantiate();
	add_child(level);
	current_level = level;

#update current level and current level index
func change_level(n):
	if (n >= GV.LEVEL_COUNT):
		return;
	current_level.queue_free();
	call_deferred("add_level", n);
	GV.current_level_index = n;

func change_level_faded(n):
	if (n >= GV.LEVEL_COUNT):
		return;
	next_level_index = n;
	fader.play("fade_in_black");

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "fade_in_black":
		change_level(next_level_index);
		fader.play("fade_out_black");
