Unit things;

interface

procedure take_thing(find:string);
procedure init_thinger;
procedure done_thinger;
procedure refresh_thinger;
function in_thingbar(x,y:word):boolean;
procedure do_thingbar(butt:byte; x,y:word);
function name_thingbar(x,y:word):string;

implementation

uses { core modules }
     start,core,misc,kernel,objects,streams,types,
     { constants modules }
     data,strconst,Constants,
     { script-related }
     tpstr,tpparam,flashcom,tptimeline,
     flobjects,flaction,flmain,textlib,flscript,
     { fx-api }
     fx_mouse,fx_pens,fx_dev,fx_types,fx_fonts,fx_pal,
     fx_shape,fx_init,imgstack,fx_form,flplay,
     { resource-file }
     res_type,
     { main engine }
     locview,flgraph,
     { sound engine }
     acting,play,sounds,
     paths;

const
     cMaxIcons = 32;
     cICONUP   = 'MOVE_UP';
     cICONDN   = 'MOVE_DN';
     cICONSP   = 3;
     cFILLCOL  = 0;

 {$I iconbar.pas}

const
     cThingPicX   = 272;
     cThingPicY   = 25;
     cThingBarX   = cThingPicX+2;
     cThingBarY   = cThingPicY+2;
     cThingBarW   = 32;
     cThingBarH   = 32;
     cThingBars   = 3;
     cThingBarPic = '';{'BUTT_FRAME';}

var thingbar:piconbar;

procedure take_thing(find:string);
 var thing:pFlashObject;
begin
 thing:=thinglist^.find(find);
 if thing=nil
 then ErrorMSG(Str2Pchar('can`t find thing '+find))
 else begin
  thingbar^.add_icon( get_var(cVAR_ICON,thing^.reskey) );
  player^.things^.put(find);
{  thingbar^.scroll(1);}
 end;
end; { flaction }

procedure init_thinger;
 var a:integer;
     thing:pFlashObject;
     dev:pdevice;
begin
 new(thingbar,init(cThingBarW,cThingBarH,cThingBars));
 if player^.things^.count<>0 then
 for a:=0 to player^.things^.count-1 do
  begin
   thing:=findin(player^.things^.get(a));
   if thing=nil
   then errorMSG(Str2Pchar('player have incorrect thing '+player^.things^.get(a)))
   else thingbar^.add_icon(get_var(cVAR_ICON,thing^.reskey));
  end;
 if cTHINGBARPIC<>'' then
 begin
  dev:=new(PDEVICE,Load(res^.loadres(cTHINGBARPIC)^));
  dev^.fulldevicecopy0(cThingPicX,cTHingPicY,screen);
  dispose(dev,done);
 end;
 thingbar^.show(cThingBarX,cThingBarY);
end;

procedure done_thinger;
begin
 dispose(thingbar,done);
end;

procedure refresh_thinger;
begin
 done_thinger;
 init_thinger;
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
  01: act_default(PFlashCommon(thinglist^.find(player^.things^.get(res))));
  02: act_list(PFlashCommon(thinglist^.find(player^.things^.get(res))));
 end;
end;

function name_thingbar(x,y:word):string;
 var res:integer;
begin
 name_thingbar:='';
 hide_mouse;
 res:=thingbar^.lazychoose(x,y);
 show_mouse;
 if res<>-1 then name_thingbar:=player^.things^.get(res);
end;

end.

