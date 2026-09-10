class_name CharacterSkin
extends Resource
## Five actions x eight directions; frames are packed left-to-right into the atlas.
@export var display_name: String = "角色"
@export var atlas: Texture2D
@export var action_atlases: Array[Texture2D] = []
@export_range(1, 120) var frames_per_direction: int = 8
@export_range(1, 64) var atlas_columns: int = 8
@export var animation_fps: float = 10.0
@export var idle_fps: float = 1.0 / 0.18
@export var frame_size := Vector2i(64, 80)
@export var foot_pivot := Vector2(32, 74)
@export var display_scale: float = 1.4

func validation_error() -> String:
	if frame_size.x <= 0 or frame_size.y <= 0: return "帧尺寸必须大于 0"
	if frames_per_direction <= 0 or atlas_columns <= 0: return "帧数和图集列数必须大于 0"
	if animation_fps <= 0 or idle_fps <= 0: return "播放帧率必须大于 0"
	var directions := 8 if not action_atlases.is_empty() else 40
	var rows := ceili(float(directions * frames_per_direction) / atlas_columns)
	var expected := Vector2i(atlas_columns, rows) * frame_size
	if not action_atlases.is_empty():
		if action_atlases.size() != 5: return "分动作图集需要 5 张图片"
		for page in action_atlases:
			if page == null or Vector2i(page.get_size()) != expected:
				return "分动作图集尺寸与帧数、列数不匹配"
	else:
		if atlas == null: return "缺少角色图集"
		if Vector2i(atlas.get_size()) != expected:
			return "图集尺寸与帧数、列数不匹配"
	if display_scale <= 0: return "显示倍率必须大于 0"
	return ""

func texture_for_state(state: int) -> Texture2D:
	return action_atlases[state] if not action_atlases.is_empty() else atlas

func frame_region(state: int, direction: int, frame: int) -> Rect2:
	var row := direction if not action_atlases.is_empty() else state * 8 + direction
	var index := row * frames_per_direction + posmod(frame, frames_per_direction)
	return Rect2(Vector2(index % atlas_columns, floori(float(index) / atlas_columns)) * Vector2(frame_size), Vector2(frame_size))

func frame_at_time(state: int, seconds: float) -> int:
	return posmod(floori(seconds * (idle_fps if state == 0 else animation_fps)), frames_per_direction)
