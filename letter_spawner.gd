extends Node3D

@export var path_node : Path3D
@export var letter_scene : PackedScene

var speed := 15.0
var running := false
var spawn_delay := 1.7
var active_follows := []

func _ready() -> void:
    add_to_group("letter_spawner")

func start_spawning():
    if running:
        return

    # 🔥 CLEAR PATH
    for f in active_follows:
        if is_instance_valid(f):
            f.queue_free()

    active_follows.clear()

    running = true
    _loop()

func stop_spawning():
    running = false

func _loop():
    while running:
        spawn_letter()
        await get_tree().create_timer(spawn_delay).timeout

func spawn_letter():

    if not path_node:
        print("ERROR: Path node belum di assign")
        return

    var controller = get_tree().get_first_node_in_group("archery_controller")

    var path_follow = PathFollow3D.new()
    path_node.add_child(path_follow)

    path_follow.progress = 0

    var letter = letter_scene.instantiate()

    if controller:

        var answer = controller.current_answer
        var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        if randf() < 0.4:
            letter.letter = answer[randi() % answer.length()]
        else:
            var wrong_letters = ""
            for c in alphabet:
                if not c in answer:
                    wrong_letters += c
            letter.letter = wrong_letters[randi() % wrong_letters.length()]
    else:
        letter.letter = char(randi_range(65, 90))
    path_follow.add_child(letter)
    active_follows.append(path_follow)

func _process(delta):

    for f in active_follows.duplicate():

        if not is_instance_valid(f):
            active_follows.erase(f)
            continue

        f.progress += speed * delta

        if f.progress_ratio >= 0.99:
            f.queue_free()
            active_follows.erase(f)
