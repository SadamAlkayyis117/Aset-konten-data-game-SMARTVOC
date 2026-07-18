extends Control

@onready var grid = $Panel_background/ScrollContainer/GridMedia

@onready var viewer = $ViewerPanel
@onready var tex = $ViewerPanel/TextureRect
@onready var vid = $ViewerPanel/VideoStreamPlayer
@onready var btn_close = $Panel_background/Button_Close
@onready var edit_photo = $EditFotoPanel
@onready var edit_tex = $EditFotoPanel/TextureRect
@onready var edit_video_tex = $EditVideoPanel/TextureRect
@onready var edit_video = $EditVideoPanel
@onready var timeline_slider = $ViewerPanel/HSliderTimeLine
@onready var trim_start = $EditVideoPanel/HSliderTrimStart
@onready var trim_end = $EditVideoPanel/HSliderTrimEnd
@onready var loading_panel = $LoadingPanel
@onready var loading_label = $LoadingPanel/Label_Status
@onready var loading_bar = $LoadingPanel/ProgressBar
@onready var loading_back = $LoadingPanel/Button_Bck
@onready var loading_open = $"LoadingPanel/Button_Open Folder"


var icon_play = preload("res://Play Video.png")
var icon_pause = preload("res://Pause_Video.png")
var muted := false
var selected_path = ""
var current_image : Image = null
var is_video := false
var playing := false
var video_frames = []
var current_frame = 0
var play_task_running = false
var playback_delay := 0.15
var fps := 6.66
var speed_multiplier := 1

func _ready():

    tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tex.custom_minimum_size = Vector2(579,325)

    edit_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    edit_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    edit_tex.custom_minimum_size = Vector2(579,325)

    edit_video_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    edit_video_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    edit_video_tex.custom_minimum_size = Vector2(579,325)

    $ViewerPanel/ButtonDelete.pressed.connect(_on_Button_Delete_pressed)
    $ViewerPanel/ButtonSave.pressed.connect(_on_Button_Save_pressed)
    $ViewerPanel/ButtonEdit.pressed.connect(_on_Button_Edit_pressed)
    $ViewerPanel/ButtonBack.pressed.connect(_on_Button_Back_pressed)
    $ViewerPanel/ButtonPlay_Pause.pressed.connect(_on_Button_PlayPause_pressed)

    $EditFotoPanel/ButtonBlackWhite.pressed.connect(_on_Button_BW_pressed)
    $EditFotoPanel/ButtonCrop.pressed.connect(_on_Button_Crop_pressed)
    $EditFotoPanel/ButtonRotate.pressed.connect(_on_Button_Rotate_pressed)
    $EditFotoPanel/ButtonSaveEdit.pressed.connect(_on_Button_SaveEdit_pressed)
    $EditFotoPanel/ButtonBackPhoto.pressed.connect(_on_Button_BackPhoto_pressed)

    $EditVideoPanel/ButtonBackVideo.pressed.connect(_on_Button_BackVideo_pressed)
    $EditVideoPanel/ButtonTrim.pressed.connect(_on_Button_Trim_pressed)
    $EditVideoPanel/ButtonMute.pressed.connect(_on_Button_Mute_pressed)
    $EditVideoPanel/ButtonSpeed.pressed.connect(_on_Button_Speed_pressed)
    $EditVideoPanel/ButtonSaveVideo.pressed.connect(_on_Button_SaveVideoEdit_pressed)
    timeline_slider.value_changed.connect(_on_timeline_changed)
    trim_start.value_changed.connect(_update_trim_label)
    trim_end.value_changed.connect(_update_trim_label)
    _update_play_button_icon()
    visible = false
    viewer.visible = false
    edit_photo.visible = false
    edit_video.visible = false
    loading_panel.visible = false
    loading_back.pressed.connect(_on_LoadingBack_pressed)
    loading_open.pressed.connect(_on_OpenFolder_pressed)
    btn_close.pressed.connect(close_app)


func open_gallery():

    visible = true
    load_gallery()


