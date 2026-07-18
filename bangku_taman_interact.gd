extends Area3D

const INTERACTION_LABEL = preload("res://interaction_label_text.tscn")
var interaction_ui: Node = null

var player_in_range: bool = false
var player_ref: CharacterBody3D = null
var cooldown: bool = false


func _ready():
    connect("body_entered", Callable(self, "_on_body_entered"))
    connect("body_exited", Callable(self, "_on_body_exited"))
    hide_interaction_prompt()


func _on_body_entered(body):
    if body is CharacterBody3D and body.is_in_group("player"):
        player_in_range = true
        player_ref = body

        # === Tampilkan label hanya jika player BERDIRI ===
        if not player_ref.sitting:
            show_interaction_prompt()


func _on_body_exited(body):
    if body == player_ref:
        player_in_range = false
        player_ref = null
        hide_interaction_prompt()


func _process(delta):
    if player_ref == null:
        return

    # === Player duduk → auto-hide label ===
    if player_ref.sitting:
        hide_interaction_prompt()
        return

    # === Player berdiri + masih dalam area → pastikan label tampil ===
    if player_in_range and not player_ref.sitting:
        if interaction_ui == null:
            show_interaction_prompt()
    else:
        hide_interaction_prompt()

    # === Tidak boleh interaksi kalau lock, duduk, cooldown ===
    if player_ref.stand_up_lock:
        return
    if cooldown:
        return

    # === Tekan E untuk duduk ===
    if player_in_range and Input.is_action_just_pressed("Interaksi"):

        var sit_point = get_node_or_null("SitPoint")
        if sit_point == null:
            push_warning("SitPoint tidak ditemukan.")
            return

        cooldown = true

        # Player mulai duduk → hide label
        hide_interaction_prompt()

        player_ref.sit_on_chair(self, sit_point)

        await get_tree().create_timer(0.35).timeout
        cooldown = false


# ==========================================================
# LABEL SYSTEM
# ==========================================================

func show_interaction_prompt():
    hide_interaction_prompt()

    interaction_ui = INTERACTION_LABEL.instantiate()
    get_tree().get_root().add_child(interaction_ui)

    var label_node = interaction_ui.get_node_or_null("Label")
    if label_node:
        label_node.text = "[E] Tekan Untuk Interaksi"


func hide_interaction_prompt():
    if is_instance_valid(interaction_ui):
        interaction_ui.queue_free()
    interaction_ui = null
