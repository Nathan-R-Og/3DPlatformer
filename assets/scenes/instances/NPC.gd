extends Node3D

func _interact(who):
	print("balls")
	await Special.create_timer(2.0).timeout
	print('ok you can go')
	if who is PlayerController:
		who.state = who.originalState
