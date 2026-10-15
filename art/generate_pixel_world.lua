-- Three full-size floating islands plus the sky/cloud sprites, painted in Aseprite.
print('PIXEL_WORLD_START')
local out=app.params.out or 'sword/assets/pixel/world'
app.fs.makeAllDirectories(out)
local pc=app.pixelColor
local function rgba(h,a) return pc.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),a or 255) end
local ink=rgba('1b3034')
local sets={
 {ground=rgba('42664b'),light=rgba('658261'),deep=rgba('345440'),soil=rgba('38443c'),rim=rgba('9aaa77'),tree=rgba('355d43'),treehi=rgba('6b9163'),stone=rgba('728276')},
 {ground=rgba('8b6549'),light=rgba('a77c55'),deep=rgba('77543e'),soil=rgba('544440'),rim=rgba('d4a675'),tree=rgba('9d6740'),treehi=rgba('c59458'),stone=rgba('b18a6b')},
 {ground=rgba('688a8d'),light=rgba('91b4ae'),deep=rgba('54747b'),soil=rgba('435862'),rim=rgba('c6ddc9'),tree=rgba('6aabb6'),treehi=rgba('b2d6d0'),stone=rgba('97bec5')}}
local function pixel(im,x,y,c)
 x=math.floor(x);y=math.floor(y)
 if x>=0 and x<im.width and y>=0 and y<im.height then im:putPixel(x,y,c) end
end
local function rect(im,x,y,w,h,c)
 for yy=math.floor(y),math.floor(y+h-1) do for xx=math.floor(x),math.floor(x+w-1) do pixel(im,xx,yy,c) end end
end
local function line(im,x0,y0,x1,y1,c)
 local n=math.max(math.abs(x1-x0),math.abs(y1-y0))
 if n<1 then pixel(im,x0,y0,c);return end
 for i=0,n do pixel(im,x0+(x1-x0)*i/n+0.5,y0+(y1-y0)*i/n+0.5,c) end
end
local function ellipse(im,cx,cy,rx,ry,c)
 for y=math.max(0,math.floor(cy-ry)),math.min(im.height-1,math.ceil(cy+ry)) do
  local span=rx*math.sqrt(math.max(0,1-((y-cy)/ry)^2))
  for x=math.max(0,math.ceil(cx-span)),math.min(im.width-1,math.floor(cx+span)) do pixel(im,x,y,c) end
 end
end
local function poly(im,p,c)
 local lo,hi=im.height,0
 for _,v in ipairs(p) do lo=math.min(lo,v[2]);hi=math.max(hi,v[2]) end
 for y=math.max(0,math.floor(lo)),math.min(im.height-1,math.ceil(hi)) do
  local xs={}
  for i=1,#p do local a,b=p[i],p[i%#p+1]
   if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end
  end
  table.sort(xs)
  for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do pixel(im,x,y,c) end end
 end
end
local function save(name,w,h,draw)
 local spr=Sprite(w,h,ColorMode.RGB)
 local labels={'Cliff silhouette','Land and paths','Details and landmarks'}
 local merged=Image(w,h,ColorMode.RGB)
 for layer=1,3 do
  local l=layer==1 and spr.layers[1] or spr:newLayer()
  l.name=labels[layer]
  local im=Image(w,h,ColorMode.RGB)
  draw(layer,im)
  spr:newCel(l,1,im,Point(0,0))
  merged:drawImage(im,Point(0,0))
 end
 spr:saveAs(out..'/'..name..'.aseprite')
 merged:saveAs(out..'/'..name..'.png')
 spr:close()
 print('PIXEL_WORLD_OK '..name..' '..w..'x'..h)
