extends State

var next_state:Node2D;


func enter():
	next_state = null;

func changeParentState():
	return next_state;
