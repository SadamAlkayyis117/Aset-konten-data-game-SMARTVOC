extends Control

# Skrip ini dipasang pada MinimapContainer (misalnya, Control/Panel)

func _gui_input(event):
    # Hanya menanggapi klik tombol kiri mouse
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        
        # 1. Menandai input sudah ditangani agar tidak menembus ke elemen di bawahnya
        get_viewport().set_input_as_handled() 
        
        # 2. Memanggil fungsi toggle di parent (yaitu MapRoot.gd)
        # Parameter 'true' berarti buka Full Map
        if get_parent().has_method("toggle_full_map"):
            get_parent().toggle_full_map(true)
