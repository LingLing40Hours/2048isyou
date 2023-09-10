class_name Chunk
extends Node2D

#tiles in chunk are children
var pos_c:Vector2i;
var cells:Array; #holds cell data


func _init():
	#print("CHUNK INIT");
	cells.resize(GV.CHUNK_WIDTH_T);
	for y in GV.CHUNK_WIDTH_T:
		var row:Array[int] = [];
		row.resize(GV.CHUNK_WIDTH_T);
		row.fill(0);
		cells[y] = row;

func _ready():
	#print("CHUNK READY");
	pass;
