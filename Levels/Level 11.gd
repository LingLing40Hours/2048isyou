extends Level

const LEVEL_NAME:String = "T Is For ";
const RWORDS:Array[String] = ["Restore", "Rewind", "Re-undo", "Reset", "Reverse", "Revert"]; #"Restart", 
const RWORD_DISPLAY_TIME:float = 0.33;
const RWORD_DELETE_TIME:float = 0.14;
var rword_index = 0;


func _ready():
	super._ready();
	
	#init level name
	$Background/LevelName.text = LEVEL_NAME + RWORDS[rword_index];
	rword_index += 1;
	
	#connect fader signal
	if rword_index < RWORDS.size():
		game.fader.animation_finished.connect(_on_fader_animation_finished);
	print("level name modulate: ", game.current_level_name.modulate.a);

func _on_fader_animation_finished(anim_name):
	if anim_name == "fade_out_black" and not GV.minor_level_change:
		#wait for half of level name fade-in time
		var timer = get_tree().create_timer(GV.LEVEL_NAME_FADE_IN_TIME/2);
		timer.timeout.connect(change_rword);

func change_rword():
	#delete incorrect rword
	$Background/LevelName.text = LEVEL_NAME + (" ").repeat(RWORDS[rword_index].length());
	
	var delete_timer = get_tree().create_timer(RWORD_DELETE_TIME);
	await delete_timer.timeout;
	
	$Background/LevelName.text = LEVEL_NAME + RWORDS[rword_index];
	rword_index += 1;
	
	if rword_index < RWORDS.size():
		var display_timer = get_tree().create_timer(RWORD_DISPLAY_TIME);
		display_timer.timeout.connect(change_rword);
