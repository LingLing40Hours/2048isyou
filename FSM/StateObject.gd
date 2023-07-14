extends Node
class_name State

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
@onready var states = get_parent().states
var actor = null

# Called to set the actor of the script
func setActor(_actor):
	actor = _actor

# Called when the actor (FSM controller parent) enters the state
func enter():
	pass

# Called when parent leaves the state, most likely not necessary 
func exit():
	pass

# Called every physics frame. 'delta' is the elapsed time since the previous frame. Run in FSM _physics_process.
func inPhysicsProcess(_delta):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame. Run in FSM _process.
func inProcess(_delta):
	pass

func changeParentState():
	return null

func handleInput(event):
	pass

