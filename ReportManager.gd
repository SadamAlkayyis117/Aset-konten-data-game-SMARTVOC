extends Node

signal report_reviewed(mission_id: String, status: String, feedback: String)
var report_rules: Dictionary = {}
var active_reports: Dictionary = {}

func _ready() -> void:
    _load_report_rules()

func _load_report_rules() -> void:
    var path = "res://MissionReport.json"
    if not ResourceLoader.exists(path): return
    var file = FileAccess.open(path, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    for rule in parsed.get("mission_reports", []):
        report_rules[rule["id"]] = rule

func submit_report(mission_id: String, report_text: String) -> void:
    active_reports[mission_id] = {"text": report_text, "status": "Submitted"}
    _review_report(mission_id)

func _review_report(mission_id: String) -> void:
    var mission = MissionManager.get_mission(mission_id)
    var rule_id = mission.get("report_rules_id", "")
    if not report_rules.has(rule_id): return

    var rules = report_rules[rule_id]
    var text = active_reports[mission_id]["text"]
    var word_count = text.split(" ", false).size()
    
    var status = "Approved"
    var feedback = rules["feedback"]["accepted"]

    if word_count < int(rules["min_words"]):
        status = "Needs Revision"
        feedback = rules["feedback"]["too_short"]
    else:
        for kw in rules["required_keywords"]:
            if not text.to_lower().contains(kw.to_lower()):
                status = "Needs Revision"
                feedback = rules["feedback"]["missing_keywords"]
                break

    active_reports[mission_id]["status"] = status
    report_reviewed.emit(mission_id, status, feedback)
    
    # Panggil Feedback Panel secara otomatis
    var feedback_panel = get_tree().current_scene.find_child("ReportFeedbackPanel", true, false)
    if feedback_panel:
        feedback_panel.show_feedback(mission_id, status, feedback)