func _show_loading_start():

    loading_panel.visible = true
    loading_label.text = "Converting Video..."
    loading_bar.value = 0

    loading_back.visible = false
    loading_open.visible = false


func _show_loading_done():

    loading_label.text = "Convert Selesai!"
    loading_bar.value = 100

    loading_back.visible = true
    loading_open.visible = true

func _update_play_button_icon():

    if playing:
        $ViewerPanel/ButtonPlay_Pause.texture_normal = icon_pause
    else:
        $ViewerPanel/ButtonPlay_Pause.texture_normal = icon_play

func load_gallery():

    for c in grid.get_children():
        c.queue_free()

    _load_photos()
    _load_videos()


func _load_photos():

    var dir = DirAccess.open(GalleryManager.photo_path)

    if dir == null:
        return

    dir.list_dir_begin()

    var file = dir.get_next()

    while file != "":

        if file.ends_with(".png") and not file.begins_with("thumb_"):
            create_photo_button(file)

        file = dir.get_next()

    dir.list_dir_end()

func _load_videos():

    var dir = DirAccess.open(GalleryManager.video_path)

    if dir == null:
        return

    dir.list_dir_begin()

    while true:

        var file = dir.get_next()

        if file == "":
            break

        # hanya folder video baru
        if dir.current_is_dir():
            create_video_button(file)

    dir.list_dir_end()


# ==================================================
# THUMBNAIL FOTO
# ==================================================

func create_photo_button(file):

    var btn = TextureButton.new()
    btn.custom_minimum_size = Vector2(223.53,125.74)
    btn.ignore_texture_size = true
    btn.stretch_mode = TextureButton.STRETCH_SCALE

    var thumb_path = GalleryManager.photo_path + "thumb_" + file

    var img = Image.new()

    if img.load(thumb_path) != OK:
        img.load(GalleryManager.photo_path + file)
    img.rotate_180()
    img.resize(250,180)

    var tx = ImageTexture.create_from_image(img)
    btn.texture_normal = tx

    btn.pressed.connect(_open_photo.bind(GalleryManager.photo_path + file))

    grid.add_child(btn)

func get_video_duration():
    return video_frames.size() / fps

func format_time(sec):
    var m = int(sec / 60)
    var s = int(sec) % 60
    return str(m).pad_zeros(2) + ":" + str(s).pad_zeros(2)

func create_video_button(folder):

    var thumb_path = GalleryManager.video_path + folder + "/thumb.png"

    if not FileAccess.file_exists(thumb_path):
        return

    var btn = TextureButton.new()
    btn.custom_minimum_size = Vector2(223.53,125.74)
    btn.ignore_texture_size = true
    btn.stretch_mode = TextureButton.STRETCH_SCALE
    btn.ignore_texture_size = true

    var img = Image.new()

    if img.load(thumb_path) != OK:
        return

    img.rotate_180()
    img.resize(250,180)

    var tx = ImageTexture.create_from_image(img)

    btn.texture_normal = tx
    btn.texture_pressed = tx
    btn.texture_hover = tx

    btn.pressed.connect(_open_video.bind(folder))

    grid.add_child(btn)
# ==================================================
# OPEN PHOTO
# ==================================================

func _open_photo(path):

    selected_path = path
    is_video = false

    viewer.visible = true
    tex.visible = true
    vid.visible = false

    _set_viewer_video_ui(false)

    current_image = Image.new()
    current_image.load(path)
    current_image.rotate_180()

    tex.texture = ImageTexture.create_from_image(current_image)


# ==================================================
# OPEN VIDEO
# ==================================================

func _open_video(folder):

    selected_path = folder
    is_video = true
    playing = false
    current_frame = 0

    viewer.visible = true
    tex.visible = true
    vid.visible = false

    _set_viewer_video_ui(true)

    load_video_frames(folder)

    timeline_slider.max_value = max(video_frames.size() - 1, 0)
    timeline_slider.value = 0

    $ViewerPanel/LabelTimeNow.text = "00:00"
    $ViewerPanel/LabelTimeMax.text = format_time(get_video_duration())

    _update_speed_label()

