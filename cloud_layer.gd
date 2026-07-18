extends Node3D

func _process(delta):

	for c in get_children():
		c.position.x += delta * 2.0

		if c.position.x > 500:
			c.position.x = -500
