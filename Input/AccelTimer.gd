class_name AccelTimer
extends Node

signal timeout;

var repeat_count:int;
var frames_total:int;
var frames_left:int;
var d_frames_total:int;
var dd_frames_total:int;


func _physics_process(_delta):
	if frames_left > 0:
		frames_left -= 1;
		if not frames_left:
			timeout.emit();
			if not is_stopped():
				repeat();

func start(t, dt, ddt):
	repeat_count = 1;
	frames_total = t;
	frames_left = t;
	d_frames_total = dt;
	dd_frames_total = ddt;

func stop():
	frames_left = -1;

func is_stopped() -> bool:
	return frames_left == -1;

func repeat():
	repeat_count += 1;
	frames_total = max(0, frames_total + d_frames_total);
	frames_left = frames_total;
	d_frames_total += dd_frames_total;
