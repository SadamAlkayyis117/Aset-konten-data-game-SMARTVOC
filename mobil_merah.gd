extends CharacterBody3D

@onready var anim = $AnimationPlayer

var can_start := false

func _ready():
    anim.play("Move")
