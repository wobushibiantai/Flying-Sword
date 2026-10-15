-- Hand-clustered 96x128 pixel swordsman. Eight directions, five actions,
-- 24 individually rasterized phases per direction. Native Aseprite layers.
print('PIXEL_CHARACTER_START')
local out=app.params.out or 'sword/assets/character/pixel'
app.fs.makeAllDirectories(out)
local W,H,N,COLS=96,128,24,16
local pc=app.pixelColor
local function col(h) return pc.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local c={ink=col('161e22'),hair=col('222629'),hair2=col('34383a'),shine=col('5a5952'),robe=col('303537'),robe2=col('424746'),fold=col('656760'),gold=col('96835b'),ivory=col('eee7d8'),shade=col('c8c1b3'),deep=col('a5aaa2'),sash=col('68878d'),skin=col('dbb99d'),skin2=col('b58c76'),shoe=col('22282a')}
local img,mirror
local function px(x,y,color)
 x=math.floor(x+0.5);y=math.floor(y+0.5)
 if mirror then x=W-1-x end
 if x>=0 and x<W and y>=0 and y<H then img:putPixel(x,y,c[color]) end
end
local function rect(x,y,w,h,color)
 for yy=math.floor(y+0.5),math.floor(y+h-0.5) do for xx=math.floor(x+0.5),math.floor(x+w-0.5) do px(xx,yy,color) end end
end
local function line(x0,y0,x1,y1,color)
 local n=math.max(math.abs(x1-x0),math.abs(y1-y0))
 for i=0,n do px(x0+(x1-x0)*i/n,y0+(y1-y0)*i/n,color) end
end
local function poly(points,color)
 for y=0,H-1 do
  local xs={}
  for i=1,#points do local a,b=points[i],points[i%#points+1]
   if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end
  end
  table.sort(xs)
  for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do px(x,y,color) end end
 end
