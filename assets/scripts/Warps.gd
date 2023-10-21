extends Node

onready var player = data.sceneData.Player
onready var playerBODY = player.get_node("PlayerBody")
export var warps = PoolStringArray()
export var links = PoolIntArray()
export var overrides = PoolIntArray()


func _ready():
	var iterate = 0
	while iterate < get_child_count():
		get_child(iterate).connect("body_entered", self, "loadingZone", [links[iterate], warps[iterate], overrides[iterate], get_child(iterate)])
		iterate += 1
	
	var s = 0
	while s < data.stateArray.size():
		var each = data.stateArray[s]
		if "from" in each:
			if each.from == "Warp.gd":
				if "link" in each:
					var what = Array(links).find(each.link)
					var warp = get_child(what)
					var poser = null
					for child in warp.get_children():
						if child.get_class() == "Position3D":
							poser = child
							break
					if poser == null:
						print("Fuck!")
					else:
						playerBODY.global_transform.origin = poser.global_transform.origin
						data.sceneData.Player.velocity.x = each.vel.x
						data.sceneData.Player.velocity.z = each.vel.z
						data.sceneData.Player.movement = each.playerMode
						data.sceneData.Camera.rotation_degrees = each.ang
						data.sceneData.Camera.lookyMode = each.mode
						data.stateArray.remove(s)
					break
		s += 1





func loadingZone(body, link, warp, ov, warpNode):
	if body == playerBODY:
		var poser = null
		var calc2 = 0.0
		var vec2 = Vector3()
		var newDeg = Vector3()
		if ov == 0:
			for child in warpNode.get_children():
				if child.get_class() == "Position3D":
					poser = child
					break
			calc2 = poser.global_transform.origin.angle_to(warpNode.global_transform.origin) + deg2rad(180)
			vec2 = Vector3(cos(calc2), 0, sin(calc2))
			newDeg = Vector3(0, rad2deg(calc2), 0)
		
		data.stateArray.append(
			{"from": "Warp.gd",
			"link": link,
			"mode": data.sceneData.Camera.lookyMode,
			"playerMode": data.sceneData.Player.movement,
			"ang": data.sceneData.Camera.rotation_degrees + newDeg,
			"vel": data.sceneData.Player.velocity * vec2,
			})
		get_tree().change_scene(warp)
