extends CanvasLayer

# =========================
# REFERENCES
# =========================
@onready var bladder_circle  = $Root/Panel/Bladder
@onready var mood_circle     = $Root/Panel/Mood
@onready var hunger_circle   = $Root/Panel/Hunger
@onready var thirsty_circle  = $Root/Panel/Thirsty
@onready var social_circle   = $Root/Panel/Social
@onready var energy_circle   = $Root/Panel/Energy
@onready var health_circle   = $Root/Panel/Health
@onready var hygiene_circle  = $Root/Panel/Hygiene

# =========================
# READY
# =========================
func _ready():
    process_mode = Node.PROCESS_MODE_INHERIT
    
    if NeedsManager:
        NeedsManager.needs_updated.connect(_update_ui)
    
    _update_ui()
    
func _update_ui():

    bladder_circle.value = NeedsManager.bladder
    mood_circle.value = NeedsManager.mood
    hunger_circle.value = NeedsManager.hunger
    thirsty_circle.value = NeedsManager.thirsty
    social_circle.value = NeedsManager.social
    energy_circle.value = NeedsManager.energy
    health_circle.value = NeedsManager.health
    hygiene_circle.value = NeedsManager.hygiene

    _apply_visual_feedback()

func _apply_visual_feedback():

    _set_color(bladder_circle)
    _set_color(mood_circle)
    _set_color(hunger_circle)
    _set_color(thirsty_circle)
    _set_color(social_circle)
    _set_color(energy_circle)
    _set_color(health_circle)
    _set_color(hygiene_circle)

func _set_color(circle: TextureProgressBar):

    var percent = circle.value

    if percent > 60:
        circle.modulate = Color(1.0, 1.0, 1.0) # putih
    elif percent > 30:
        circle.modulate = Color(0.5, 0.7, 1.0) # sky blue
    else:
        circle.modulate = Color(1, 0.2, 0.2) # merah
