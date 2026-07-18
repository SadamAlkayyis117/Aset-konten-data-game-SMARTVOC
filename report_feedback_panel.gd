extends Control
class_name ReportFeedbackPanel

# ===============================
# NODE REFERENCES
# ===============================
@onready var dimmer: ColorRect = $Dimmer
@onready var feedback_card: Panel = $FeddbackCard

@onready var title_label: Label = $FeddbackCard/LabelTitle
@onready var status_badge: Label = $FeddbackCard/LabelStatusBadge
@onready var feedback_text: RichTextLabel = $FeddbackCard/Feedbacktext

@onready var continue_button: Button = $FeddbackCard/ButtonContainer/ButtonContinue
@onready var revise_button: Button = $FeddbackCard/ButtonContainer/ButtonRevise


# ===============================
# DATA STATE
# ===============================
var mission_id: String = ""
var report_status: String = ""   # Draft / Reviewed / Approved / Needs Revision
var feedback_message: String = ""


# ===============================
# SIGNALS
# ===============================
signal continue_pressed(mission_id: String)
signal revise_pressed(mission_id: String)


# ===============================
# LIFECYCLE
# ===============================
func _ready() -> void:
    add_to_group("report_feedback")
    _hide_panel()
    _bind_buttons()



# ===============================
# PUBLIC API
# ===============================
## Dipanggil oleh ReportManager / MissionManager
func show_feedback(
    p_mission_id: String,
    p_status: String,
    p_feedback: String
) -> void:
    mission_id = p_mission_id
    report_status = p_status
    feedback_message = p_feedback

    _update_ui()
    _show_panel()


func hide_feedback() -> void:
    _hide_panel()


# ===============================
# UI UPDATE
# ===============================
func _update_ui() -> void:
    title_label.text = "Mission Report Feedback"

    status_badge.text = report_status.to_upper()
    _set_status_style(report_status)

    feedback_text.clear()
    feedback_text.append_text(feedback_message)

    # Button logic
    match report_status:
        "Approved":
            revise_button.visible = false
            continue_button.text = "Continue"
        "Reviewed", "Needs Revision":
            revise_button.visible = true
            continue_button.text = "Continue"
        _:
            revise_button.visible = false
            continue_button.text = "Close"


func _set_status_style(status: String) -> void:
    match status:
        "Approved":
            status_badge.modulate = Color(0.4, 0.8, 0.4) # green
        "Reviewed":
            status_badge.modulate = Color(0.9, 0.8, 0.4) # yellow
        "Needs Revision":
            status_badge.modulate = Color(0.9, 0.4, 0.4) # red
        _:
            status_badge.modulate = Color.WHITE


# ===============================
# VISIBILITY
# ===============================
func _show_panel() -> void:
    visible = true
    mouse_filter = Control.MOUSE_FILTER_STOP


func _hide_panel() -> void:
    visible = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE


# ===============================
# BUTTONS
# ===============================
func _bind_buttons() -> void:
    continue_button.pressed.connect(_on_continue_pressed)
    revise_button.pressed.connect(_on_revise_pressed)


func _on_continue_pressed() -> void:
    emit_signal("continue_pressed", mission_id)
    hide_feedback()


func _on_revise_pressed() -> void:
    emit_signal("revise_pressed", mission_id)
    hide_feedback()
