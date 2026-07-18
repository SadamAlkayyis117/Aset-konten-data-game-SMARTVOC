# PerformanceSettings.gd (AutoLoad)
extends Node

# Resolusi Dasar (Ganti dengan ukuran Jendela Game Anda)
const BASE_WIDTH = 1280
const BASE_HEIGHT = 720

# Persentase skala untuk setiap setting kualitas
const RESOLUTION_SCALES = {
    "HIGH": 1.0,  # 100%
    "MEDIUM": 0.85, # 85%
    "LOW": 0.65   # 65% (Paling optimal untuk FPS)
}

# Array ini untuk mengisi item di Dropdown
const QUALITY_OPTIONS = ["HIGH", "MEDIUM", "LOW"]

func set_quality_setting(quality_level: String):
    if not RESOLUTION_SCALES.has(quality_level):
        push_error("Invalid quality level: " + quality_level)
        return

    var scale = RESOLUTION_SCALES[quality_level]

    # Hitung resolusi baru
    var new_width = int(BASE_WIDTH * scale)
    var new_height = int(BASE_HEIGHT * scale)

    # Terapkan perubahan ke Viewport utama
    DisplayServer.window_set_size(Vector2i(new_width, new_height))
    print("Quality set to %s: %dx%d" % [quality_level, new_width, new_height])
