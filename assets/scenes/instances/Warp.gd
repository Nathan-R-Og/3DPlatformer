extends Area3D
## Script for containing warp data.
## Putting each warp's data in an exported array variable got kind of annoying.
## This is a comprimise.
class_name Warp
## The file to be warped to on touch.
@export_file("*.tscn") var goTo
## The exit to be warped to on touch.
## A child indicie within the goTo scene's Warp node.
## Can be left at default to just be brought to the scene.
@export var link:int = -1
## The retention mode as to which playe data is transfered,
## in regards to velocity, camera angle, and whatever else Warps.gd specifies
## for that mode.
enum RetentionModes {
	None=-1,
	Relative,
	}
@export var retentionMode: RetentionModes = RetentionModes.Relative
func _ready():
	body_entered.connect(loadingZone)
func loadingZone(body):
	if !body.owner is PlayerController:
		return
	var dict = {"from": "Warp.gd",
	"link": link,
	"mode": data.sceneData.Camera.lookyMode,
	"playerMode": data.sceneData.Player.state,
	"ang": data.sceneData.Camera.rotation_degrees,
	"vel": data.sceneData.Player.velocity,
	"run": data.sceneData.Player.stats.running,
	}
	
	match retentionMode:
		RetentionModes.Relative:
			var poser = null
			for child in get_children():
				if child is Marker3D:
					poser = child
					break
			var calc2 = poser.global_transform.origin.angle_to(global_transform.origin) + deg_to_rad(180)
			dict.vel *= Vector3(cos(calc2), 0, sin(calc2))
			dict.ang += Vector3(0, rad_to_deg(calc2), 0)
	
	data.stateArray.append(dict)
	get_tree().change_scene_to_file(goTo)
