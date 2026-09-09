-- Run with Aseprite --batch --script-param out=... --script this-file.lua
-- Hand-authored pixel clusters. Reference: supplied black/ivory swordsman sheet.
local out=app.params.out or 'sword/assets/character'
local W,H=64,80
local custom_renderer=app.params.renderer and dofile(app.params.renderer) or nil
local spr=Sprite(W,H,ColorMode.RGB)
local layers={spr.layers[1],spr:newLayer(),spr:newLayer()}
layers[1].name='Robe and shoes'; layers[2].name='Sleeves and collar'; layers[3].name='Hair and face'
local palette={ink='191e20',dark='252a2b',robe='34393a',fold='464a49',edge='777971',white='ece8dc',shade='c5c4bb',deep='9baba9',sash='6d8589',skin='e2c7ac',skinshade='b79781',hair='202526',shine='4c4d46'}
local C={}
for k,h in pairs(palette) do C[k]=app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local img,mirror,bob,profile
local function px(x,y,c)
 x=math.floor(32+(x-32)*profile+0.5); y=math.floor(y+bob+0.5)
 if mirror then x=63-x end
 if x>=0 and x<W and y>=0 and y<H then img:putPixel(x,y,C[c]) end
end
local function poly(p,c)
 for y=0,H-1 do
  local xs={}
  for i=1,#p do
   local a,b=p[i],p[i%#p+1]
   if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end
  end
  table.sort(xs)
  for j=1,#xs-1,2 do for x=math.ceil(xs[j]),math.floor(xs[j+1]) do px(x,y,c) end end
 end
end
local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(xx,yy,c) end end end
-- Side view has its own anatomy. Coordinates face east; left/right garments
-- have different lapel, lining and sash constructions before orientation.
local function side_layer(layer,st,d,wind,stride)
 local left=d==4
 local sway=st==1 and math.floor(stride*2+0.5) or 0
 if layer==1 then
  if st==4 then
   -- Hovering: relaxed fabric sways around the legs, with a closed ankle hem.
   poly({{28,24},{36,24},{39,43},{43+wind,72},{39+wind,75},{23+wind,74},{26,47}},'ink')
   poly({{29,26},{35,26},{37,43},{41+wind,72},{38+wind,74},{25+wind,73},{28,46}},'robe')
   poly({{34,43},{37,44},{40+wind,73},{34+wind,74}},left and 'white' or 'shade')
   poly({{28,46},{32,44},{32+wind,73},{25+wind,72}},'dark')
   poly({{28,52},{30,48},{28+wind,69},{26+wind,71}},'fold')
   return
  end
  if st<3 then
  rect(28-sway,70,8,3,'ink');rect(28-sway,73,8,1,'shade')
  rect(34+sway,71,9,3,'ink');rect(34+sway,74,9,1,'shade')
  end
  if st==3 then
   -- Wind comes from the facing direction (right in these local coordinates).
   -- Front edge and lining cling to the legs; only the rear panels flap.
   local tail=15+wind
   poly({{28,24},{36,24},{38,43},{39,74},{26,75},{24,70},{tail,68},{tail-2,61},{24,48}},'ink')
   poly({{29,26},{35,26},{36,43},{37,73},{27,74},{26,68},{tail+2,66},{tail+1,61},{26,47}},'robe')
   poly({{33,43},{36,43},{37,73},{33,74}},left and 'white' or 'shade')
   poly({{31,44},{33,45},{32,73},{27,73},{26,68},{tail+3,65},{25,53}},'dark')
   poly({{27,49},{29,47},{25,58},{tail+2,63},{tail+4,60}},'fold')
   poly({{24,55},{27,52},{tail+5,66},{tail+2,65}},'edge')
   return
  end
  poly({{28,24},{36,24},{39,42},{43+wind,69},{39,72},{22+wind,71},{26,47}},'ink')
  poly({{29,26},{35,26},{37,42},{41+wind,69},{24+wind,69},{28,45}},'robe')
  -- The overlapping front panel is broad on the left, tucked on the right.
  if left then
   poly({{33,42},{37,42},{41+wind,70},{33+wind,70}},'white')
   poly({{33,46},{35,45},{36+wind,69},{33+wind,69}},'shade')
   poly({{29,45},{32,44},{31+wind,67},{26+wind,69}},'fold')
  else
   poly({{36,43},{38,45},{41+wind,70},{37+wind,70}},'shade')
   poly({{28,44},{34,42},{34+wind,69},{24+wind,69}},'dark')
   poly({{27,54},{29,48},{28+wind,66},{26+wind,67}},'fold')
  end
 elseif layer==2 then
  poly({{28,24},{34,22},{38,26},{40,36},{37,43},{27,42},{26,29}},'ink')
  poly({{29,25},{34,24},{37,27},{38,36},{36,42},{28,40}},'robe')
  poly({{34,23},{37,25},{38,30},{34,35},{32,29}},'white')
  if left then
   poly({{36,26},{38,30},{33,39},{31,36}},'shade')
  else
   poly({{33,27},{35,29},{32,35},{29,32}},'edge')
  end
  rect(28,40,10,3,'sash')
  if st>=3 then
   poly({{29,41},{27,44},{20+wind,49},{22+wind,46}},'deep')
  elseif left then
   poly({{36,41},{39,43},{39+wind,52},{37+wind,50}},'deep')
  else rect(29,40,3,2,'shade') end
  if st>=3 then
   -- Upper arm sweeps back; bent elbow, cuff and hands behind the waist.
   poly({{29,26},{32,28},{30,35},{26,42},{22,42},{22,36},{26,30}},'ink')
   poly({{28,28},{30,29},{27,35},{24,39},{24,34}},'fold')
   poly({{23,38},{26,39},{26,44},{23,44}},'white')
   rect(23,43,4,3,'skinshade');rect(24,43,3,2,'skin')
  elseif st==2 then
   poly({{30,26},{34,28},{40,30},{48,26},{50,30},{46,40},{39,40},{32,35}},'ink')
   poly({{31,28},{34,30},{40,32},{47,28},{47,33},{44,38},{39,37}},'robe')
   poly({{46,28},{49,27},{50,30},{47,34}},'white')
   rect(50,26,6,3,'skin');rect(54,25,3,1,'skin')
  else
   -- Near arm hangs at the shoulder line, separated from the torso by a seam.
   poly({{28,27},{32,28},{34,36},{34+sway,46},{28+sway,48},{25,40},{25,31}},'ink')
   poly({{28,29},{30,29},{32,36},{32+sway,44},{28+sway,45},{27,38}},'robe')
   poly({{27,31},{29,32},{30,42},{28+sway,43},{27,39}},'fold')
   rect(28+sway,44,5,3,left and 'white' or 'shade')
   rect(29+sway,47,3,5,'skinshade');rect(30+sway,47,2,4,'skin')
   px(31+sway,52,'skinshade')
   -- Far hand peeks beyond the front robe; not a second frontal sleeve.
   rect(38,39,2,4,'shade');rect(39,43,2,3,'skinshade')
  end
 else
  -- All front-facing views share forehead y=13 and chin y=25.
  -- A quiet, continuous profile: no eye, mouth or separate lip pixels.
  poly({{26,12},{28,9},{32,8},{36,9},{38,12},{38,17},{35,23},{33,26},{25,25},{24,17}},'hair')
  poly({{31,13},{36,13},{36,21},{35,25},{32,23}},'skinshade')
  poly({{32,13},{35,13},{35,21},{34,24},{33,23}},'skin')
  poly({{26,13},{29,10},{33,10},{36,12},{34,14},{31,15},{29,24},{28,30},{25+wind,40},{23+wind,43},{25,29},{24,20}},'hair')
  poly({{26,16},{28,12},{31,11},{29,16},{27,29},{25+wind,38}},'shine')
  poly({{29,21},{31,22},{31,31},{33+wind,38},{30+wind,35},{28,29}},'dark')
  -- One temple lock leaves the cheek and neck readable.
  poly({{31,13},{33,12},{32,16},{32,24},{31,27},{30,21}},'hair')
end
end
local function cast_arm(d,t)
 local lift=math.floor(math.sin(t)*1.2+0.5)
 if d==2 then
  -- Toward camera: foreshortened forearm and hand in front of the chest.
  poly({{38,25},{42,28},{44,39},{40,45},{33,40},{34,34}},'ink')
  poly({{38,28},{40,30},{42,38},{39,42},{35,38},{36,34}},'robe')
  poly({{34,33},{38,34},{38,38},{34,37}},'white')
  rect(33,35+lift,4,4,'skin');rect(34,39+lift,2,2,'skin')
 elseif d==6 then
  -- Away from camera: raised arm reaches above the shoulder, beside the head.
  poly({{37,28},{41,30},{47,26},{48,19},{44,18},{41,24}},'ink')
  poly({{39,28},{41,28},{45,25},{46,20},{44,20},{42,26}},'fold')
  rect(43,19,4,3,'white');rect(44,15+lift,3,5,'skin')
  rect(45,13+lift,2,3,'skin')
 elseif d==5 or d==7 then
  poly({{37,27},{42,29},{51,22},{50,17},{46,18},{40,24}},'ink')
  poly({{39,27},{42,27},{49,22},{48,19},{46,20},{41,25}},'robe')
  poly({{47,19},{50,17},{52,20},{49,23}},'white')
  rect(50,16+lift,4,3,'skin');rect(53,14+lift,2,3,'skin')
 else
  -- SE / SW: forearm points diagonally forward and down, not horizontally.
  poly({{37,25},{41,27},{46,32},{53,34},{52,40},{44,44},{39,36}},'ink')
  poly({{38,28},{41,29},{45,34},{51,36},{49,40},{44,41},{41,34}},'robe')
  poly({{49,34},{53,35},{53,39},{49,38}},'white')
  rect(53,36+lift,4,3,'skin');rect(56,38+lift,2,2,'skin')
 end
end
local atlas=Image(W*8,H*40,ColorMode.RGB)
local dirs={'e','se','s','sw','w','nw','n','ne'}
local states={'idle','walk','cast','fly','hover'}
for row_st=0,4 do for d=0,7 do
 local st=math.min(row_st,3)
 local first=row_st*64+d*8+1
 for f=0,7 do
  local frame=first+f
  if frame>1 then spr:newEmptyFrame() end
  spr.frames[frame].duration= st==0 and 0.18 or 0.1
  local t=f/8*math.pi*2
  local stride=st==1 and math.sin(t) or 0
  local wind=math.floor(math.sin(t)*(st==0 and 1.3 or 2.5)+0.5)
  bob=st==1 and -math.floor(math.abs(stride)+0.5) or 0
  mirror=d==3 or d==4 or d==5
  local side=d==0 or d==4
  local back=d>=5
  local diag=d==1 or d==3 or d==5 or d==7
  profile=diag and 0.92 or 1.0
  local face=side and 4 or (diag and 2 or 0)
  local h=wind
  local merged=Image(W,H,ColorMode.RGB)
  for layer=1,3 do
   img=Image(W,H,ColorMode.RGB)
   if custom_renderer then
    custom_renderer(layer,row_st,d,wind,stride,poly,rect,px)
   elseif side then
    side_layer(layer,row_st,d,wind,stride)
   elseif layer==1 then
    -- Narrow adult proportions: head 11 px, full silhouette 68 px.
    rect(25,70+math.floor(stride*2),7,3,'ink');rect(34,70-math.floor(stride*2),7,3,'ink')
    rect(25,73+math.floor(stride*2),7,1,'shade');rect(34,73-math.floor(stride*2),7,1,'shade')
    poly({{26,25},{38,25},{40,43},{47+h,70},{40,73},{21+h,72},{23,49}},'ink')
    poly({{27,27},{37,27},{39,44},{45+h,69},{39,71},{23+h,70},{25,47}},'robe')
    poly({{28,40},{36,40},{38+h,70},{26+h,71}},'white')
    poly({{31,44},{33,43},{34+h,69},{29+h,70}},'shade')
    poly({{36,44},{38,46},{42+h,70},{37+h,70}},'deep')
    poly({{25,40},{29,39},{26+h,67},{22+h,70}},'dark')
    poly({{38,39},{40,46},{45+h,69},{40+h,68}},'dark')
    poly({{24,54},{26,47},{25+h,67},{23+h,67}},'fold')
    if back then
     poly({{26,30},{38,29},{41,51},{42+h,70},{31+h,69},{24+h,70}},'robe')
     poly({{32,44},{35,43},{34+h,68},{30+h,70}},'dark')
     poly({{37,49},{40+h,67},{37+h,66}},'fold')
    end
   elseif layer==2 then
    poly({{26,22},{37,22},{40,35},{37,43},{25,42},{23,30}},'robe')
    if not back then
     poly({{28+face,22},{36+face,22},{38,28},{29,40},{26,35}},'white')
     poly({{29+face,24},{31+face,29},{36+face,23},{36+face,26},{29,37},{28,33}},'shade')
     poly({{26,24},{28,25},{26,39},{24,36}},'edge')
     rect(25,40,14,3,'sash');poly({{34,41},{37,42},{40+wind,53},{37+wind,51}},'deep')
     rect(32,40,3,2,'shade')
    end
    if st==3 then
     -- Both elbows draw back. From behind, wrists meet below the hair tips.
     poly({{25,25},{28,28},{25,36},{27,43},{29,45},{26,48},{22,43},{21,35}},'ink')
     poly({{24,28},{26,29},{23,36},{25,43},{24,43},{22,37}},'fold')
     poly({{38,25},{41,28},{43,36},{41,43},{37,48},{34,45},{38,40},{39,34}},'ink')
     poly({{39,28},{40,31},{41,36},{39,41},{37,44},{36,43},{39,37}},'fold')
     if back then
      poly({{26,43},{29,44},{32,47},{29,49},{26,47}},'white')
      poly({{37,43},{39,45},{36,49},{33,48},{34,45}},'shade')
      rect(29,47,7,3,'skinshade');rect(30,47,5,2,'skin')
     end
    else
    -- Hanging sleeve with a pale lining; casting sleeve reaches outward.
    poly({{24,24},{28,28},{25,38},{23+wind,52},{17+wind,48},{19,35}},'ink')
    poly({{24,26},{26,29},{23,40},{22+wind,50},{18+wind,47},{21,34}},'fold')
    poly({{20+wind,42},{23+wind,43},{22+wind,50},{18+wind,47}},'shade')
    rect(21+wind,40,3,5,'skin')
    if st==2 then
     -- Draw the directional casting arm after hair so the gesture stays legible.
    else
     poly({{37,24},{41,27},{44,39},{46-wind,48},{40-wind,52},{36,38}},'ink')
     poly({{38,26},{40,29},{42,39},{44-wind,47},{40-wind,49},{38,38}},'robe')
     poly({{40,37},{42,42},{42-wind,47},{40-wind,48}},'fold')
     rect(40-wind,46,3,3,'shade')
     rect(40-wind,49,3,4,'skin');px(41-wind,53,'skinshade')
    end
    end
   else
    -- Loose waist-length hair, separate tapered locks and restrained highlights.
    poly({{26,9},{31,6},{37,8},{40,17},{40,27},{44+wind,41},{40+wind,38},{37,28},{25,33},{22+wind,44},{22,31},{24,20}},'hair')
    if not back then
     poly({{26,12},{30,9},{32,9},{28,14},{26,26}},'shine')
     poly({{37,18},{39,26},{42+wind,34},{40+wind,31}},'fold')
     px(31,8,'edge')
     if d==2 then
      poly({{29,13},{35,13},{36,18},{35,22},{32,25},{29,23},{28,18}},'skinshade')
      poly({{30,13},{34,13},{35,18},{34,22},{32,24},{30,22},{29,18}},'skin')
      poly({{28,11},{32,9},{31,13},{28,18},{27,28},{26,26}},'hair')
      poly({{33,10},{36,12},{38,24},{37,28},{35,19},{34,13}},'hair')
     else
      -- SE / SW: a broader near cheek, short jaw, same vertical landmarks.
      -- Keep the temple lock outside the face instead of cutting it in half.
      poly({{30,13},{36,13},{38,17},{37,22},{34,25},{31,23},{29,18}},'skinshade')
      poly({{32,13},{36,14},{37,17},{36,22},{34,24},{32,22},{31,17}},'skin')
      poly({{27,11},{31,9},{35,10},{33,13},{30,15},{29,23},{27,30},{26,26}},'hair')
      poly({{36,11},{38,13},{40,25},{41+wind,34},{38,30},{37,23},{38,17}},'hair')
      poly({{27,14},{29,12},{30,12},{28,19},{27,25}},'shine')
     end
    else
     poly({{26,12},{31,8},{36,10},{39,21},{40+wind,37},{36+wind,46},{31,41},{26+wind,45},{25,30}},'hair')
     poly({{28,12},{30,10},{29,27},{28+wind,39},{26+wind,42}},'shine')
     poly({{33,10},{35,12},{35,28},{37+wind,40},{34+wind,38},{32,24}},'fold')
     poly({{38,22},{40+wind,34},{39+wind,39}},'shine')
     if diag then
      poly({{37,15},{40,17},{39,22},{37,23}},'skinshade')
      poly({{38,24},{41,27},{39,29},{37,27}},'white')
      poly({{35,11},{38,13},{38,22},{37,28},{36,23}},'hair')
     end
    end
   end
   if not custom_renderer and layer==3 and st==2 and not side then cast_arm(d,t) end
   spr:newCel(layers[layer],frame,img,Point(0,0))
   merged:drawImage(img,Point(0,0))
  end
  atlas:drawImage(merged,Point(f*W,(row_st*8+d)*H))
 end
 local tag=spr:newTag(first,first+7);tag.name=states[row_st+1]..'_'..dirs[d+1]
end end
spr:saveAs(out..'/swordsman.aseprite')
atlas:saveAs(out..'/swordsman.png')
print('SWORDSMAN_ASSETS_OK frames='..#spr.frames..' tags='..#spr.tags..' layers='..#spr.layers)
