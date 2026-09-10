class_name CharacterSkin
extends Resource
## Five actions x eight directions, one row per direction, eight frames per row.
@export var display_name: String = "角色"
@export var atlas: Texture2D
@export var action_atlases: Array[Texture2D] = []
@export var frame_size := Vector2i(64, 80)
@export var foot_pivot := Vector2(32, 74)
@export var display_scale: float = 1.4

func validation_error() -> String:
	if frame_size.x <= 0 or frame_size.y <= 0: return "帧尺寸必须大于 0"
	if not action_atlases.is_empty():
		if action_atlases.size() != 5: return "分动作图集需要 5 张图片"
		for page in action_atlases:
			if page == null or page.get_width() != frame_size.x * 8 or page.get_height() != frame_size.y * 8:
				return "每张分动作图集需要 8 列 × 8 行"
	else:
		if atlas == null: return "缺少角色图集"
		if atlas.get_width() != frame_size.x * 8 or atlas.get_height() != frame_size.y * 40:
			return "图集需要 8 列 × 40 行，当前帧尺寸与图片不匹配"
	if display_scale <= 0: return "显示倍率必须大于 0"
	return ""

func texture_for_state(state: int) -> Texture2D:
	return action_atlases[state] if not action_atlases.is_empty() else atlas

func frame_region(state: int, direction: int, frame: int) -> Rect2:
	var row := direction if not action_atlases.is_empty() else state * 8 + direction
	return Rect2(Vector2(frame, row) * Vector2(frame_size), Vector2(frame_size))
