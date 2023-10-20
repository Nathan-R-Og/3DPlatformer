extends Node3D
class_name PlayerController
var stats = {
	gravity = 19.0,
	speed = 100.0,
	maxSpeed = 5.0,
	run_maxSpeed = 10.0,
	MAX_SPEED = 5.0,
	friction = 0.5,
	snap = -Vector3.DOWN,
	jumpPower = [6.0],
	jumps = 1,
	deadZone = 0.15,
	running = false,
	airScalar = .4
}
var pfstats = {
	gravity = 50.0,
	speed = 100.0,
	maxSpeed = 10.0,
	run_maxSpeed = 20.0,
	MAX_SPEED = 12.0,
	friction = .7,
	snap = -Vector3.DOWN,
	jumpPower = [20.0],
	jumps = 0,
	deadZone = 0.15,
	running = false,
	airScalar = .5
}
var baseStats = stats.duplicate(true)


var velocity = Vector3()
var playerInput = Vector2()
enum states {
	PHYS = -2,
	NONE,
	NORMAL,
	PLATFORMER,
}
var state = states.PLATFORMER
var doable = true
var doing = false
var do = null
var originalState = states.NONE


var run_toggle = false
var run_invert = true

var firstCoyote = true
var firstCoyoteFrames = 0
var firstCoyoteLimit = 8

var facingCamera = false

var oldWJNormal = Vector3.ZERO
var timesWJN = 0

func _ready():
	$PlayerBody/PlayerInteractArea.body_entered.connect(interact.bind(true))
	$PlayerBody/PlayerInteractArea.body_exited.connect(interact.bind(false))
	switchStats()
	runnies(true)

func switchStats():
	match state:
		states.NORMAL:
			stats = baseStats
		states.PLATFORMER:
			stats = pfstats




func _process(delta):
	playerInput = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	

	match state:
		states.PHYS:
			phys()
		states.NORMAL:
			normal()
		states.PLATFORMER:
			platformer()
	
	var pauseStates = [states.NONE, states.PHYS]
	$Target.looky = !state in pauseStates

