class_name CharacterSkin
extends Resource
## Five actions x eight directions, one row per direction, eight frames per row.
@export var display_name: String = "角色"
@export var atlas: Texture2D
@export var frame_size := Vector2i(64, 80)
@export var foot_pivot := Vector2(32, 74)
@export var display_scale: float = 1.4

func validation_error() -> String:
	if atlas == null: return "缺少角色图集"
	if frame_size.x <= 0 or frame_size.y <= 0: return "帧尺寸必须大于 0"
	if atlas.get_width() != frame_size.x * 8 or atlas.get_height() != frame_size.y * 40:
		return "图集需要 8 列 × 40 行，当前帧尺寸与图片不匹配"
	if display_scale <= 0: return "显示倍率必须大于 0"
	return ""
