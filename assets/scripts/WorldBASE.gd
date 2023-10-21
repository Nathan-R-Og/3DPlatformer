extends Spatial
export var Level = NodePath()
export var Objects = NodePath()
export var Player = NodePath()
export var Events = NodePath()
export var Text = NodePath()
export var Warps = NodePath()
export var Camera = NodePath()
export var autoAssign = true
func _enter_tree():
	if autoAssign:
		Player = "Objects/Player"
		Objects = "Objects"
		Level = "Level"
		Events = "Level/Events"
		Text = "Hud/Text"
		Warps = "Level/Warps"
		Camera = "Level/Target"
	data.sceneData.World = self
	data.sceneData.Player = get_node_or_null(Player)
	data.sceneData.Objects = get_node_or_null(Objects)
	data.sceneData.Level = get_node_or_null(Level)
	data.sceneData.Events = get_node_or_null(Events)
	data.sceneData.Text = get_node_or_null(Text)
	data.sceneData.Warps = get_node_or_null(Warps)
	data.sceneData.Camera = get_node_or_null(Camera)
class_name StandardWorld
