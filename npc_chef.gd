extends CharacterBody3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var teflon = $metarig/Skeleton3D/BoneAttachment3D/Teflon

func _ready():
	anim_player.play("Cooking")
