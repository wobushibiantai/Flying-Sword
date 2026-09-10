-- Retain generated pixels at 1:1. Assemble RGBA pages and editable Aseprite files.
-- Usage: aseprite --batch --script-param out=sword/assets/character/hd --script sword/art/build_hd_character.lua
local out=app.params.out or 'sword/assets/character/hd'
local FW,FH=384,640
local COUNT,COLUMNS=24,16
local rgba=app.pixelColor
local dirs={'e','se','s','sw','w','nw','n','ne'}
local function extract(path)
 local src=Image{fromFile=path}
 local w,h=src.width,src.height
 local colors,labels={},{}
 for y=0,h-1 do for x=0,w-1 do
  local c=src:getPixel(x,y)
  local r,g,b=rgba.rgbaR(c),rgba.rgbaG(c),rgba.rgbaB(c)
  -- Saturated magenta occurs only in the chroma background / edge spill.
  if not (r>g+18 and b>g+18) then colors[y*w+x+1]=c end
 end end
 local components={}
 for start=1,w*h do if colors[start] and not labels[start] then
  local id=#components+1
  local q={start};labels[start]=id
  local n=1
  local c={pixels=q,x0=w,y0=h,x1=0,y1=0}
  while n<=#q do
   local p=q[n];n=n+1
   local x=(p-1)%w;local y=math.floor((p-1)/w)
   c.x0=math.min(c.x0,x);c.x1=math.max(c.x1,x)
   c.y0=math.min(c.y0,y);c.y1=math.max(c.y1,y)
   for _,v in ipairs({x>0 and p-1 or 0,x<w-1 and p+1 or 0,y>0 and p-w or 0,y<h-1 and p+w or 0}) do
    if colors[v] and not labels[v] then labels[v]=id;q[#q+1]=v end
   end
  end
  components[id]=c
 end end
 local mains={}
 for _,c in ipairs(components) do if #c.pixels>7000 then
  local d=math.min(3,math.floor((c.x0+c.x1)/2/(w/4)))+4*math.min(1,math.floor((c.y0+c.y1)/2/(h/2)))
  assert(not mains[d+1],'Touching sprites / multiple main components')
  mains[d+1]=c
 end end
 assert(#mains==8,'Expected eight isolated characters')
 for _,c in ipairs(components) do if #c.pixels<=7000 and #c.pixels>2 then
  local best,dist=1,math.huge
  local cx,cy=(c.x0+c.x1)/2,(c.y0+c.y1)/2
  for d,m in ipairs(mains) do
   local dx=math.max(m.x0-cx,0,cx-m.x1)
   local dy=math.max(m.y0-cy,0,cy-m.y1)
   local distance=dx*dx+dy*dy
   if distance<dist then dist=distance;best=d end
  end
  if dist<900 then for _,p in ipairs(c.pixels) do table.insert(mains[best].pixels,p) end end
 end end
 local frames={}
 for d,c in ipairs(mains) do
  -- Align by the head, not by the extended casting arm or flowing tail.
  local ys=c.y0+math.floor((c.y1-c.y0)*0.12)
  local runs={};local first=nil
  for x=math.floor((d-1)%4*w/4),math.floor(((d-1)%4+1)*w/4)-1 do
   if colors[ys*w+x+1] then first=first or x
   elseif first then runs[#runs+1]={first,x-1};first=nil end
  end
  table.sort(runs,function(a,b) return a[2]-a[1]>b[2]-b[1] end)
  local center=runs[1] and (runs[1][1]+runs[1][2])/2 or (c.x0+c.x1)/2
  local dx=math.floor(FW/2-center+0.5)
  local dy=30-c.y0
  local image=Image(FW,FH,ColorMode.RGB)
  local clipped=0
  for _,p in ipairs(c.pixels) do
   local x=(p-1)%w+dx;local y=math.floor((p-1)/w)+dy
   if x>=3 and x<FW-3 and y>=3 and y<FH-3 then image:putPixel(x,y,colors[p]) else clipped=clipped+1 end
  end
  assert(clipped==0,'Character clipped during registration: '..d..' pixels='..clipped)
  frames[d]=image
 end
 return frames
end
local idle=extract(out..'/source/idle.png')
local sources={idle,extract(out..'/source/walk.png'),extract(out..'/source/cast.png'),extract(out..'/source/fly.png')}
local names={'idle','walk','cast','fly','hover'}
local function smooth(a,b,v)
 local k=math.max(0,math.min(1,(v-a)/(b-a)))
 return k*k*(3-2*k)
end
-- Continuous deformation of each action's own key pose. Inserting an unrelated
-- idle drawing in the middle of the walk cycle caused large silhouette jumps.
-- No cross-fades: sample a single source pixel so fine texture stays crisp.
for state=1,5 do
 local spr=Sprite(FW,FH,ColorMode.RGB)
 spr.layers[1].name='Detailed pixels'
 local page=Image(FW*COLUMNS,FH*math.ceil(COUNT*8/COLUMNS),ColorMode.RGB)
 local srcs=sources[math.min(state,4)]
 for d=1,8 do for f=0,COUNT-1 do
  local frame=(d-1)*COUNT+f+1
  if frame>1 then spr:newEmptyFrame() end
  spr.frames[frame].duration=state==1 and 0.06 or 1/30
  local src=srcs[d]
  local img=Image(FW,FH,ColorMode.RGB)
  local t=f/COUNT*math.pi*2
  local stride=math.sin(t)
  local side=math.abs(math.cos((d-1)*math.pi/4))
  for y=0,FH-1 do
   local lower=smooth(290,585,y)
   local legs=smooth(440,585,y)
   local upper=1-smooth(380,590,y)
   local hair=smooth(65,160,y)*(1-smooth(280,410,y))
   local sleeves=smooth(155,240,y)*(1-smooth(360,440,y))
   local wave=math.sin(t-lower*1.8)
   local cloth=wave*lower*(state==4 and 9 or (state==2 and 7 or 5))
   local bob=(state==2 and (1-math.cos(t*2))*2.5 or math.sin(t)*1.5)*upper
   for x=0,FW-1 do
    local lateral=math.max(-1,math.min(1,(x-FW/2)/45))
    local outer=smooth(38,112,math.abs(x-FW/2))
    local shift=cloth
    -- A travelling side view pins the upwind front; rear hair/hem trail behind.
    if state==4 and (d==1 or d==5) then
     shift=shift*(1-smooth(-22,35,(x-FW/2)*(d==1 and 1 or -1)))
    end
    shift=shift+math.sin(t-hair*1.2)*hair*outer*(state==4 and 4 or 2.5)
    local lift=0
    if state==2 then
     shift=shift+stride*legs*lateral*(8+8*side)
     shift=shift-stride*sleeves*lateral*outer*5
     lift=math.max(0,stride*lateral)*legs*9
    end
    local sx=math.floor(x-shift+0.5)
    local sy=math.floor(y-bob+lift+0.5)
    if sx>=0 and sx<FW and sy>=0 and sy<FH then
     local c=src:getPixel(sx,sy)
     if rgba.rgbaA(c)>0 then img:putPixel(x,y,c) end
    end
   end
  end
  spr:newCel(spr.layers[1],frame,img,Point(0,0))
  page:drawImage(img,Point(((frame-1)%COLUMNS)*FW,math.floor((frame-1)/COLUMNS)*FH))
 end
  local tag=spr:newTag((d-1)*COUNT+1,d*COUNT);tag.name=names[state]..'_'..dirs[d]
 end
 spr:saveAs(out..'/'..names[state]..'.aseprite')
 page:saveAs(out..'/'..names[state]..'.png')
 spr:close()
 print('HD_PAGE_OK '..names[state]..' frame='..FW..'x'..FH..' frames='..COUNT*8)
end