func _on_timeline_changed(value):

    if not is_video:
        return

    current_frame = int(value)

    _show_frame(current_frame)

    var now_sec = current_frame / fps
    $ViewerPanel/LabelTimeNow.text = format_time(now_sec)

func _update_speed_label():

    var txt = "x" + str(speed_multiplier)

    $ViewerPanel/LabelSpeed.text = txt
    $EditVideoPanel/LabelSpeed.text = txt

func load_video_frames(folder):

    video_frames.clear()
    current_frame = 0

    var dir = DirAccess.open(GalleryManager.video_path + folder)

    if dir == null:
        return

    dir.list_dir_begin()

    while true:

        var file = dir.get_next()

        if file == "":
            break

        if file.ends_with(".png") and file != "thumb.png":
            video_frames.append(file)

    dir.list_dir_end()

    video_frames.sort()

    if video_frames.size() > 0:
        _show_frame(0)

func _show_frame(index):

    if index < 0 or index >= video_frames.size():
        return

    var path = GalleryManager.video_path + selected_path + "/" + video_frames[index]

    var img = Image.new()

    if img.load(path) != OK:
        return

    img.rotate_180()

    tex.texture = ImageTexture.create_from_image(img)

func play_video_frames(folder):

    var dir = DirAccess.open(GalleryManager.video_path + folder)

    if dir == null:
        return

    dir.list_dir_begin()

    while true:

        var file = dir.get_next()

        if file == "":
            break

        if file.ends_with(".png") and file != "thumb.png":

            var img = Image.new()
            img.load(GalleryManager.video_path + folder + "/" + file)

            tex.texture = ImageTexture.create_from_image(img)

            await get_tree().create_timer(0.15).timeout


# ==================================================
# PLAY / PAUSE
# ==================================================

func _on_Button_PlayPause_pressed():

    if not is_video:
        return

    if not playing and current_frame >= video_frames.size() - 1:
        current_frame = 0
        timeline_slider.value = 0
        _show_frame(0)
        $ViewerPanel/LabelTimeNow.text = "00:00"

    playing = !playing

    _update_play_button_icon()

    if playing and not play_task_running:
        _play_video_loop()

func _play_video_loop():

    play_task_running = true

    while playing:

        _show_frame(current_frame)

        timeline_slider.value = current_frame

        var now_sec = current_frame / fps
        $ViewerPanel/LabelTimeNow.text = format_time(now_sec)

        current_frame += 1

        # selesai video
        if current_frame >= video_frames.size():

            current_frame = video_frames.size() - 1
            playing = false

            _update_play_button_icon()

            break

        await get_tree().create_timer(playback_delay).timeout

    play_task_running = false

func _on_Button_Delete_pressed():

    if is_video:

        var path = GalleryManager.video_path + selected_path + "/"
        delete_folder_recursive(path)

    else:

        DirAccess.remove_absolute(selected_path)

    viewer.visible = false
    load_gallery()
    
func delete_folder_recursive(path):

    var dir = DirAccess.open(path)

    if dir == null:
        return

    dir.list_dir_begin()

    while true:

        var file = dir.get_next()

        if file == "":
            break

        if file == "." or file == "..":
            continue

        DirAccess.remove_absolute(path + file)

    dir.list_dir_end()

    DirAccess.remove_absolute(path)


# ==================================================
# SAVE
# ==================================================

func _on_Button_Save_pressed():

    if is_video:
        _save_video_mp4()
        return

    var file_name = selected_path.get_file()
    var out_path = GalleryManager.export_path + file_name

    var err = current_image.save_png(out_path)

    if err == OK:
        print("📷 FOTO BERHASIL DISAVE:", out_path)
    else:
        print("❌ GAGAL SAVE FOTO:", err)

# ==================================================
# GANTI TOTAL _save_video_mp4()
# ==================================================

