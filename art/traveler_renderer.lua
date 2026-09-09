-- Alternate hand-drawn pixel design based on the supplied September reference.
-- Shared exporter supplies the palette, pixel rasterizer, layers and tags.
return function(layer,state,d,wind,stride,P,R,X)
 local side=d==0 or d==4
 local back=d>=5
 local diagonal=d==1 or d==3 or d==5 or d==7
 local fly=state>=3
 local moving=state==3
 local left=d==4
 local hem=wind
 local foot=state==1 and math.floor(stride*2+0.5) or 0
 if layer==1 then
  if not fly then
   R(23-foot,71,9,3,'ink'); R(34+foot,71,10,3,'ink')
   R(24-foot,73,8,1,'edge'); R(35+foot,73,8,1,'shade')
  end
  -- Wide layered outer robe; the central ivory panel falls vertically.
  local rear=side and moving and 13+hem or 18+hem
  local front=side and moving and 42 or 46+hem
  P({{23,27},{40,27},{42,44},{front,69},{front-3,73},{rear+2,74},{rear-2,69},{23,45}},'ink')
  P({{24,29},{39,29},{40,46},{front-2,69},{front-4,72},{rear+3,72},{rear,68},{25,45}},'robe')
  if not back then
   local ivory=side and (left and 34 or 37) or 27
   P({{ivory,43},{38,43},{41,72},{ivory-2,72},{ivory-3,67}},'white')
   P({{ivory+1,47},{ivory+3,47},{ivory+2,66},{ivory+5,72},{ivory+1,71}},'shade')
   P({{36,48},{38,45},{40,70},{37,68}},'shade')
   P({{29,50},{31,56},{30,65},{28,69}},'edge')
   P({{23,44},{27,43},{25,55},{rear+1,68},{rear,64}},'dark')
   P({{39,43},{42,49},{front-2,66},{39,70},{38,60}},'dark')
   P({{39,51},{41,55},{front-3,63},{front-5,65},{39,57}},'fold')
   P({{24,53},{26,49},{24,61},{rear+2,65},{rear+1,63}},'edge')
  else
   P({{26,44},{39,43},{42,64},{40,72},{32,70},{rear+3,72},{23,60}},'dark')
   P({{30,50},{32,47},{31,66},{28,71},{26,69}},'fold')
   P({{36,50},{39,54},{41,65},{37,64},{35,59}},'fold')
   P({{32,65},{34,63},{37,73},{31,73}},'shade')
  end
  -- Broken clusters suggest cloth weight rather than flat polygon planes.
  for _,p in ipairs({{23,59},{22,63},{39,54},{40,58},{42,65},{27,68}}) do
   R(p[1],p[2],2,2,'fold')
  end
 elseif layer==2 then
  P({{22,27},{28,24},{37,24},{43,28},{42,42},{38,46},{23,43}},'ink')
  P({{24,28},{29,26},{36,26},{41,29},{39,43},{25,42}},'robe')
  if not back then
   P({{27,25},{33,28},{38,25},{41,29},{28,42},{24,36}},'white')
   P({{28,27},{31,31},{37,26},{38,28},{28,38},{26,35}},'shade')
   P({{26,29},{27,31},{25,38},{23,40}},'edge')
   P({{38,29},{40,31},{29,41},{27,40}},'shade')
   R(25,42,15,4,'sash')
   P({{25,42},{32,43},{40,42},{39,44},{28,45}},'deep')
   R(30,43,3,2,'shade');R(34,45,5,1,'ink')
   if not side or left then
    P({{34,45},{37,45},{39+hem,54},{36+hem,52}},'sash')
   end
  end
  if fly then
   -- Wide sleeves sweep into a composed hands-behind-back pose.
   P({{22,28},{26,30},{23,37},{25,43},{29,47},{25,51},{19,45},{18,36}},'ink')
   P({{22,31},{24,32},{21,37},{23,43},{26,47},{24,48},{20,43}},'fold')
   P({{40,28},{44,30},{46,38},{43,47},{37,51},{34,48},{39,43},{41,36}},'ink')
   P({{41,31},{43,33},{44,38},{41,45},{37,48},{36,47},{40,42}},'robe')
   if side then
    P({{21,43},{24,44},{24,47},{21,48}},'white');R(21,47,4,3,'skin')
   elseif back then
    P({{26,46},{30,47},{32,50},{29,51},{26,49}},'white')
    P({{37,46},{40,48},{36,51},{33,50}},'shade')
    R(29,49,7,2,'skin');R(31,51,4,1,'skinshade')
   end
  else
   -- Hanging near sleeve: broad black volume, ivory turned cuff, exposed hand.
   P({{22,28},{26,31},{24,41},{23+hem,50},{18+hem,53},{15+hem,48},{17,35}},'ink')
   P({{21,31},{24,32},{22,41},{21+hem,49},{18+hem,50},{17+hem,46},{19,36}},'robe')
   P({{19,35},{21,34},{20,44},{18+hem,47},{17+hem,45}},'fold')
   P({{18+hem,45},{22+hem,46},{21+hem,50},{17+hem,48}},'white')
   R(19+hem,49,3,5,'skinshade');R(20+hem,49,2,4,'skin')
   if state~=2 then
    P({{40,28},{44,31},{47,41},{48-hem,49},{43-hem,53},{38,49},{37,36}},'ink')
    P({{41,31},{43,33},{45,41},{46-hem,48},{43-hem,50},{40,47},{39,36}},'robe')
    P({{40,36},{42,36},{44,44},{42-hem,48},{41-hem,46}},'fold')
    P({{40-hem,48},{45-hem,49},{44-hem,51},{40-hem,50}},'edge')
    R(41-hem,51,3,3,'skin')
   end
  end
 else
  -- Fuller head and long layered locks, close to the proportions of the sheet.
  P({{24,9},{29,6},{36,7},{41,10},{43,18},{41,30},{44+hem,44},{40+hem,46},{37,33},{37,26},{28,26},{27,33},{24+hem,48},{19+hem,43},{22,28},{21,18}},'ink')
  P({{25,10},{29,8},{36,9},{39,11},{41,19},{39,29},{42+hem,42},{40+hem,43},{38,32},{38,25},{27,25},{26,33},{23+hem,45},{22+hem,42},{24,26},{23,17}},'hair')
  for _,p in ipairs({{27,11},{30,9},{34,10},{37,12},{25,15},{39,19}}) do R(p[1],p[2],2,2,'shine') end
  P({{25,17},{27,13},{28,14},{26,27},{23+hem,39},{22+hem,41}},'shine')
  P({{37,14},{39,17},{38,28},{41+hem,40},{38+hem,37},{36,25}},'fold')
  P({{24,28},{25,30},{24+hem,42},{22+hem,44}},'fold')
  if back then
   P({{29,11},{32,9},{35,12},{36,26},{39+hem,41},{35+hem,47},{30,42},{27+hem,46},{26,33}},'hair')
   P({{29,14},{31,12},{30,30},{31+hem,39},{29+hem,43},{28,30}},'shine')
   P({{33,15},{35,19},{34,31},{37+hem,41},{35+hem,44},{32,30}},'fold')
   R(30,12,2,3,'fold');R(33,11,2,2,'shine')
   if diagonal then P({{39,18},{41,19},{40,25},{38,27}},'skinshade') end
  else
   local shift=side and 3 or (diagonal and 1 or 0)
   P({{27+shift,15},{35+shift,15},{36+shift,22},{34+shift,26},{31+shift,28},{28+shift,25}},'skinshade')
   P({{29+shift,15},{34+shift,16},{35+shift,22},{33+shift,26},{31+shift,27},{29+shift,24}},'skin')
   -- No eye/mouth pixels: preserve the user's clean face preference.
   P({{25,12},{30,9},{34,11},{32,15},{28+shift,17},{27,29},{25+hem,35},{24,30}},'hair')
   P({{35,11},{38,14},{39,25},{41+hem,32},{38,31},{36+shift,24},{35+shift,17}},'hair')
   P({{25,16},{27,13},{29,12},{27,18},{26,26}},'shine')
   R(31,10,2,2,'fold');R(34,12,2,2,'shine')
  end
  -- Loose outer wisps make the dark silhouette less blocky.
  P({{22,23},{21,33},{17+hem,40},{18+hem,44},{16+hem,42},{19,32}},'hair')
  P({{41,23},{43,28},{48+hem,38},{47+hem,44},{46+hem,42},{46+hem,36}},'hair')
  if state==2 then
   local hand_x,hand_y=53,35
   if side then hand_x,hand_y=54,28
   elseif d==2 then hand_x,hand_y=36,38
   elseif d==6 then hand_x,hand_y=44,17
   elseif back then hand_x,hand_y=52,19 end
   P({{39,29},{43,30},{hand_x-1,hand_y-2},{hand_x+1,hand_y+4},{44,46},{39,41}},'ink')
   P({{40,32},{43,33},{hand_x-2,hand_y},{hand_x-1,hand_y+3},{44,42},{41,39}},'robe')
   P({{42,34},{43,35},{46,39},{44,41}},'fold')
   R(hand_x-2,hand_y,4,3,'white');R(hand_x+1,hand_y,4,3,'skin')
   R(hand_x+3,hand_y-1,2,2,'skin')
  end
 end
end
