extends Node3D
func _ready():
	for each in data.stateArray:
		if !"from" in each:
			continue
		if each.from != "Warp.gd":
			continue
		var poser = null
		if each.link != -1:
			for child in get_child(each.link).get_children():
				if child is Marker3D:
					poser = child
					break
		var player = data.sceneData.Player
		player.get_node("PlayerBody").global_transform.origin = poser.global_transform.origin if poser else Vector3.ZERO
		player.velocity.x = each.vel.x
		player.velocity.z = each.vel.z
		player.switchStats()
		player.stats.running = each.run
		player.runnies(true)
		player.state = each.playerMode
		player.get_node("Target").rotation_degrees = each.ang
		player.get_node("Target").lookyMode = each.mode
		data.stateArray.remove_at(data.stateArray.find(each))
		return