func _save_video_mp4():

    _show_loading_start()

    await get_tree().process_frame

    var ffmpeg_path = ProjectSettings.globalize_path("res://ffmpeg.exe")

    var input_folder = ProjectSettings.globalize_path(
        GalleryManager.video_path + selected_path + "/"
    )

    var clean_name = "VID_" + Time.get_datetime_string_from_system()
    clean_name = clean_name.replace(":", "-")
    clean_name = clean_name.replace(" ", "_")

    var output_file = ProjectSettings.globalize_path(
        GalleryManager.export_path + clean_name + ".mp4"
    )

    if not FileAccess.file_exists("res://ffmpeg.exe"):
        loading_label.text = "ffmpeg.exe tidak ditemukan!"
        return

    if not FileAccess.file_exists(input_folder + "0000.png"):
        loading_label.text = "Frame video tidak ditemukan!"
        return

    loading_bar.value = 25
    await get_tree().process_frame

    var args = [
        "-y",
        "-framerate", str(round(fps)),
        "-i", input_folder + "%04d.png",
        "-vf", "hflip,vflip",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        output_file
    ]

    loading_bar.value = 60
    await get_tree().process_frame

    var output := []
    var code = OS.execute(ffmpeg_path, args, output, true)

    loading_bar.value = 95
    await get_tree().process_frame

    if code == 0:
        _show_loading_done()
    else:
        loading_label.text = "Convert Gagal!"
        loading_bar.value = 0


# ==================================================
# EDIT
# ==================================================

func _on_Button_Edit_pressed():
    viewer.visible = false
    if is_video:

        edit_video.visible = true
        _show_edit_video_frame(0)

        $EditVideoPanel/HSliderTrimStart.max_value = video_frames.size() - 1
        $EditVideoPanel/HSliderTrimEnd.max_value = video_frames.size() - 1
        await get_tree().process_frame
        $EditVideoPanel/HSliderTrimStart.value = 0
        $EditVideoPanel/HSliderTrimEnd.value = trim_end.max_value
        _update_speed_label()
        _update_trim_label()

    else:

        edit_photo.visible = true

        var tx = ImageTexture.create_from_image(current_image)
        edit_tex.texture = tx

func _update_trim_label(value = 0):

    if video_frames.size() == 0:
        return

    var a = int($EditVideoPanel/HSliderTrimStart.value)
    var b = int($EditVideoPanel/HSliderTrimEnd.value)

    if b < a:
        b = a
        $EditVideoPanel/HSliderTrimEnd.value = b

    var sec_a = a / fps
    var sec_b = b / fps

    $EditVideoPanel/LabelTrimInfo.text = format_time(sec_a) + " - " + format_time(sec_b)

func refresh_edit_texture():

    if current_image == null:
        return

    edit_tex.texture = ImageTexture.create_from_image(current_image)
    edit_tex.custom_minimum_size = Vector2(579,325)


# ==================================================
# PHOTO FILTER
# ==================================================

func _on_Button_BW_pressed():

    for x in range(current_image.get_width()):
        for y in range(current_image.get_height()):

            var c = current_image.get_pixel(x,y)
            var g = (c.r+c.g+c.b)/3

            current_image.set_pixel(x,y,Color(g,g,g))

    refresh_edit_texture()


func _on_Button_Rotate_pressed():

    current_image.rotate_180()
    refresh_edit_texture()


func _on_Button_Crop_pressed():

    var w = current_image.get_width()
    var h = current_image.get_height()

    var crop_x = int(w / 4)
    var crop_y = int(h / 4)
    var crop_w = int(w / 2)
    var crop_h = int(h / 2)

    var new_img = Image.create(crop_w, crop_h, false, current_image.get_format())

    new_img.blit_rect(
        current_image,
        Rect2i(crop_x, crop_y, crop_w, crop_h),
        Vector2i.ZERO
    )

    current_image = new_img

    refresh_edit_texture()


