extends Camera2D
class_name TrackingCam

signal transition_started(target:Vector2, track_dir:Vector2i);

@onready var game:Node2D = $"/root/Game";
@onready var level:Node2D = game.current_level;

@export var max_rx:float = 0.3125; #ratio between dx and level width to make camera move
@export var max_ry:float = 0.25;

var track_pos:Vector2;
var track_dir:Vector2i;
var clamped_track_dir:Vector2i; #track_dir but only if target is clamped

var active:bool;
var max_dx:float;
var max_dy:float;

var tween:Tween;
var target:Vector2;
var min_pos:Vector2;
var max_pos:Vector2;


func _ready():
	active = true;
	
	#set zoom
	zoom.x = minf(GV.RESOLUTION.x / level.resolution.x, GV.RESOLUTION.y / level.resolution.y);
	zoom.y = zoom.x;
	
	#find max coord offsets from center of screen
	max_dx = max_rx * level.resolution.x;
	max_dy = max_ry * level.resolution.y;
	
	#find position limits
	min_pos = Vector2(level.min_pos.x + level.resolution.x/2, level.min_pos.y + level.resolution.y/2);
	max_pos = Vector2(level.max_pos.x - level.resolution.x/2, level.max_pos.y - level.resolution.y/2);
	
	#set initial position
	if level.players:
		track_pos = avg_player_pos();
		position = track_pos.clamp(min_pos, max_pos);

#returns (0, 0) if no players present
func avg_player_pos() -> Vector2:
	var ans = Vector2.ZERO;
	for player in level.players:
		ans += player.global_position;
	return ans / level.players.size();

func _process(_delta):
	if active:
		#update track_pos
		track_pos = avg_player_pos();
		
		#figure out whether to move
		#if tracking towards clamped target, don't restart track in that direction
		var dx = track_pos.x - position.x;
		var dy = track_pos.y - position.y;
		var track:bool = false;
		track_dir = Vector2i.ZERO;
		if (dx >= max_dx and !GV.is_approx_equal(position.x, max_pos.x, 0.005) and clamped_track_dir.x != 1):
			track_dir.x = 1;
			track = true;
		elif (dx <= -max_dx and !GV.is_approx_equal(position.x, min_pos.x, 0.005) and clamped_track_dir.x != -1):
			track_dir.x = -1;
			track = true;
		if (dy >= max_dy and !GV.is_approx_equal(position.y, max_pos.y, 0.005) and clamped_track_dir.y != 1):
			track_dir.y = 1;
			track = true;
		elif (dy <= -max_dy and !GV.is_approx_equal(position.y, min_pos.y, 0.005) and clamped_track_dir.y != -1):
			track_dir.y = -1;
			track = true;
		
		if track:
			var track_rx:float = GV.TRACKING_CAM_LEAD_RATIO if track_dir.x else GV.TRACKING_CAM_SLACK_RATIO;
			var track_ry:float = GV.TRACKING_CAM_LEAD_RATIO if track_dir.y else GV.TRACKING_CAM_SLACK_RATIO;
			target.x = position.x + track_rx * (track_pos.x - position.x);
			target.y = position.y + track_ry * (track_pos.y - position.y);
			
			#target = target.clamp(min_pos, max_pos);
			#clamp target, set clamped_track_dir
			clamped_track_dir = Vector2i.ZERO;
			if target.x <= min_pos.x:
				target.x = min_pos.x;
				clamped_track_dir.x = -1;
			elif target.x >= max_pos.x:
				target.x = max_pos.x;
				clamped_track_dir.x = 1;
			if target.y <= min_pos.y:
				target.y = min_pos.y;
				clamped_track_dir.y = -1;
			elif target.y >= max_pos.y:
				target.y = max_pos.y;
				clamped_track_dir.y = 1;
			
			tween = create_tween();
			tween.set_ease(Tween.EASE_OUT);
			tween.finished.connect(_on_tween_transitioned);
			tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE);
			tween.tween_property(self, "position", target, GV.TRACKING_CAM_TRANSITION_TIME).set_trans(Tween.TRANS_QUINT);
			transition_started.emit(target, track_dir);

func _on_tween_transitioned():
	clamped_track_dir = Vector2i.ZERO;
