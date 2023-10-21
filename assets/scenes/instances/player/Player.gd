extends Spatial


onready var camera = data.sceneData.Camera
onready var cameraReal = camera.get_child(0)

var velocity = Vector3()
var playerInput = Vector2()
export var movement = 3
var snap = Vector3.DOWN



export var deadZone = 0.15


export var speed = 100.0
var MAX_SPEED = 0.0
export var maxSpeed = 5.0
export var maxSpeed2 = 10.0
export var friction = 0.5

var moveMode = 1

export var gravity = 19.0

var jumping = false
export var jumpPower = 6.0




var doable = true
var doing = false
var do = null



func _ready():
	$PlayerBody/PlayerInteractArea.connect("body_entered", self, "interact", [1])
	$PlayerBody/PlayerInteractArea.connect("body_exited", self, "interact", [-1])


func _process(delta):
	playerInput = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	var cam_basis = cameraReal.get_global_transform().basis
	
	match movement:
		0:
			pass
		1:
			#direction in 3d space based on camera and 2d player input
			var dir = Vector3()
			dir = playerInput.x * truebasis(cam_basis.x)
			dir += playerInput.y * truebasis(cam_basis.z)
			#set y to 0 since we arent controlling that
			dir.y = 0
			#get total directional power from the dir
			var directionalPower = sqrt(pow(dir.x,2) + pow(dir.z,2))
			#if normal move
			var running = Input.is_action_pressed("decline")
			if running:
				MAX_SPEED = maxSpeed2
			else:
				MAX_SPEED = maxSpeed
			velocity += (dir * speed) * delta
			#if the total power is under a certain threshold (in this case acceleration times a deadzone)
			if abs(directionalPower) < speed * deadZone:
				#move controllable velocity towards 0
				var catch = Vector2(velocity.x, velocity.z).move_toward(Vector2(0,0), friction)
				velocity = Vector3(catch.x,velocity.y,catch.y)
			#regardless, add dir to velocity
			var c = Vector2(velocity.x, velocity.z).clamped(MAX_SPEED)
			velocity.x = c.x
			velocity.z = c.y
			
			
			$PlayerBody.rotation_degrees.y = wrapf(camera.rotation_degrees.y + 180, 0, 360)
			
			
			#add to downwards gravity per frame
			velocity.y += -gravity * delta
			
			
			
			if Input.is_action_pressed("accept") and $PlayerBody.is_on_floor():
				snap = Vector3.ZERO
				jumping = true
				velocity.y = jumpPower
				velocity.y = $PlayerBody.move_and_slide_with_snap(velocity, snap, -snap, true, 4, deg2rad(45), false).y
				snap = Vector3.DOWN
				
			if Input.is_action_just_released("accept") and velocity.y > 0 and jumping:
				velocity.y /= 1.5
				jumping = false
			
			
			#normal phys stuff
			if $PlayerBody.is_on_floor():
				jumping = false
				$PlayerBody.move_and_slide_with_snap(velocity, snap, -snap, true, 4, deg2rad(45), false)
				velocity.y = 0
			else:
				velocity = $PlayerBody.move_and_slide_with_snap(velocity, snap, -snap, true, 4, deg2rad(45), false)
			if do != null and doable and Input.is_action_just_pressed("ui_accept") and not doing:
				movement = 0
				var b = do.interact(self)
				if b == false:
					movement = 1

func truebasis(vec3):
	var parseAngle = (atan2(vec3.z, vec3.x))
	var fuck2 = Vector2(cos(parseAngle),sin(parseAngle))
	return Vector3(fuck2.x, vec3.y, fuck2.y)

func interact(get, way):
	if get.is_class("PhysicsBody"):
		get = get.get_parent()
	elif get.is_class("Area"):
		get = get.get_parent().get_parent()
	if way == 1:
		if "BEHAVIOR" in get:
			do = get
	else:
		if do == get:
			do = null
