procedure take_thing(find:string);
 var thing:pclass;
begin
 thing:=thinglist^.find(find);
 if thing=nil
 then ErrorMSG('can`t find thing '+find)
 else begin
  thingbar^.add_icon( get_var(cVAR_ICON,thing^.reskey) );
  player^.things^.put(find);
 end;
end;

procedure init_thinger;
 var a:integer;
     thing:pclass;
     dev:pdevice;
begin
 new(thingbar,init(cThingBarW,cThingBarH,cThingBars));
 for a:=0 to player^.things^.count-1 do
  begin
   thing:=findin(player^.things^.get(a));
   if thing=nil
   then errorMSG('player have incorrect thing '+player^.things^.get(a))
   else thingbar^.add_icon(get_var(cVAR_ICON,thing^.reskey));
  end;
 dev:=new(PDEVICE,Load(res^.loadres(cTHINGBARPIC)^));
 dev^.fulldevicecopy0(cThingPicX,cTHingPicY,screen);
 dispose(dev,done);
 thingbar^.show(cThingBarX,cThingBarY);
end;

procedure done_thinger;
begin
 dispose(thingbar,done);
end;

function in_thingbar(x,y:word):boolean;
begin
 in_thingbar:=thingbar^.here(x,y);
end;

procedure do_thingbar(butt:byte; x,y:word);
 var res:integer;
begin
 hide_mouse;
 res:=thingbar^.choose(x,y);
 show_mouse;
 if res<>-1 then
 case butt of
  01: act_default(thinglist^.find(player^.things^.get(res)));
  02: act_list(thinglist^.find(player^.things^.get(res)));
 end;
end;
