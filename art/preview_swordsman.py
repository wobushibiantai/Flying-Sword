"""Preview exported Aseprite pixels without modifying game assets."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[2]
atlas = Image.open(root / 'sword/assets/character/swordsman.png').convert('RGBA')
assert atlas.size == (512, 3200)
frames = []
for frame in range(8):
    sheet = Image.new('RGB', (1024, 928), '#667478')
    draw = ImageDraw.Draw(sheet)
    for state, name in enumerate(('IDLE', 'WALK', 'CAST', 'FLY', 'HOVER')):
        draw.text((10, state*184+4), name, fill='#f2e9d5')
        for direction, label in enumerate(('E', 'SE', 'S', 'SW', 'W', 'NW', 'N', 'NE')):
            sprite = atlas.crop((frame*64, (state*8+direction)*80, (frame+1)*64, (state*8+direction+1)*80))
            sheet.paste(sprite.resize((128,160), Image.Resampling.NEAREST), (direction*128, state*184+20), sprite.resize((128,160), Image.Resampling.NEAREST))
            draw.text((direction*128+59,state*184+168), label, fill='white')
    frames.append(sheet)
frames[0].save(root / 'reference/swordsman-animations.png')
frames[0].save(root / 'reference/swordsman-animations.gif', save_all=True, append_images=frames[1:], duration=120, loop=0)
for row in range(40):
    cells = [atlas.crop((f*64,row*80,(f+1)*64,(row+1)*80)) for f in range(8)]
    assert len({im.tobytes() for im in cells}) >= 3, f'Frozen animation row {row}'
    for im in cells:
        box = im.getbbox()
        assert box and box[0]>0 and box[1]>0 and box[2]<64 and box[3]<80, ('Clipped',row,box)
for d in range(8):
    # Shoes remain fixed; robe hems may flutter above them.
    if d not in (0,4):
        shoes=[atlas.crop((f*64,(24+d)*80+73,(f+1)*64,(25+d)*80)).tobytes() for f in range(8)]
        assert len(set(shoes))==1, f'Flight stepping in direction {d}'
for st in range(5):
    right=atlas.crop((0,st*640,64,st*640+80))
    left=atlas.crop((0,st*640+320,64,st*640+400))
    assert right.transpose(Image.Transpose.FLIP_LEFT_RIGHT).tobytes()!=left.tobytes(), 'Side clothing is only mirrored'
skin_colors={(226,199,172,255),(183,151,129,255)}
for state in range(5):
    for frame in range(8):
        heights=[]
        for direction in range(5):
            head=atlas.crop((frame*64,(state*8+direction)*80,(frame+1)*64,(state*8+direction)*80+25))
            ys=[y for y in range(25) for x in range(23,41) if head.getpixel((x,y)) in skin_colors]
            heights.append((min(ys),max(ys)))
        assert len(set(heights))==1, ('Face heights differ',state,frame,heights)
for d in (0,4):
    cells=[atlas.crop((f*64,(24+d)*80,(f+1)*64,(25+d)*80)) for f in range(8)]
    if d==4: cells=[im.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for im in cells]
    fronts=[im.crop((33,44,43,70)).tobytes() for im in cells]
    backs=[im.crop((8,50,29,70)).tobytes() for im in cells]
    assert len(set(fronts))==1, 'Flight front robe must stay fitted'
    assert len(set(backs))>=3, 'Flight rear robe should flutter'
for d in (0,4):
    hover=[atlas.crop((f*64,(32+d)*80,(f+1)*64,(33+d)*80)) for f in range(8)]
    if d==4: hover=[im.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for im in hover]
    assert len({im.crop((33,44,48,75)).tobytes() for im in hover})>=3, 'Hover front should sway again'
print('ASSET_CHECK_OK: 40 animated rows, 320 unclipped frames, moving/hover cloth distinct, face heights aligned')
