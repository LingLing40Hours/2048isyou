extends Node2D

@onready var GV:Node = $"/root/GV";
@onready var current_level:Node2D;
var levels = [];

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
