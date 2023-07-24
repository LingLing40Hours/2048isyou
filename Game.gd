extends Node2D

@onready var GV:Node = $"/root/GV";

@onready var fader:AnimationPlayer = $"Overlay/AnimationPlayer";
@onready var right_sidebar:VBoxContainer = $"GUI/HBoxContainer/RightSideBar";
@onready var mode_label:Label = right_sidebar.get_node("MoveMode");

@onready var combine_sound = $"Audio/Combine";
@onready var slide_sound = $"Audio/Slide";
@onready var split_sound = $"Audio/Split";
@onready var shift_sound = $"Audio/Shift";

var current_level:Node2D;
var current_level_name:Label;
var levels = [];
var next_level_index:int;


func _ready():
	#load levels
	for i in range(GV.LEVEL_COUNT):
		levels.append(load("res://Levels/Level "+str(i)+".tscn"));
	add_level(GV.current_level_index);
	
	#init mode label
	change_move_mode(GV.player_snap);
	
	#testing


func _input(event):
	if event.is_action_pressed("change_move_mode") and GV.abilities["move_mode"]:
		change_move_mode(not GV.player_snap);
		
		#update player(s) state
		for player in current_level.players:
			var state = player.get_state();
			if state not in ["merging1", "merging2", "combining", "splitting"]:
				var next_state = "snap" if GV.player_snap else "slide";
				player.change_state(next_state);


#defer this until previous level has been freed
func add_level(n):
	var level:Node2D = levels[n].instantiate();
	current_level = level;
	add_child(level);
	GV.changing_level = false;
	
	#update right sidebar visibility
	#right_sidebar.visible = true if n else false;
	
	#get level name
	if current_level.get_node("Background").has_node("LevelName"):
		current_level_name = current_level.get_node("Background/LevelName");
	else:
		current_level_name = null;
	
	#init player position
	if GV.spawn_point != Vector2.ZERO:
		level.get_node("Player").position = GV.spawn_point;

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
	if anim_name == "fade_in_black": #fade out black
		change_level(next_level_index);
		fader.play("fade_out_black");
	elif anim_name == "fade_out_black": #fade in level name
		if current_level_name != null:
			var tween = current_level_name.create_tween().set_trans(Tween.TRANS_LINEAR);
			tween.finished.connect(_on_level_name_faded_in);
			tween.tween_property(current_level_name, "modulate:a", 1, GV.LEVEL_NAME_FADE_IN_TIME);
			

func change_move_mode(snap):
	GV.player_snap = snap;
	
	#update label
	var s:String = "Mode: ";
	s += "snap" if snap else "slide";
	mode_label.text = s;

func _on_level_name_faded_in(): #display level name
	var timer = get_tree().create_timer(GV.LEVEL_NAME_DISPLAY_TIME);
	timer.timeout.connect(_on_level_name_displayed);

func _on_level_name_displayed(): #fade out level name
	if current_level_name != null:
		var tween = current_level_name.create_tween().set_trans(Tween.TRANS_LINEAR);
		tween.tween_property(current_level_name, "modulate:a", 0, GV.LEVEL_NAME_FADE_OUT_TIME);

func save_level():
	pass;
