local out=app.params.out or 'sword/assets/character'
local s=Sprite{fromFile=out..'/swordsman.aseprite'}
local atlas=Image{fromFile=out..'/swordsman.png'}
assert(#s.frames==192 and #s.tags==24 and #s.layers==3)
for frame=1,192 do
 local merged=Image(64,80,ColorMode.RGB)
 for _,layer in ipairs(s.layers) do
  local cel=layer:cel(frame)
  assert(cel)
  merged:drawImage(cel.image,cel.position)
 end
 local ox=((frame-1)%8)*64
 local oy=math.floor((frame-1)/8)*80
 for y=0,79 do for x=0,63 do
  assert(merged:getPixel(x,y)==atlas:getPixel(ox+x,oy+y),'Source/export mismatch')
 end end
end
print('ASEPRITE_REOPEN_OK: 192 layered frames match exported atlas')
