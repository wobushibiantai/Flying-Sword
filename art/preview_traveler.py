from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[2]
atlas=Image.open(root/'sword/assets/character/traveler/swordsman.png').convert('RGBA')
assert atlas.size==(512,3200)
frames=[]
for f in range(8):
    canvas=Image.new('RGB',(1024,928),'#78807d')
    pen=ImageDraw.Draw(canvas)
    for s,label in enumerate(('IDLE','WALK','CAST','FLY','HOVER')):
        pen.text((8,s*184+4),label,fill='white')
        for d,direction in enumerate(('E','SE','S','SW','W','NW','N','NE')):
            cell=atlas.crop((f*64,(s*8+d)*80,(f+1)*64,(s*8+d+1)*80))
            box=cell.getbbox()
            assert box and box[0]>0 and box[1]>0 and box[2]<64 and box[3]<80
            cell=cell.resize((128,160),Image.Resampling.NEAREST)
            canvas.paste(cell,(d*128,s*184+20),cell)
            pen.text((d*128+58,s*184+171),direction,fill='white')
    frames.append(canvas)
frames[0].save(root/'reference/traveler-animations.png')
frames[0].save(root/'reference/traveler-animations.gif',save_all=True,append_images=frames[1:],duration=100,loop=0)
for r in range(40):
    assert len({atlas.crop((f*64,r*80,(f+1)*64,(r+1)*80)).tobytes() for f in range(8)})>=3
print('TRAVELER_ART_OK 320 unclipped frames, 40 animated rows')
