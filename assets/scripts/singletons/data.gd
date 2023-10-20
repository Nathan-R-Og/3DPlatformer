extends Node
var stateArray = []
var sceneData = {
	"World": null,
	"Player": null,
	"Objects": null,
	"Level": null,
	"Events": null,
	"Text": null,
	"Warps": null,
	"Music": null,
	"Screen": null,
	"Camera": null,
}





var save = {
	"Slots":[],
	"Settings":{
		
		
		
	}
	
	
}



var DELTA = 0.0
func _ready():
	var place = get_parent()
	var newScreen = CanvasLayer.new()
	newScreen.name = "Screen"
	place.call_deferred("add_child", newScreen)
	sceneData.Screen = newScreen
	var newMusic = AudioStreamPlayer.new()
	newMusic.name = "Music"
	place.call_deferred("add_child", newMusic)
	sceneData.Music = newMusic
func _process(delta):
	DELTA = delta
