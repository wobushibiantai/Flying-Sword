"""Preview exported Aseprite pixels without modifying game assets."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[2]
atlas = Image.open(root / 'sword/assets/character/swordsman.png').convert('RGBA')
assert atlas.size == (512, 1920)
frames = []
for frame in range(8):
    sheet = Image.new('RGB', (1024, 560), '#667478')
    draw = ImageDraw.Draw(sheet)
    for state, name in enumerate(('IDLE', 'WALK', 'CAST')):
        draw.text((10, state*184+4), name, fill='#f2e9d5')
        for direction, label in enumerate(('E', 'SE', 'S', 'SW', 'W', 'NW', 'N', 'NE')):
            sprite = atlas.crop((frame*64, (state*8+direction)*80, (frame+1)*64, (state*8+direction+1)*80))
            sheet.paste(sprite.resize((128,160), Image.Resampling.NEAREST), (direction*128, state*184+20), sprite.resize((128,160), Image.Resampling.NEAREST))
            draw.text((direction*128+59,state*184+168), label, fill='white')
    frames.append(sheet)
frames[0].save(root / 'reference/swordsman-animations.png')
frames[0].save(root / 'reference/swordsman-animations.gif', save_all=True, append_images=frames[1:], duration=120, loop=0)
for row in range(24):
    cells = [atlas.crop((f*64,row*80,(f+1)*64,(row+1)*80)) for f in range(8)]
    assert len({im.tobytes() for im in cells}) >= 3, f'Frozen animation row {row}'
    for im in cells:
        box = im.getbbox()
        assert box and box[0]>0 and box[1]>0 and box[2]<64 and box[3]<80, ('Clipped',row,box)
print('ASSET_CHECK_OK: 24 animated rows, 192 unclipped frames')