func _on_Button_SaveEdit_pressed():

    var err = current_image.save_png(selected_path)

    if err != OK:
        print("Gagal save edit:", err)
        return

    # regenerate thumbnail
    var thumb = current_image.duplicate()

    thumb.resize(250,180, Image.INTERPOLATE_LANCZOS)

    var thumb_path = GalleryManager.photo_path + "thumb_" + selected_path.get_file()

    thumb.save_png(thumb_path)

    print("EDIT TERSIMPAN")

    edit_photo.visible = false
    viewer.visible = false

    load_gallery()

func _show_edit_video_frame(index):

    if index < 0 or index >= video_frames.size():
        return

    var path = GalleryManager.video_path + selected_path + "/" + video_frames[index]

    var img = Image.new()

    if img.load(path) != OK:
        return

    img.rotate_180()

    edit_video_tex.texture = ImageTexture.create_from_image(img)

func _set_viewer_video_ui(show_video_ui: bool):

    $ViewerPanel/ButtonPlay_Pause.visible = show_video_ui
    $ViewerPanel/HSliderTimeLine.visible = show_video_ui
    $ViewerPanel/LabelTimeNow.visible = show_video_ui
    $ViewerPanel/LabelTimeMax.visible = show_video_ui
    $ViewerPanel/LabelSpeed.visible = show_video_ui

func _on_Button_Trim_pressed():

    var start_i = int($EditVideoPanel/HSliderTrimStart.value)
    var end_i = int($EditVideoPanel/HSliderTrimEnd.value)

    if end_i <= start_i:
        return

    var new_frames = []

    for i in range(start_i, end_i + 1):
        new_frames.append(video_frames[i])

    video_frames = new_frames

    _show_edit_video_frame(0)

    $EditVideoPanel/HSliderTrimStart.value = 0
    $EditVideoPanel/HSliderTrimEnd.value = video_frames.size() - 1

    _update_trim_label()

func _on_Button_Mute_pressed():

    muted = !muted

    if muted:
        print("Muted")
    else:
        print("Unmuted")

func _on_Button_Speed_pressed():

    if speed_multiplier == 1:
        speed_multiplier = 2
    else:
        speed_multiplier = 1

    _update_speed_label()

func _on_Button_SaveVideoEdit_pressed():

    var folder = GalleryManager.video_path + selected_path + "/"
    var temp_folder = GalleryManager.video_path + selected_path + "_temp/"

    # bersihin temp kalau ada
    if DirAccess.dir_exists_absolute(temp_folder):
        delete_folder_recursive(temp_folder)

    DirAccess.make_dir_recursive_absolute(temp_folder)

    # copy frame yang masih dipakai ke temp
    var new_index = 0
    for i in range(0, video_frames.size(), speed_multiplier):

        var old_path = folder + video_frames[i]

        var img = Image.new()
        if img.load(old_path) != OK:
            continue

        var new_path = temp_folder + str(i).pad_zeros(4) + ".png"
        img.save_png(new_path)
        
        new_index += 1

    # thumbnail baru
    var thumb = Image.new()
    if thumb.load(temp_folder + "0000.png") == OK:
        thumb.resize(250,180, Image.INTERPOLATE_LANCZOS)
        thumb.save_png(temp_folder + "thumb.png")

    # hapus folder lama
    delete_folder_recursive(folder)

    # rename temp jadi folder asli
    DirAccess.rename_absolute(temp_folder, folder)

    edit_video.visible = false
    viewer.visible = false

    load_gallery()

    print("Video edit saved")


# ==================================================
# BACK
# ==================================================

func _on_Button_Back_pressed():
    playing = false
    _update_play_button_icon()
    viewer.visible = false

func _on_Button_BackPhoto_pressed():
    edit_photo.visible = false
    viewer.visible = true

func _on_Button_BackVideo_pressed():
    edit_video.visible = false
    viewer.visible = true

func _on_Button_Close_pressed():
    visible = false

func _on_LoadingBack_pressed():
    loading_panel.visible = false

func _on_OpenFolder_pressed():
    OS.shell_open(ProjectSettings.globalize_path(GalleryManager.export_path))

func close_app():
    visible = false
    get_parent().close_current_app()
