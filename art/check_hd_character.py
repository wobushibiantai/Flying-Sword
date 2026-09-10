"""Inspect exported pixels and assemble review sheets; does not paint assets."""
from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[2]
folder=root/'sword/assets/character/hd'
names=['idle','walk','cast','fly','hover']
review=Image.new('RGB',(1536,700),'#737777')
pen=ImageDraw.Draw(review)
for state,name in enumerate(names):
    page=Image.open(folder/f'{name}.png').convert('RGBA')
    assert page.size==(3072,5120)
    for d in range(8):
        distinct=set()
        for f in range(8):
            cell=page.crop((f*384,d*640,(f+1)*384,(d+1)*640))
            box=cell.getbbox()
            assert box and box[0]>0 and box[1]>0 and box[2]<384 and box[3]<640,(name,d,f,box)
            distinct.add(cell.tobytes())
        assert len(distinct)>2,(name,d,'Frozen animation')
    if state in (0,2,3):
        i={0:0,2:1,3:2}[state]
        d=6 if state==3 else 2
        cell=page.crop((0,d*640,384,(d+1)*640))
        review.paste(cell,(i*512+64,35),cell)
        pen.text((i*512+32,12),name+' 384x640 native pixels',fill='white')
    print('HD_PIXEL_CHECK_OK',name,page.size,'64 RGBA animation frames')
review.save(root/'reference/hd-native-preview.png')
