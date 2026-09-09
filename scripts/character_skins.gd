extends Node
signal changed
var skins: Array[CharacterSkin] = [
	preload("res://assets/character/traveler.tres"),
	preload("res://assets/character/classic.tres")]
var selected: int = 0
var external_path: String = ""
var external_index: int = -1

func current() -> CharacterSkin:
	return skins[selected]

func select(index: int) -> void:
	if index < 0 or index >= skins.size(): return
	if not skins[index].validation_error().is_empty(): return
	selected = index
	changed.emit()

func next_skin() -> void:
	select((selected + 1) % skins.size())

func handle_shortcut(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		next_skin()
		get_viewport().set_input_as_handled()
		return true
	return false

func load_external(path: String) -> String:
	# Read a fresh PNG directly, so Aseprite exports can be reloaded during play.
	var picture := Image.new()
	if picture.load(path) != OK: return "无法读取 PNG 图片，请检查路径和文件格式"
	if picture.get_width() % 8 != 0 or picture.get_height() % 40 != 0:
		return "图集必须能均分为 8 列 × 40 行"
	var size := Vector2i(picture.get_width() / 8, picture.get_height() / 40)
	if size.x < 16 or size.y < 16: return "每帧至少需要 16 × 16 像素"
	var skin := CharacterSkin.new()
	skin.display_name = "外部 · " + path.get_file().get_basename()
	skin.atlas = ImageTexture.create_from_image(picture)
	skin.frame_size = size
	skin.foot_pivot = Vector2(size) * Vector2(0.5, 0.925)
	skin.display_scale = 112.0 / size.y
	external_path = path
	if external_index < 0:
		external_index = skins.size()
		skins.append(skin)
	else: skins[external_index] = skin
	select(external_index)
	return ""

func reload_external() -> String:
	if external_path.is_empty(): return "请先选择一张外部图集"
	return load_external(external_path)
