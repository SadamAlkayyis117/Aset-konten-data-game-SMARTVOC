extends Node

enum GameState { FREE_ROAM, REPORT_MODE }
var current_state: GameState = GameState.FREE_ROAM
signal state_changed(new_state)

func enter_report_mode():
    if current_state == GameState.REPORT_MODE: return
    current_state = GameState.REPORT_MODE
    _apply_report_mode()
    state_changed.emit(current_state)

func exit_report_mode():
    if current_state == GameState.FREE_ROAM: return
    current_state = GameState.FREE_ROAM
    _apply_free_roam()
    state_changed.emit(current_state)

func _apply_report_mode():
    get_tree().paused = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _apply_free_roam():
    get_tree().paused = false
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
