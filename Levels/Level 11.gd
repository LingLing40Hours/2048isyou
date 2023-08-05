extends Level

const LEVEL_NAME:String = "R Is For ";
const RWORDS:Array[String] = ["Reverse", "Rewind", "Restore", "Re-undo", "Reset", "Revert"];
const RWORD_DISPLAY_TIME:float = 0.3;
var rword_index = 0;


func _ready():
	super._ready();
	
	#init level name
	$Background/LevelName.text = LEVEL_NAME + RWORDS[rword_index]; print("INIT TEXT");
	rword_index += 1;
	
	#connect fader signal
	if rword_index < RWORDS.size():
		game.fader.animation_finished.connect(_on_fader_animation_finished);

func _on_fader_animation_finished(anim_name):
	if anim_name == "fade_out_black": #wait for half of level name fade-in time
		var timer = get_tree().create_timer(GV.LEVEL_NAME_FADE_IN_TIME/2);
		timer.timeout.connect(change_rword);

func change_rword():
	$Background/LevelName.text = LEVEL_NAME + RWORDS[rword_index];
	rword_index += 1;
	
	if rword_index < RWORDS.size():
		var timer = get_tree().create_timer(RWORD_DISPLAY_TIME);
		timer.timeout.connect(change_rword);