end
local dirs={'e','se','s','sw','w','nw','n','ne'}
local names={'idle','walk','cast','fly','hover'}
local function paint(layer,state,d,f)
 local t=f/N*math.pi*2
 local walk=state==2
 local fly=state==4 or state==5
 local side=d==1 or d==5
 local back=d>=6
 local slant=d==2 or d==4 or d==6 or d==8
 local left=d==4 or d==5 or d==6
 mirror=left
 local facing=d==5 and 1 or (side and 1 or 0)
 local stride=walk and math.sin(t) or 0
 local bob=walk and -math.floor(math.abs(stride)*2+0.5) or 0
 local wind=math.floor(math.sin(t-0.35)*(fly and 3.2 or 2.2)+0.5)
 local footshift=math.floor(stride*5+0.5)
 local rear=side and state==4 and 25+wind or 24+wind
 local front=side and state==4 and 64 or 72+wind
 if layer==1 then
  if not fly then
   rect(35-footshift,116+bob,12,5,'shoe');rect(52+footshift,116-bob,13,5,'shoe')
   rect(38-footshift,118+bob,8,1,'gold');rect(54+footshift,118-bob,9,1,'gold')
  end
  poly({{37,43+bob},{59,42+bob},{64,69},{front,109},{front-3,117},{rear+5,118},{rear,111},{34,72}},'ink')
  poly({{39,45+bob},{57,44+bob},{61,71},{front-3,108},{front-6,114},{rear+8,115},{rear+3,109},{37,72}},'robe')
  if back then
   poly({{41,65},{57,64},{front-5,111},{53,116},{rear+8,113}},'robe2')
   line(48,69,47+wind,111,'fold');line(57,71,59+wind,109,'fold')
  else
   poly({{43,69},{55,66},{63,113},{39+wind,114}},'ivory')
   poly({{44,72},{47,70},{43+wind,111},{40+wind,112}},'shade')
   poly({{52,76},{54,74},{60,112},{56,112}},'shade')
   poly({{37,73},{42,71},{34+wind,107},{rear+6,114}},'robe2')
   poly({{59,74},{63,77},{front-4,108},{front-9,113}},'robe2')
   for k=0,4 do line(42+k*4,92+k%2,40+wind+k*5,111,'deep') end
  end
  if fly then rect(38,114,19,3,'ink') end
 elseif layer==2 then
  poly({{37,41+bob},{58,41+bob},{66,64},{62,78},{34,78},{31,60}},'robe')
  if not back then
   poly({{40,43+bob},{48,48},{57,42+bob},{59,55},{47,69},{39,59}},'ivory')
   poly({{41,46},{47,53},{50,50},{41,58}},'shade')
   poly({{56,44},{60,51},{49,65},{46,66}},'shade')
   rect(38,68,23,5,'sash');rect(43,69,17,1,'deep');rect(47,71,5,2,'gold')
   if side then
    poly({{55,45},{63,47},{57,63},{51,66}},left and 'shade' or 'ivory')
   end
  else
   line(42,46,40,69,'fold');line(56,45,61,69,'fold')
   rect(42,70,16,3,'sash')
  end
  -- Distinct near and far sleeves; the casting arm is raised in all 8 views.
  poly({{36,46+bob},{40,50},{36+wind,76},{24+wind,73},{29,54}},'ink')
  poly({{36,48+bob},{39,51},{35+wind,73},{27+wind,71},{31,54}},'robe2')
  poly({{27+wind,69},{35+wind,71},{35+wind,74},{26+wind,73}},'ivory')
  rect(30+wind,73,4,4,'skin')
  local casting=state==3
  if casting then
   local handx=side and 79 or (back and 71 or (slant and 73 or 65))
   local handy=(back and 31 or (side and 43 or 48))+math.floor(math.sin(t)*2+0.5)
   poly({{58,47+bob},{63,48+bob},{handx-8,handy-3},{handx,handy+4},{handx-9,handy+8},{55,62}},'ink')
   poly({{59,49+bob},{61,51},{handx-8,handy},{handx-2,handy+3},{handx-10,handy+6},{56,60}},'robe2')
   rect(handx-3,handy-1,5,4,'ivory');rect(handx+1,handy-3,4,5,'skin')
   line(handx+4,handy-2,handx+8,handy-4,'skin')
  elseif fly then
   poly({{58,47+bob},{63,50},{67,70},{62,78},{57,73},{57,62}},'ink')
   poly({{59,50},{61,52},{64,70},{61,75},{59,69}},'robe2')
   if back then rect(45,75,12,3,'skin') else rect(59,74,3,3,'skin') end
  else
   local sway=math.floor(stride*3)
   poly({{58,47+bob},{64,53},{70-sway,74},{66-sway,81},{56,77},{55,61}},'ink')
   poly({{59,49+bob},{62,54},{67-sway,74},{65-sway,78},{57,75}},'robe2')
   poly({{63-sway,77},{68-sway,77},{66-sway,81},{61-sway,79}},'ivory')
   rect(64-sway,81,4,5,'skin')
  end
 elseif layer==3 then
  local head=side and 49 or 47
  local top=9+bob
  -- Hair silhouette, segmented strands and an adult-length jaw across views.
  poly({{35,22+bob},{39,12+bob},{48,8+bob},{59,12+bob},{65,24+bob},{62,42},{34,42}},'ink')
  poly({{38,20+bob},{42,12+bob},{49,10+bob},{59,14+bob},{63,25+bob},{60,39},{36,39}},'hair')
  -- Back hair falls on both sides of the torso; the crossed ivory collar stays visible.
  poly({{35,28},{40,28},{40,49},{37+wind,71},{32+wind,84},{27+wind,86},{32,49}},'ink')
  poly({{36,29},{39,29},{38,51},{35+wind,71},{31+wind,81},{30+wind,81},{34,48}},'hair')
  poly({{58,27},{64,28},{65,51},{70+wind,82},{65+wind,87},{59,71},{57,47}},'ink')
  poly({{59,29},{63,29},{62,50},{67+wind,79},{65+wind,82},{60,67}},'hair')
  if not back then
   if side then
    poly({{46,20+bob},{55,20+bob},{58,24+bob},{57,34+bob},{54,39+bob},{48,39+bob},{45,35+bob}},'skin2')
    poly({{48,21+bob},{55,21+bob},{57,25+bob},{56,33+bob},{53,38+bob},{49,37+bob},{47,33+bob}},'skin')
    rect(54,28+bob,2,1,'ink')
   else
    poly({{40,20+bob},{55,20+bob},{58,28+bob},{56,36+bob},{51,40+bob},{44,39+bob},{39,32+bob}},'skin2')
    poly({{42,21+bob},{54,21+bob},{56,28+bob},{54,36+bob},{50,39+bob},{45,38+bob},{41,32+bob}},'skin')
    rect(43,29+bob,3,1,'ink');rect(52,29+bob,3,1,'ink')
   end
  end
  poly({{39,15+bob},{47,9+bob},{54,12+bob},{48,21+bob},{42,23+bob},{37,45}},'hair')
  poly({{54,11+bob},{61,15+bob},{63,38},{59+wind,70},{57+wind,74},{58,34},{55,21+bob}},'hair')
  line(39,17+bob,44,12+bob,'shine');line(42,20+bob,37+wind,64,'hair2')
  line(56,17+bob,61+wind,68,'hair2');line(61,22+bob,67+wind,78,'shine')
  line(35,30+bob,31+wind,74,'hair2');line(61,31+bob,67+wind,71,'hair2')
  -- One drifting glint runs along a strand for 24 distinct native pixel frames.
  px(40+(f%8),14+math.floor(f/8)+bob,'shine')
 end
end
for state=1,5 do
 local name=names[state]
 local spr=Sprite(W,H,ColorMode.RGB)
 local layers={spr.layers[1],spr:newLayer(),spr:newLayer()}
 for i,label in ipairs({'Feet and robe','Sleeves and collar','Hair and face'}) do layers[i].name=label end
 local page=Image(W*COLS,H*(8*N/COLS),ColorMode.RGB)
 for d=1,8 do for f=0,N-1 do
  local frame=(d-1)*N+f+1
  if frame>1 then spr:newEmptyFrame() end
  spr.frames[frame].duration=state==1 and 0.06 or 1/30
  local merged=Image(W,H,ColorMode.RGB)
  for layer=1,3 do
   img=Image(W,H,ColorMode.RGB)
   paint(layer,state,d,f)
   spr:newCel(layers[layer],frame,img,Point(0,0))
   merged:drawImage(img,Point(0,0))
  end
  page:drawImage(merged,Point(((frame-1)%COLS)*W,math.floor((frame-1)/COLS)*H))
 end
 local tag=spr:newTag((d-1)*N+1,d*N);tag.name=name..'_'..dirs[d]
 end
 spr:saveAs(out..'/'..name..'.aseprite')
 page:saveAs(out..'/'..name..'.png')
 spr:close()
 print('PIXEL_CHARACTER_OK '..name..' 96x128 frames=192')
end
