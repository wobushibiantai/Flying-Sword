"""Inspect exported pixels and assemble review sheets; does not paint assets."""
from pathlib import Path
from PIL import Image, ImageDraw
import hashlib
import numpy as np
root=Path(__file__).resolve().parents[2]
folder=root/'sword/assets/character/hd'
names=['idle','walk','cast','fly','hover']
count,columns=24,16
def get_frame(page,d,f):
    index=d*count+f
    x,y=(index%columns)*384,(index//columns)*640
    return page.crop((x,y,x+384,y+640))
def silhouette_steps(cells):
    masks=[np.asarray(c.getchannel('A'))>127 for c in cells]
    return [np.count_nonzero(a^b)/max(1,np.count_nonzero(a|b))
            for a,b in zip(masks,masks[1:]+masks[:1])]
review=Image.new('RGB',(1536,700),'#737777')
pen=ImageDraw.Draw(review)
for state,name in enumerate(names):
    page=Image.open(folder/f'{name}.png').convert('RGBA')
    assert page.size==(6144,7680)
    largest_step=0
    for d in range(8):
        distinct=set()
        cells=[]
        for f in range(count):
            cell=get_frame(page,d,f)
            cells.append(cell)
            box=cell.getbbox()
            assert box and box[0]>0 and box[1]>0 and box[2]<384 and box[3]<640,(name,d,f,box)
            distinct.add(hashlib.sha256(cell.tobytes()).digest())
        assert len(distinct)==count,(name,d,'Duplicated in-between frames',len(distinct))
        steps=silhouette_steps(cells)
        largest_step=max(largest_step,max(steps))
        assert max(steps)<0.12,(name,d,'Silhouette jumps',steps)
        assert steps[-1]<=max(steps[:-1])*1.3,(name,d,'Loop seam',steps)
    if state in (0,2,3):
        i={0:0,2:1,3:2}[state]
        d=6 if state==3 else 2
        cell=get_frame(page,d,0)
        review.paste(cell,(i*512+64,35),cell)
        pen.text((i*512+32,12),name+' 384x640 native pixels',fill='white')
    print('HD_PIXEL_CHECK_OK',name,page.size,'192 unique RGBA frames, max silhouette step',round(largest_step,4))
    if name=='walk':
        before=root/'reference/hd-walk-before-24.png'
        if before.exists():
            old=Image.open(before).convert('RGBA')
            old_steps=silhouette_steps([old.crop((f*384,0,(f+1)*384,640)) for f in range(8)])
            new_steps=silhouette_steps([get_frame(page,0,f) for f in range(count)])
            assert max(new_steps)<max(old_steps)*0.5,'Walk still jumps as much as before'
            print('WALK_CONTINUITY old_max=',round(max(old_steps),4),'new_max=',round(max(new_steps),4))
        clips=[]
        for f in range(count):
            clip=Image.new('RGB',(768,640),'#737777')
            for i,d in enumerate([0,2]):
                cell=get_frame(page,d,f)
                clip.paste(cell,(i*384,0),cell)
            clips.append(clip)
        clips[0].save(root/'reference/hd-walk-24.gif',save_all=True,append_images=clips[1:],duration=[30,30,40]*8,loop=0)
review.save(root/'reference/hd-native-preview.png')
