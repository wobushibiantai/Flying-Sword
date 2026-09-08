-- Run with Aseprite --batch --script-param out=... --script this-file.lua
-- Hand-authored pixel clusters. Reference: supplied black/ivory swordsman sheet.
local out=app.params.out or 'sword/assets/character'
local W,H=64,80
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
local atlas=Image(W*8,H*24,ColorMode.RGB)
local dirs={'e','se','s','sw','w','nw','n','ne'}
local states={'idle','walk','cast'}
for st=0,2 do for d=0,7 do
 local first=st*64+d*8+1
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
  profile=side and 0.78 or (diag and 0.92 or 1.0)
  local face=side and 4 or (diag and 2 or 0)
  local h=wind
  local merged=Image(W,H,ColorMode.RGB)
  for layer=1,3 do
   img=Image(W,H,ColorMode.RGB)
   if layer==1 then
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
    -- Hanging sleeve with a pale lining; casting sleeve reaches outward.
    poly({{24,24},{28,28},{25,38},{23+wind,52},{17+wind,48},{19,35}},'ink')
    poly({{24,26},{26,29},{23,40},{22+wind,50},{18+wind,47},{21,34}},'fold')
    poly({{20+wind,42},{23+wind,43},{22+wind,50},{18+wind,47}},'shade')
    rect(21+wind,40,3,5,'skin')
    if st==2 then
     local lift=math.floor(math.sin(t)*1.2+0.5)
     poly({{37,24},{43,27},{52,25+lift},{53,31+lift},{49,43},{42,40},{38,32}},'ink')
     poly({{38,26},{44,29},{51,27+lift},{51,32+lift},{48,40},{43,38}},'robe')
     poly({{48,28+lift},{51,26+lift},{53,29+lift},{49,35}},'white')
     rect(52,25+lift,5,3,'skin');rect(55,24+lift,3,1,'skin')
     poly({{40,30},{46,34},{48,38},{44,36}},'fold')
    else
     poly({{37,24},{41,27},{44,39},{46-wind,48},{40-wind,52},{36,38}},'ink')
     poly({{38,26},{40,29},{42,39},{44-wind,47},{40-wind,49},{38,38}},'robe')
     poly({{40,37},{42,42},{42-wind,47},{40-wind,48}},'fold')
     rect(40-wind,46,3,3,'shade')
    end
   else
    -- Loose waist-length hair, separate tapered locks and restrained highlights.
    poly({{26,9},{31,6},{37,8},{40,17},{40,27},{44+wind,41},{40+wind,38},{37,28},{25,33},{22+wind,44},{22,31},{24,20}},'hair')
    if not back then
     poly({{28+face,13},{35+face,12},{37+face,18},{35+face,24},{32+face,26},{28+face,22}},'skinshade')
     poly({{29+face,13},{35+face,14},{35+face,20},{33+face,24},{30+face,22}},'skin')
     if side then px(40,18,'skin');rect(35,17,3,1,'ink')
     else rect(29+face,17,2,1,'ink');rect(34+face,17,2,1,'ink');px(33+face,21,'skinshade') end
     poly({{25,11},{30,7},{37,9},{39,16},{34+face,12},{31+face,13},{27,20},{26,31},{24+wind,38},{25,22}},'hair')
     poly({{34+face,11},{37+face,14},{38,28},{41+wind,35},{37,32},{35,23}},'hair')
     poly({{26,12},{30,9},{32,9},{28,14},{26,26}},'shine')
     poly({{37,18},{39,26},{42+wind,34},{40+wind,31}},'fold')
     px(31,8,'edge')
     if d==2 then
      poly({{29,13},{35,13},{36,19},{34,23},{32,25},{29,22},{28,17}},'skinshade')
      poly({{30,13},{34,13},{35,19},{33,23},{31,22},{29,18}},'skin')
      rect(29,17,2,1,'ink');rect(34,17,2,1,'ink')
      px(32,21,'skinshade')
      poly({{28,11},{32,9},{31,13},{28,19},{27,28},{26,26}},'hair')
      poly({{33,10},{36,12},{38,24},{37,28},{35,20},{34,14}},'hair')
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
   spr:newCel(layers[layer],frame,img,Point(0,0))
   merged:drawImage(img,Point(0,0))
  end
  atlas:drawImage(merged,Point(f*W,(st*8+d)*H))
 end
 local tag=spr:newTag(first,first+7);tag.name=states[st+1]..'_'..dirs[d+1]
end end
spr:saveAs(out..'/swordsman.aseprite')
atlas:saveAs(out..'/swordsman.png')
print('SWORDSMAN_ASSETS_OK frames='..#spr.frames..' tags='..#spr.tags..' layers='..#spr.layers)
