extends Node
class_name FSM

@onready var actor = get_parent() # the actor is the node you are giving the FSM to
var states = {}
var curState = null: set = setState
var prevState = null

func _ready():
	for child in get_children():
		states[child.name] = child
	inReady()

func inReady():
	pass

func setState(newState):
	prevState = curState
	curState = newState
	
	if prevState != null:
		prevState.exit()
	curState.setActor(actor)
	curState.enter()

func _physics_process(delta):
	if curState != null:
		curState.inPhysicsProcess(delta)
		var newState = curState.changeParentState()
		if newState != null:
			setState(newState)

func _process(delta):
	if curState != null:
		curState.inProcess(delta)

func _input(event):
	if curState != null:
		curState.handleInput(event)


