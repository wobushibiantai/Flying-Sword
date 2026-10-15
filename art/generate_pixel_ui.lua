-- Pixel UI pieces drawn as editable native Aseprite sprites.
local out=app.params.out or 'sword/assets/pixel/ui'
app.fs.makeAllDirectories(out)
local pc=app.pixelColor
local function color(h,a) return pc.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),a or 255) end
local C={ink=color('102225'),dark=color('173033'),jade=color('284b47'),hover=color('345d55'),gold=color('b49d66'),edge=color('53766c'),light=color('d2e6ac'),white=color('e8eed8')}
local function rect(im,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do im:putPixel(xx,yy,c) end end end
local function line(im,x0,y0,x1,y1,c)
 local n=math.max(math.abs(x1-x0),math.abs(y1-y0))
 if n==0 then im:putPixel(x0,y0,c);return end
 for i=0,n do local x=math.floor(x0+(x1-x0)*i/n+0.5);local y=math.floor(y0+(y1-y0)*i/n+0.5);im:putPixel(x,y,c) end
end
local function make(name,w,h,render)
 local spr=Sprite(w,h,ColorMode.RGB)
 local labels={'Field','Pixel trim','Glyph'}
 local merged=Image(w,h,ColorMode.RGB)
 for k=1,3 do
  local layer=k==1 and spr.layers[1] or spr:newLayer();layer.name=labels[k]
  local im=Image(w,h,ColorMode.RGB);render(k,im)
  spr:newCel(layer,1,im,Point(0,0));merged:drawImage(im,Point(0,0))
 end
 spr:saveAs(out..'/'..name..'.aseprite');merged:saveAs(out..'/'..name..'.png');spr:close()
 print('PIXEL_UI_OK '..name..' '..w..'x'..h)
end
local function nine(name,fill,trim)
 make(name,32,32,function(layer,im)
  if layer==1 then rect(im,3,3,26,26,C.ink);rect(im,4,4,24,24,fill)
  elseif layer==2 then
   rect(im,5,1,22,2,trim);rect(im,5,29,22,2,trim)
   rect(im,1,5,2,22,trim);rect(im,29,5,2,22,trim)
   rect(im,2,2,5,3,C.gold);rect(im,25,2,5,3,C.gold)
   rect(im,2,27,5,3,C.gold);rect(im,25,27,5,3,C.gold)
  else
   for _,p in ipairs({{5,5},{26,5},{5,26},{26,26}}) do rect(im,p[1],p[2],2,2,C.light) end
  end
 end)
end
nine('panel',C.dark,C.edge)
nine('button',C.jade,C.edge)
nine('button_hover',C.hover,C.gold)
nine('button_pressed',C.dark,C.light)
nine('tab',C.dark,C.edge)
nine('tab_selected',C.jade,C.gold)
make('track',32,8,function(layer,im)
 if layer==1 then rect(im,0,1,32,6,C.ink);rect(im,1,2,30,4,C.dark)
 elseif layer==2 then rect(im,1,1,30,1,C.edge);rect(im,1,6,30,1,C.edge)
 else for i=4,27,8 do rect(im,i,3,1,2,C.jade) end end
end)
make('track_fill',32,8,function(layer,im)
 if layer==1 then rect(im,0,1,32,6,C.ink);rect(im,1,2,30,4,C.jade)
 elseif layer==2 then rect(im,1,1,30,1,C.gold);rect(im,1,6,30,1,C.gold)
 else rect(im,3,3,26,1,C.light) end
end)
make('thumb',16,18,function(layer,im)
 if layer==1 then rect(im,2,0,12,18,C.ink);rect(im,4,2,8,14,C.jade)
 elseif layer==2 then rect(im,3,1,10,2,C.gold);rect(im,3,15,10,2,C.gold)
 else rect(im,7,5,2,8,C.light) end
end)
for _,on in ipairs({false,true}) do
 make(on and 'check_on' or 'check_off',16,16,function(layer,im)
  if layer==1 then rect(im,1,1,14,14,C.ink);rect(im,3,3,10,10,C.dark)
  elseif layer==2 then
   rect(im,3,1,10,1,C.gold);rect(im,3,14,10,1,C.gold)
   rect(im,1,3,1,10,C.gold);rect(im,14,3,1,10,C.gold)
  elseif on then line(im,4,8,7,11,C.light);line(im,7,11,12,5,C.light) end
 end)
end
make('arrow',12,12,function(layer,im)
 if layer==2 then for y=4,8 do rect(im,2+y-4,y,8-(y-4)*2,1,C.gold) end end
end)
local icons={
 sword={{2,13,14,2},{6,11,12,1},{3,10,4,5}},
 bloom={{7,3,2,10},{2,7,13,2},{4,4,2,2},{11,4,2,2},{4,11,2,2},{11,11,2,2}},
 river={{1,4,3,3},{5,7,3,3},{9,4,3,3},{13,7,2,3}},
 rise={{7,2,2,12},{4,6,3,3},{9,6,3,3}},
 land={{7,1,2,10},{4,7,3,3},{9,7,3,3},{2,13,12,2}}}
for name,parts in pairs(icons) do
 make('icon_'..name,16,16,function(layer,im)
  if layer==1 then for _,p in ipairs(parts) do rect(im,p[1],p[2],p[3],p[4],C.ink) end
  elseif layer==2 then for _,p in ipairs(parts) do rect(im,p[1]+1,p[2],math.max(1,p[3]-2),math.max(1,p[4]-1),C.gold) end
  else rect(im,7,7,2,2,C.light) end
 end)
end
