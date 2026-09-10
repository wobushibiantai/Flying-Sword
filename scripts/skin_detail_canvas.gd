extends Control
var skin: CharacterSkin
var action: int = 0
var direction: int = 2
var clock: float = 0.0

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size), Color("596263"))
	if skin == null: return
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frame := int(clock * (1.0/0.18 if action==0 else 10.0)) % 8
	var source := skin.frame_region(action,direction,frame)
	var texture := skin.texture_for_state(action)
	# Full figure at native pixels when it fits; older skins are enlarged.
	var zoom := minf((size.y-12)/skin.frame_size.y, (size.x*0.58)/skin.frame_size.x)
	var dimensions := Vector2(skin.frame_size)*zoom
	draw_texture_rect_region(texture,Rect2(Vector2(10,6),dimensions),source)
	# Magnified head/collar crop alongside the full character.
	var crop := Rect2(source.position+Vector2(skin.frame_size)*Vector2(0.28,0.02),Vector2(skin.frame_size)*Vector2(0.46,0.38))
	var detail_width := size.x*0.35
	var detail_size := Vector2(detail_width,detail_width*crop.size.y/crop.size.x)
	draw_texture_rect_region(texture,Rect2(Vector2(size.x*0.63,35),detail_size),crop)