end
local function wp(x,y) return math.floor((x+1600)/2+0.5),math.floor((y+1300)/2+0.5) end
for region=0,2 do
 math.randomseed(1029+region*309)
 local c=sets[region+1]
 local rim={}
 for i=0,63 do
  local a=i/64*math.pi*2
  local r=(i%4==0 and 0.93 or (i%5==0 and 1.04 or 1))+math.random(-3,3)/100
  rim[#rim+1]={1080+math.floor(math.cos(a)*810*r),875+math.floor(math.sin(a)*615*r)}
 end
 local side={}
 for i=1,#rim do side[i]={rim[i][1],rim[i][2]+145} end
 local patches={}
 for i=1,1750 do
  local x,y=math.random(284,1870),math.random(280,1445)
  if ((x-1080)/780)^2+((y-875)/590)^2<0.92 then patches[#patches+1]={x,y,math.random(1,7),math.random(0,7)} end
 end
 local landmarks={{-350,150},{250,-300},{1390,350},{620,1140},{-150,930}}
 save('island_'..region,2048,1792,function(layer,im)
  if layer==1 then
   poly(im,side,c.soil)
   for i=1,900 do
    local x,y=math.random(300,1850),math.random(1130,1590)
    if ((x-1080)/795)^2+((y-1020)/625)^2<0.93 then rect(im,x,y,math.random(2,14),math.random(2,4),c.deep) end
   end
  elseif layer==2 then
   poly(im,rim,c.ground)
   for i=1,#rim do local a,b=rim[i],rim[i%#rim+1];line(im,a[1],a[2],b[1],b[2],c.rim) end
   for _,p in ipairs(patches) do
    local color=(p[4]<2 and c.light or c.deep)
    rect(im,p[1],p[2],p[3],1+p[3]%2,color)
   end
   for i=0,18 do
    local x,y=wp(110+i*54,485+math.sin(i*0.8)*24)
    rect(im,x-9,y-4,19,11,c.stone)
    line(im,x-7,y+4,x+8,y+4,c.deep)
   end
  else
   for _,p in ipairs(landmarks) do
    local x,y=wp(p[1],p[2])
    if region==2 then
     for j=0,3 do
      local cx=x+j*17
      poly(im,{{cx-9,y+18},{cx-8,y-4-j*2},{cx,y-53-j*7},{cx+13,y-3},{cx+9,y+17}},ink)
      poly(im,{{cx-6,y+13},{cx,y-48-j*7},{cx+10,y+12}},c.tree)
      line(im,cx,y-45-j*7,cx+8,y+9,c.treehi)
     end
    else
     rect(im,x-5,y-4,11,42,c.soil)
     ellipse(im,x,y-36,42,21,c.tree)
     ellipse(im,x-18,y-27,29,16,c.treehi)
     for k=0,13 do rect(im,x-37+(k*17)%70,y-54+(k*11)%26,2,1,c.rim) end
    end
   end
   local x,y=wp(560,70)
   rect(im,x-96,y-51,192,102,ink)
   rect(im,x-94,y-49,188,98,c.soil)
   rect(im,x-82,y-39,164,78,c.deep)
   for i=0,6 do line(im,x-80,y-38+i*12,x+80,y-38+i*12,c.ground) end
   for i=0,10 do line(im,x-81+i*16,y-39,x-81+i*16,y+38,c.ground) end
   ellipse(im,x,y,29,19,c.rim)
   ellipse(im,x,y,23,14,c.deep)
   line(im,x-14,y,x+14,y,c.rim)
   rect(im,x-3,y-4,6,9,c.stone)
  end
 end)
end
-- Four individually outlined cloud banks in one transparent sprite sheet.
local cloud=Sprite(256,128,ColorMode.RGB)
local banks=Image(1024,128,ColorMode.RGB)
local bottom=cloud.layers[1];bottom.name='Shadow shapes'
local upper=cloud:newLayer();upper.name='Lit cloud rims'
for f=0,3 do
 if f>0 then cloud:newEmptyFrame() end
 local merged=Image(256,128,ColorMode.RGB)
 for layer,l in ipairs({bottom,upper}) do
  local im=Image(256,128,ColorMode.RGB)
  for i=0,4 do
   local cx=30+i*49+(f%2)*5
   local cy=63+(i%2)*9
   local rx=37+i%3*8
   if layer==1 then ellipse(im,cx,cy+14,rx+7,20,rgba('6d90a0',175))
   else ellipse(im,cx,cy-2,rx,17,rgba('e1efdf',220));ellipse(im,cx-9,cy-8,rx-10,9,rgba('f3f5dd',205)) end
  end
  cloud:newCel(l,f+1,im,Point(0,0));merged:drawImage(im,Point(0,0))
 end
 banks:drawImage(merged,Point(f*256,0))
end
cloud:saveAs(out..'/cloud_bank.aseprite');banks:saveAs(out..'/cloud_bank.png');cloud:close()
save('cloud_veil',256,256,function(layer,im)
 local function hash(x,y)
  local v=math.sin((x%8)*127.1+(y%8)*311.7)*43758.5453
  return v-math.floor(v)
 end
 local function noise(x,y,step)
  local u,v=x/step,y/step
  local ix,iy=math.floor(u),math.floor(v)
  local fx,fy=u-ix,v-iy
  fx=fx*fx*(3-2*fx);fy=fy*fy*(3-2*fy)
  local a=hash(ix,iy)*(1-fx)+hash(ix+1,iy)*fx
  local b=hash(ix,iy+1)*(1-fx)+hash(ix+1,iy+1)*fx
  return a*(1-fy)+b*fy
 end
 if layer==1 then
  for y=0,255,8 do for x=0,255,8 do
   local n=noise(x,y,64)*0.65+noise(x,y,32)*0.25+noise(x,y,16)*0.1
   if n>0.28 then rect(im,x,y,8,8,rgba('aacdd2',math.floor(90+n*165))) end
  end end
 elseif layer==2 then
  for y=0,255,8 do for x=0,255,8 do
   local n=noise(x+41,y+17,64)*0.7+noise(x,y,32)*0.3
   if n>0.57 then rect(im,x,y,8,8,rgba('e1eddf',math.floor(n*110))) end
  end end
 else
  for y=0,255,16 do for x=0,255,16 do
   if noise(x+17,y+91,32)>0.68 then rect(im,x,y,4,4,rgba('f3f5dd',45)) end
  end end
 end
end)
