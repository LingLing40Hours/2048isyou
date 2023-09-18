class_name Chunk
extends Node2D

#tiles in chunk are children
var pos_c:Vector2i;
var cells:Array; #holds cell data, excluding player

var add_start_time:int;
var add_end_time:int;


func _init():
	#print("CHUNK INIT");
	#init cells array
	cells.resize(GV.CHUNK_WIDTH_T);
	for y in GV.CHUNK_WIDTH_T:
		var row:Array[int] = [];
		row.resize(GV.CHUNK_WIDTH_T);
		row.fill(0);
		cells[y] = row;

func _enter_tree():
	add_start_time = Time.get_ticks_usec();

func _ready():
	add_end_time = Time.get_ticks_usec();
	#print("chunk add time: ", add_end_time - add_start_time);
