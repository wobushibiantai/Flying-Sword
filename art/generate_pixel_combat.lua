-- Native Aseprite pixel drawing. No rasterized SVG, filters or external images.
-- Run from workspace parent with --batch --script art/generate_pixel_combat.lua.
local out=app.params.out or 'sword/assets/pixel/combat'
app.fs.makeAllDirectories(out)
local pc=app.pixelColor
local function color(h,a)
 return pc.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),a or 255)
end
local C={ink=color('142527'),dark=color('253f3c'),jade=color('397868'),mid=color('78a58a'),light=color('d9e8b2'),white=color('f0f3d6'),gold=color('b89c62'),wood=color('705741'),shadow=color('10232a',95)}
local img
local function px(x,y,c)
 x=math.floor(x);y=math.floor(y)
 if x>=0 and y>=0 and x<img.width and y<img.height then img:putPixel(x,y,c) end
end
local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(xx,yy,c) end end end
local function line(x0,y0,x1,y1,c)
 local n=math.max(math.abs(x1-x0),math.abs(y1-y0))
 if n==0 then px(x0,y0,c);return end
 for i=0,n do px(math.floor(x0+(x1-x0)*i/n+0.5),math.floor(y0+(y1-y0)*i/n+0.5),c) end
end
local function poly(p,c)
 for y=0,img.height-1 do
  local xs={}
  for i=1,#p do
   local a,b=p[i],p[i%#p+1]
   if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end
  end
  table.sort(xs)
  for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do px(x,y,c) end end
 end
end
local function ellipse(cx,cy,rx,ry,c,outline)
 for y=math.floor(cy-ry),math.ceil(cy+ry) do for x=math.floor(cx-rx),math.ceil(cx+rx) do
  local d=((x-cx)/rx)^2+((y-cy)/ry)^2
  local inner=rx>1 and ry>1 and ((x-cx)/(rx-1))^2+((y-cy)/(ry-1))^2 or 2
  if d<=1 and (not outline or inner>1) then px(x,y,c) end
 end end
end
local function asset(name,w,h,count,render)
 local spr=Sprite(w,h,ColorMode.RGB)
 local layers={spr.layers[1],spr:newLayer(),spr:newLayer()}
 for i,label in ipairs({'Silhouette','Materials','Light and details'}) do layers[i].name=label end
 local sheet=Image(w*count,h,ColorMode.RGB)
 for f=0,count-1 do
  if f>0 then spr:newEmptyFrame() end
  spr.frames[f+1].duration=0.08
  local merged=Image(w,h,ColorMode.RGB)
  for layer=1,3 do
   img=Image(w,h,ColorMode.RGB)
   render(f,layer)
   spr:newCel(layers[layer],f+1,img,Point(0,0))
   merged:drawImage(img,Point(0,0))
  end
  sheet:drawImage(merged,Point(f*w,0))
 end
 local tag=spr:newTag(1,count);tag.name=name
 spr:saveAs(out..'/'..name..'.aseprite');sheet:saveAs(out..'/'..name..'.png');spr:close()
 print('PIXEL_COMBAT_OK '..name..' '..w..'x'..h..' frames='..count)
end
asset('blade',48,20,1,function(f,l)
 if l==1 then
  poly({{13,6},{38,6},{47,10},{38,14},{13,14}},C.ink)
  rect(3,8,10,5,C.ink);rect(11,3,3,14,C.ink);rect(1,7,4,6,C.ink)
 elseif l==2 then
  poly({{14,7},{38,7},{45,10},{38,13},{14,13}},C.jade)
  rect(4,9,7,3,C.dark);rect(12,4,1,12,C.gold);rect(2,8,2,4,C.gold)
 else
  line(14,8,38,8,C.mid);line(14,10,43,10,C.light);line(14,12,37,12,C.mid)
  for x=5,10,3 do line(x,9,x+1,11,C.mid) end
  px(13,7,C.white);px(13,13,C.white)
 end
end)
asset('mount',96,20,1,function(f,l)
 if l==1 then
  poly({{18,6},{79,6},{95,10},{79,14},{18,14}},C.ink);rect(4,8,15,5,C.ink);rect(16,3,4,14,C.ink)
 elseif l==2 then
  poly({{20,7},{79,7},{92,10},{79,13},{20,13}},C.jade);rect(6,9,10,3,C.dark);rect(17,4,2,12,C.gold)
 else
  line(21,8,79,8,C.mid);line(20,10,90,10,C.light);line(21,12,79,12,C.mid)
  for x=7,14,3 do line(x,9,x+1,11,C.gold) end
 end
end)
asset('target',32,40,3,function(f,l)
 local lit=f==1
 if l==1 then
  ellipse(16,37,14,2,C.shadow);rect(14,23,5,14,C.ink);rect(9,36,15,2,C.ink)
  ellipse(16,15,14,14,C.ink)
 elseif l==2 then
  rect(15,23,3,13,C.wood);ellipse(16,15,12,12,f==2 and C.dark or C.wood)
  ellipse(16,15,10,10,C.gold,true);ellipse(16,15,7,7,C.dark)
  for y=7,23,4 do line(7,y,25,y,C.dark) end
 else
  local c=lit and C.white or C.light
  ellipse(16,15,11,11,f==2 and C.jade or C.gold,true)
  line(16,10,21,15,c);line(21,15,16,20,c);line(16,20,11,15,c);line(11,15,16,10,c)
  rect(15,14,3,3,C.jade);px(16,15,c)
  for _,p in ipairs({{16,1},{29,15},{16,28},{2,15}}) do rect(p[1],p[2],2,2,C.gold) end
  if f==2 then line(7,4,22,26,C.ink);line(21,26,16,28,C.ink) end
 end
end)
asset('shadow',32,12,1,function(f,l) if l==1 then ellipse(16,6,15,5,C.shadow);ellipse(16,6,11,3,color('0d2025',45)) end end)
asset('focus',32,32,8,function(f,l)
 if l==1 then ellipse(16,16,12,9,color('7ba58b',100),true)
 elseif l==2 then
  for i=0,3 do
   local a=i*math.pi/2+f*math.pi/16
   local x,y=16+math.cos(a)*13,16+math.sin(a)*10
   rect(math.floor(x),math.floor(y),2,2,C.gold)
  end
 else
  rect(15,14,3,5,C.light);rect(14,15,5,3,C.light);px(16,16,C.white)
 end
end)
asset('placement',32,32,1,function(f,l)
 if l==2 then
  for i=0,3 do local a=i*math.pi/2;local x,y=16+math.cos(a)*13,16+math.sin(a)*13
   line(x-3,y,x+3,y,C.light);line(x,y-3,x,y+3,C.light)
  end
  ellipse(16,16,11,11,C.gold,true)
 end
end)
asset('impact',24,24,6,function(f,l)
 local r=3+f*1.6
 if l==1 then ellipse(12,12,r+2,r+2,color('99b59a',110),true)
 elseif l==2 then
  for i=0,7 do local a=i*math.pi/4+0.1*f
   line(12+math.cos(a)*r,12+math.sin(a)*r,12+math.cos(a)*(r+2),12+math.sin(a)*(r+2),C.light)
  end
 elseif f<3 then rect(11,9,2,6,C.white);rect(9,11,6,2,C.white) end
end)
asset('spark',8,8,1,function(f,l)
 if l==1 then line(1,4,6,4,C.jade)
 elseif l==2 then line(3,3,6,3,C.light);line(4,2,4,5,C.gold)
 else rect(4,3,2,2,C.white) end
end)
asset('trail',16,8,1,function(f,l)
 if l==1 then rect(0,2,16,4,color('588d78',65))
 elseif l==2 then rect(0,3,16,2,color('a3cd98',170))
 else rect(0,3,16,1,C.light) end
end)
asset('aim_line',8,4,1,function(f,l) if l==2 then rect(0,1,5,1,color('b2d3a1',180));rect(0,2,3,1,color('527c68',110)) end end)
asset('aim_fill',8,8,1,function(f,l) if l==1 then px(1,1,color('b6d6aa',25));px(5,5,color('b6d6aa',25)) end end)
asset('hp_bg',24,4,1,function(f,l) if l==1 then rect(0,0,24,4,C.ink) elseif l==2 then rect(1,1,22,2,C.dark) else px(0,0,C.gold);px(23,3,C.gold) end end)
asset('hp_fill',22,2,1,function(f,l) if l==2 then rect(0,0,22,1,C.light);rect(0,1,22,1,C.jade) end end)
asset('arena',128,128,1,function(f,l)
 if l==1 then rect(0,0,128,128,color('182d2b'))
 elseif l==2 then
  for i=0,90 do local x=(i*47+13)%126;local y=(i*71+9)%126
   rect(x,y,2+i%3,1,color(i%3==0 and '213b33' or '1c332e'))
  end
 else
  for i=0,8 do local x=(i*31+11)%120;local y=(i*43+19)%120
   line(x,y,x+1,y-3,color('37513d'));line(x+1,y,x+4,y-2,color('2b4437'))
  end
 end
end)
asset('icon',64,64,1,function(f,l)
 if l==1 then rect(2,2,60,60,C.ink);rect(4,4,56,56,C.dark)
 elseif l==2 then
  poly({{14,49},{18,46},{44,12},{50,7},{49,16},{23,49},{19,53}},C.jade)
  line(17,46,46,11,C.mid);line(20,49,48,13,C.light)
  poly({{11,45},{13,42},{25,52},{22,55}},C.gold);line(12,55,17,49,C.gold)
 else
  for _,p in ipairs({{7,7},{55,7},{7,55},{55,55}}) do rect(p[1],p[2],2,2,C.gold) end
  px(47,11,C.white);line(30,46,50,24,C.jade);line(11,36,29,13,C.jade)
 end
end)