func platformer():
	shadowUpdate()
	var dir = basisInput()
	runnies()
	#get total directional power from the dir
	var directionalPower = sqrt(pow(dir.x,2) + pow(dir.z,2))
	#check if running, if so give bigger cap
	#add speed
	if $PlayerBody.is_on_floor():
		velocity += dir * stats.speed * get_process_delta_time()
	else:
		velocity += (dir * stats.airScalar) * stats.speed * get_process_delta_time()
	#if the total power is under a certain threshold (in this case acceleration times a deadzone)
	if abs(directionalPower) < stats.deadZone:
		#move controllable velocity towards 0
		var catch = Vector2(velocity.x, velocity.z).move_toward(Vector2(0,0), stats.friction)
		velocity = Vector3(catch.x,velocity.y,catch.y)
	#cap speed
	var c = Vector2(velocity.x, velocity.z).limit_length(stats.MAX_SPEED)
	velocity.x = c.x
	velocity.z = c.y
	#rotate based on camera
	#TODO: make this toggleable.
	#this is mainly for first person and a more 'immersive' third person, but you should
	#be able to adjust on your own in third
	
	if facingCamera: $PlayerBody.rotation_degrees.y = wrapf($Target.rotation_degrees.y + 180, 0, 360)
	elif dir != Vector3.ZERO: 
		$PlayerBody.rotation_degrees.y = wrapf(rad_to_deg(atan2(-dir.z, dir.x)) + 90, 0, 360)
	
	
	#gravity
	velocity.y += -stats.gravity * get_process_delta_time()
	
	
	#set velocity.y to 0 if on floor, or else it will BUILD UP
	#used to just be a set, instead you need a check just in case you jump on the same frame
	#(since is_on_floor() doesnt update until you run it)
	if $PlayerBody.is_on_floor():
		oldWJNormal = Vector3.ZERO
		timesWJN = 0
		if velocity.y < 0:
			velocity.y = 0
		stats.jumps = stats.jumpPower.size()
		if firstCoyote:
			firstCoyoteFrames = 0
	#hit head on ceiling
	elif $PlayerBody.is_on_ceiling() and velocity.y > 0: velocity.y = 0 #bonk
	
	#first jump coyote
	if firstCoyote:
		if not $PlayerBody.is_on_floor()\
		and stats.jumps == stats.jumpPower.size():
			if firstCoyoteFrames >= firstCoyoteLimit:
				stats.jumps = stats.jumpPower.size() - 1
			else:
				firstCoyoteFrames += 1
	
	#wall jump stuff
	var wallkickable = $PlayerBody/WallJump.is_colliding() and\
	$PlayerBody.is_on_wall_only()
	if wallkickable and Input.is_action_pressed("fire2"):
		var combivel = Vector2()
		var launchPower = stats.jumpPower[0] * 1.2
		var compareToNerf = Vector3.ZERO
		for i in $PlayerBody/WallJump.get_collision_count():
			var ugh = $PlayerBody/WallJump.get_collision_normal(i)
			compareToNerf += ugh
			combivel += Vector2(ugh.x, ugh.z)
		if compareToNerf == oldWJNormal:
			timesWJN += 1
			combivel /= (2.0 * timesWJN)
			launchPower /= (1.2 * timesWJN)
			print(combivel, " " , launchPower)
		else:
			oldWJNormal = compareToNerf
		combivel = combivel.normalized()
		velocity += Vector3(combivel.x, 0, combivel.y) * (stats.speed / 2.0)
		velocity.y = launchPower
		if stats.jumps == stats.jumpPower.size():
			stats.jumps = stats.jumpPower.size() - 1

	#jump
	if Input.is_action_pressed("fire2") and stats.jumps > 0 and not wallkickable:
		#snap length 0 so you can get off of the damn floor
		if $PlayerBody.is_on_floor() or Input.is_action_just_pressed("fire2"):
			$PlayerBody.floor_snap_length = 0
			velocity.y = stats.jumpPower[abs(stats.jumps - stats.jumpPower.size())]
			stats.jumps -= 1
	#if jump released, cut air time
	if Input.is_action_just_released("fire2") and velocity.y > 0:
		velocity.y /= 1.5
	
	
	doInteract()
	#common sets
	$PlayerBody.velocity = velocity
	$PlayerBody.move_and_slide()
	shadowUpdate()
	#reset snap length if it was changed after the fact
	$PlayerBody.floor_snap_length = stats.snap.y


func normal():
	var dir = basisInput()
	#get total directional power from the dir
	#check if running, if so give bigger cap
	runnies()
	var directionalPower = sqrt(pow(dir.normalized().x,2) + pow(dir.normalized().z,2))
	#add speed
	velocity += dir * stats.speed * get_process_delta_time()
	#if the total power is under a certain threshold (in this case acceleration times a deadzone)
	if abs(directionalPower) < stats.speed * stats.deadZone:
		#move controllable velocity towards 0
		var catch = Vector2(velocity.x, velocity.z).move_toward(Vector2(0,0), stats.friction)
		velocity = Vector3(catch.x,velocity.y,catch.y)
	#cap speed
	var c = Vector2(velocity.x, velocity.z).limit_length(stats.MAX_SPEED)
	velocity.x = c.x
	velocity.z = c.y
	
	#rotate based on camera
	#TODO: make this toggleable.
	#this is mainly for first person and a more 'immersive' third person, but you should
	#be able to adjust on your own in third
	$PlayerBody.rotation_degrees.y = wrapf($Target.rotation_degrees.y + 180, 0, 360)
	
	
	#gravity
	velocity.y += -stats.gravity * get_process_delta_time()
	
	
	
	#jump
	if Input.is_action_pressed("fire2") and $PlayerBody.is_on_floor():
		#snap length 0 so you can get off of the damn floor
		$PlayerBody.floor_snap_length = 0
		velocity.y = stats.jumpPower
	#if jump released, cut air time
	if Input.is_action_just_released("fire2") and velocity.y > 0:
		velocity.y /= 1.5
	
	
	#set velocity.y to 0 if on floor, or else it will BUILD UP
	#used to just be a set, instead you need a check just in case you jump on the same frame
	#(since is_on_floor() doesnt update until you run it)
	if $PlayerBody.is_on_floor() and velocity.y < 0:
		velocity.y = 0
	doInteract()
	#common sets
	$PlayerBody.velocity = velocity
	
	$PlayerBody.move_and_slide()
	#reset snap length if it was changed after the fact
	$PlayerBody.floor_snap_length = stats.snap.y

