extends StaticBody3D

var letter : String

func _ready():
    for child in get_children():
        if child is Label3D:
            child.text = letter

func on_hit_by_projectile(projectile):

    print("KENA HURUF:", letter)

    var controller = get_tree().get_first_node_in_group("archery_controller")

    if controller:
        controller.on_letter_hit(letter)

    queue_free()
