class_name AccelTimer
extends Node

signal timeout;

var repeat_count:int;
var frames_total:int;
var frames_left:int = -1; #stopped by default
var d_frames_total:int;
var dd_frames_total:int;
var min_frames_total:int;


func _physics_process(_delta):
	if frames_left > 0:
		frames_left -= 1;
		if not frames_left:
			timeout.emit();
			if not is_stopped():
				repeat();

func start(t, dt, ddt, min_t):
	repeat_count = 1;
	frames_total = t;
	frames_left = t;
	d_frames_total = dt;
	dd_frames_total = ddt;
	min_frames_total = min_t;

func is_timeouted():
	return frames_left == 0;

func stop():
	frames_left = -1;

func is_stopped() -> bool:
	return frames_left == -1;

func repeat():
	repeat_count += 1;
	frames_total = maxi(min_frames_total, frames_total + d_frames_total);
	frames_left = frames_total;
	d_frames_total += dd_frames_total;
