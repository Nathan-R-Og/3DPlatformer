extends Node3D
@export_file("*.tscn") var goTo
@export var link:int

func _interact(who):
	if who is PlayerController:
		data.stateArray.append(
				{"from": "Warp.gd",
				"link": link,
				"mode": data.sceneData.Camera.lookyMode,
				"playerMode": data.sceneData.Player.originalState,
				"ang": data.sceneData.Camera.rotation_degrees,
				"vel": data.sceneData.Player.velocity,
				})
		get_tree().change_scene_to_file(goTo)