func phys():
	#cap speed
	#move controllable velocity towards 0
	var catch = Vector2(velocity.x, velocity.z).move_toward(Vector2(0,0), stats.friction)
	velocity = Vector3(catch.x,velocity.y,catch.y)
	var c = Vector2(velocity.x, velocity.z).limit_length(stats.MAX_SPEED)
	velocity.x = c.x
	velocity.z = c.y
	$PlayerBody.rotation_degrees.y = wrapf($Target.rotation_degrees.y + 180, 0, 360)
	velocity.y += -stats.gravity * get_process_delta_time()
	if $PlayerBody.is_on_floor() and velocity.y < 0:
		velocity.y = 0
	$PlayerBody.velocity = velocity
	$PlayerBody.move_and_slide()
	$PlayerBody.floor_snap_length = stats.snap.y

func runnies(set=false):
	var signVert = (int(run_invert) * -2) + 1
	var time = .3
	if run_toggle:
		if Input.is_action_just_pressed("fire1"):
			stats.running = !stats.running
			Special.doTweenKillId(self, "stats:MAX_SPEED",
			stats.MAX_SPEED, stats.run_maxSpeed if stats.running else stats.maxSpeed, time,
			Tween.TRANS_EXPO, Tween.EASE_IN, "run")
	else:
		var switch = (int(Input.is_action_just_pressed("fire1")) - int(Input.is_action_just_released("fire1"))) * signVert
		if switch != 0:
			stats.running = switch > 0 
			Special.doTweenKillId(self, "stats:MAX_SPEED",
			stats.MAX_SPEED, stats.run_maxSpeed if stats.running else stats.maxSpeed, time,
			Tween.TRANS_EXPO, Tween.EASE_IN, "run")
	if set: stats.MAX_SPEED = stats.run_maxSpeed if stats.running else stats.maxSpeed

func shadowUpdate():
	var shadow = $PlayerBody/Shadow
	shadow.force_raycast_update()
	var shadowImg = shadow.get_node("Texture")
	shadowImg.visible = shadow.is_colliding()
	if shadow.is_colliding():
		var point = shadow.get_collision_point()
		var distance = $PlayerBody.global_position.y - point.y
		var ratio = 1 - (distance / -shadow.target_position.y)
		shadowImg.modulate = Color(0, 0, 0, ratio)
		shadowImg.global_position = point
		var ugh = shadow.get_collision_normal()
		shadowImg.rotation_degrees.z = wrapf(-rad_to_deg(ugh.x), 0, 360)
		shadowImg.rotation_degrees.x = wrapf(rad_to_deg(ugh.z), 0, 360)
		shadowImg.rotation_degrees.y = -$PlayerBody.rotation_degrees.y

func basisInput():
	var cam_basis = $Target/Camera.get_global_transform().basis
	#direction in 3d space based on camera and 2d player input
	var dir = playerInput.x * cam_basis.x.normalized()
	dir += playerInput.y * cam_basis.z.normalized()
	#set y to 0 since we arent controlling that
	dir.y = 0
	dir = dir.normalized()
	return dir

func doInteract():
	if do != null and doable and Input.is_action_just_pressed("fire4") and not doing:
		originalState = state
		state = states.NONE
		do._interact(self)


func interact(get, enter):
	#get has to be a detectable body
	#go up the tree until not warranted to find NPC
	var limit = 3
	var uppers = 0
	while uppers < limit and !get.has_method("_interact"):
		get = get.get_parent()
		uppers += 1
	if uppers >= limit:
		return
	if enter:
		do = get
	else:
		if do == get:
			do = null
