extends Spatial
export var lookSensitivity = 15
export var minLookAngle = -40.0
export var maxLookAngle = 60.0
var mouseDelta = Vector2()
onready var player = data.sceneData.Player
var looky = true
var lookyMode = 0

var tFrown = 0.0
var t = .2

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	lookyMode()
func _input(event):
	# if move
	if looky:
		if event is InputEventMouseMotion:
			#set to the movement?
			mouseDelta = event.relative
	

func lookyMode():
	match lookyMode:
		0:
			$Tween.interpolate_property($Camera, "translation",
			$Camera.translation, Vector3.ZERO, t, Tween.TRANS_EXPO, Tween.EASE_OUT)
			$Tween.start()
			tFrown = 0.0
		1:
			$Tween.interpolate_property($Camera, "translation",
			$Camera.translation, Vector3(0, 2.757, 5.848), t, Tween.TRANS_EXPO, Tween.EASE_OUT)
			$Tween.start()
			data.sceneData.Player.get_node("PlayerBody/IMG").show()

func _process(delta):
	if lookyMode == 0 and tFrown >= t and data.sceneData.Player.get_node("PlayerBody/IMG").visible:
		data.sceneData.Player.get_node("PlayerBody/IMG").hide()
	else:
		tFrown += delta
	
	if Input.is_action_just_pressed("ui_accept"):
		lookyMode = int(!bool(lookyMode))
		lookyMode()
	mouseDelta += Vector2(Input.get_axis("rstickleft", "rstickright"), Input.get_axis("rstickup", "rstickdown")) * 15
	transform.origin = player.get_node("PlayerBody").transform.origin + Vector3(0, 2, 0)
	#set the rotation vecotr to the mouse speed y and x, but also mutliply by time and look sensitivuity
	var rot = Vector3(-mouseDelta.y, mouseDelta.x, 0) * lookSensitivity * delta
	rotation_degrees.x = clamp(rotation_degrees.x + rot.x, -40, 40)
	rotation_degrees.y = wrapf(rotation_degrees.y - rot.y, 0, 360)
	#set blank
	mouseDelta = Vector2()
