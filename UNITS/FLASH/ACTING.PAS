Unit acting;

interface

 uses flobjects;

Const
     cDefaultAct        = '#default';
     cDescribe          = '#describe';
     cDoTalk            = '#talkto';
     cEX_PREFIX         = 'DEL_';

     Listsize=32;
type
    listrec=record
     listname:string[16];
     Kind:(grel,orel);
    end;
    plist=^tlist;
    tlist=record
     length:byte;
     listing:array[0..listsize-1] of listrec;
    end;

procedure dirdefaultact(dirname:string);
procedure act_default(obj:pFlashCommon);
procedure act_list(obj:pFlashCommon);

implementation

uses objects,core,misc,types,constants,
     tpstr,flashcom,flaction,
     fx_mouse,fx_init,flgraph,fx_form,play,sounds;


procedure dirdefaultact(dirname:string);
 var comm:pCommands;
begin
 comm:=currentloc^.acts^.getname(dirname);
 if comm=nil
 then Message('нет выхода '+dirname)
 else begin
  comm^.run;
  Atmo^.TimeLine^.ProcessEvents;
 end;
end;

procedure act_default(obj:pFlashCommon);
 var cm:pCommands;
begin
 case obj^.Kind of
  nTHING:  begin
            CurrentThing:=obj^.Name;
            cm:=obj^.acts^.getname(cDefaultAct);
            if cm<>nil
            then cm^.run
            else MessageWindow(PTHING(obj)^.text);
            Atmo^.TimeLine^.ProcessEvents;
           end;
  nLOC  :  begin
            cm:=obj^.acts^.getname(cDescribe);
            if cm<>nil
            then cm^.run
            else MessageWindow(PLocation(obj)^.text);
            Atmo^.TimeLine^.ProcessEvents;
           end;
  nHUMAN:  begin
            cm:=obj^.acts^.getname(cDOTALK);
            if cm<>nil
            then cm^.run
            else MessageWindow(PHuman(obj)^.text);
            Atmo^.TimeLine^.ProcessEvents;
           end;
 end;
end;


procedure add_orel(obj:pFlashCommon; var list:tlist);
 var a:integer;
     name:pstring;

function must_exclude(act:nstring):boolean;
begin
 if PFlashCommon(Obj)^.Params^.SearchRec(cEX_PREFIX+Act)<>nil
 then must_exclude:=true
 else must_exclude:=false;
end;

begin
 for a:=0 to obj^.acts^.commands^.count-1 do
     begin
      name:=PCommands(obj^.acts^.commands^.at(a))^.name;
      if (name<>nil) and (name^[1]<>'#') and (not must_exclude(name^))
      then if list.length=listsize
           then ErrorMSG(Str2Pchar('Can`t add orel to list for '+obj^.name))
           else begin
            list.listing[list.length].listname:=name^;
            list.listing[list.length].Kind:=orel;
            inc(list.length);
           end;
     end;
end;


procedure add_grel(obj:pFlashCommon; var list:tlist);
 var a:integer;
     name:IdentString;
     PlayName:TString;

function must_exclude(act:nstring):boolean;
begin
 if PFlashCommon
 (Obj)^.Params^.SearchRec(cEX_PREFIX+Act)<>nil
 then must_exclude:=true
 else must_exclude:=false;
end;

begin
 for a:=0 to actlist^.count-1 do
 begin
  name:=actlist^.get(a)^.name;
  if (name[1]<>'#') and (not must_exclude(name))
  then if list.length=listsize
          then ErrorMSG(Str2Pchar('Can`t add grel '+name+' for unkown'))
          else begin
           list.listing[list.length].listname:=name;
           list.listing[list.length].Kind:=grel;
           inc(list.length);
          end;
 end;
end;

procedure make_list(obj:pFlashCommon; var list:tlist);
begin
 list.length:=0;
 case obj^.Kind of
  nTHING:begin
          CurrentThing:=obj^.Name;
          add_grel(obj,list);
          add_orel(obj,list);
         end;
  nLOC  :begin
          CurrentThing:=obj^.Name;
          add_orel(obj,list);
         end;
  nHUMAN:begin
          CurrentThing:=obj^.Name;
          add_orel(obj,list);
          add_grel(obj,list);
         end;
 end;
end;

function choose(butt:pbutton_line):integer;
 var i:integer;
     x,y:word;
begin
 hide_mouse;
 if butt^.viewed then butt^.hide;
 if not butt^.viewed then begin

  if butt^.height+5+mouseposy>Screen^.height
  then y:=Screen^.height-butt^.height-1
  else begin
   if MousePOSY>10
   then y:=MousePOSY-10
   else y:=mouseposy;
  end;

  if butt^.width+5+mouseposx>Screen^.Width
  then x:=Screen^.Width-butt^.width-1
  else begin
   if MousePOSX>10
   then X:=MousePOSX-10
   else X:=mouseposX;
  end;

  butt^.show(x,y);
 end;
 show_mouse;
  while true do begin

  if mousebuttons=02 then begin
     while mousebuttons<>0 do;
     choose:=-1;
     exit;
  end;

  if mousebuttons=01
  then begin
   i:=butt^.pressed(mouseposx,mouseposy);
   if i<>-1 then begin
    PlaySound(sndClick);
    choose:=i;
    while mousebuttons<>0 do;
    exit;
   end else while mousebuttons<>0 do;
  end;
 end;
end;

procedure act_list(obj:pFlashCommon);
var
   list:plist;
   butt:pbutton_line;
   c:byte;
   a,wasb,len,len1:integer;
begin
 new(list);
  make_list(obj,list^);
  if list^.length=0 then begin
                          dispose(list);
                          exit;
                         end;
  if list^.length<10
     then c:=list^.length
     else c:=10;

  len:=LightFont^.lnWidth(obj^.playname);
  for a:=0 to list^.length-1 do begin
   len1:=LightFont^.lnWidth(list^.listing[a].listname);
   if len1>len then len:=len1;
  end;

  new(butt,init(c,len+15,obj^.playname));
  for a:=0 to list^.length-1 do
   case list^.listing[a].kind of
    orel : butt^.add_butt(list^.listing[a].listname);
    grel : butt^.add_butt(actlist^.find(list^.listing[a].listname)^.playname);
   end;
  wasb:=butt^.buttons;
  a:=choose(butt);
  hide_mouse;
  dispose(butt,done);
  show_mouse;
  if (a<>-1) and (a<>wasb) then
  case list^.listing[a].Kind of
   orel : begin
           obj^.acts^.getname(list^.listing[a].listname)^.run;
           Atmo^.TimeLine^.ProcessEvents;
          end;
   grel : begin
           pact(actlist^.find(list^.listing[a].listname))^.run(obj^.name);
           Atmo^.TimeLine^.ProcessEvents;
          end;
  end;
 dispose(list);
end;

end.