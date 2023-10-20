extends Node3D
@export var lookSensitivity = 15
@export var minLookAngle = -40.0
@export var maxLookAngle = 60.0
var mouseDelta = Vector2()
var looky = true
var lookyMode = 0

var tFrown = 0.0
var t = .2

var clipping = false
var dist = 0.0
var useDist = 0.0

var zo = Vector3(0, 2.757, 5.848)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	lookyModer()

func _input(event):
	# if move
	if looky and event is InputEventMouseMotion:
		#set to the movement?
		mouseDelta = event.relative
	

func lookyModer():
	match lookyMode:
		0:
			Special.doTweenKillId($Camera, "position",
			$Camera.position, Vector3.ZERO, t,
			Tween.TRANS_EXPO, Tween.EASE_OUT, str(self))
			tFrown = 0.0
			clipping = false
		1:
			Special.doTweenKillId($Camera, "position",
			$Camera.position, zo, t,
			Tween.TRANS_EXPO, Tween.EASE_OUT, str(self))
			owner.get_node("PlayerBody/IMG").show()
			clipping = true
			$RayCast.target_position.y = $RayCast.position.distance_to(zo)

func _process(delta):
	if lookyMode == 0 and tFrown >= t and $"../PlayerBody/IMG".visible:
		owner.get_node("PlayerBody/IMG").hide()
	else:
		tFrown += delta
	
	if Input.is_action_just_pressed("fire3"):
		lookyMode = int(!bool(lookyMode))
		lookyModer()
	
	
	if looky:
		mouseDelta += Vector2(Input.get_axis("move2_left", "move2_right"), Input.get_axis("move2_up", "move2_down")) * 15
	transform.origin = $"../PlayerBody".transform.origin + Vector3(0, 2, 0)
	#set the rotation vecotr to the mouse speed y and x, but also mutliply by time and look sensitivuity
	var rot = Vector3(-mouseDelta.y, mouseDelta.x, 0) * lookSensitivity * delta
	rotation_degrees.x = clamp(rotation_degrees.x + rot.x, minLookAngle, maxLookAngle)
	rotation_degrees.y = wrapf(rotation_degrees.y - rot.y, 0, 360)
	$RayCast.position = Vector3.ZERO
	$RayCast.rotation_degrees.x = $RayCast.position.angle_to($Camera.global_position) + 65
	$RayCast.force_raycast_update()
	if lookyMode == 1:
		if $RayCast.is_colliding() and clipping:
			$Camera.global_position = $RayCast.get_collision_point()
		else:
			$Camera.position = zo
	
	#set blank
	mouseDelta = Vector2()
