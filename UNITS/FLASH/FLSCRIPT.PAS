{$DEFINE DOFADE}
Unit FlScript;

interface

Uses flobjects,flmain,locview,fx_form;

Var loc_id:tlocrec;
    Switches:TSwitches;
    dofadeloc:boolean;
    ScriptSize,StartSize:LongInt;
    Turns:longint;

    Procedure Init(P:PProcessBar; Name:string;var F:Text);
    procedure Load(Name:string);
    Procedure Done;
    Procedure UpDateLocation(Loc:PLocation);
    Procedure Go(Dir:flobjects.TString);
    Procedure Look;

implementation

Uses objects,swset,strconst,kernel,TPStr,Constants,
     TPParam,FlashCom,TPTimeLine,core,misc,flgraph,
     flaction,textlib,fx_init,fx_mouse,fx_dev,
     fx_pens,status,grConst,things;

procedure Load(Name:string);
 var p:pdosstream;
begin
 new(p,init(Name,stOPENREAD));

  FlashMake:=MakeCommand;
  FlashCond:=IfCommand;

  player^.restore(P^);
  atmo^.restore(p^);
  thinglist^.restore(p^);
  loclist^.restore(p^);
  actlist^.restore(p^);
  humanlist^.restore(p^);

  CurrentLoc:=PLocation(LocList^.Find(Player^.Place));
  LastLoc:=CurrentLoc;
  If CurrentLoc=nil then ErrorMSG('Player place undefined');

 done_thinger;
 init_thinger;
 updatelocation(currentloc);
 Atmo^.Timeline^.ProcessEvents;

 dispose(p,done);
end;

Procedure Init(P:PProcessBar; Name:string;var F:Text);
begin
 StartSize:=Memavail;
 (* marking system procedures *)
 FlashMake:=MakeCommand;
 FlashCond:=IfCommand;
 (* exracting name of dat file *)
 BaseName:=Name;
 (* opening database *)
 Assign(F,BaseName);
 {$I-} Reset(F); {$I+}
 If IOResult<>0 then FatalMSG(Str2Pchar('Can`t find '+BaseName));
 (* reading main switches *)
 ConfigureSwitches(Switches,F);
 (* reading all database *)
 InitFile(P,F);
 Close(F);
 (* output system information *)
 ScriptSize:=StartSize-MemAvail;
 ScenSize := ScriptSize;
 Formtopics(BaseName);
end;

Procedure Done;
begin
 EndTopics;
 DoneAll;
 Done_Main;
end;

Procedure Go(Dir:flobjects.TString);
begin
 if LocList^.Find(DIR)=nil then ErrorMSG(cNoSuchOut);
 LastLoc:=CurrentLoc;
 CurrentLoc:=PLocation(LocList^.Find(Dir));
 Player^.Place:=CurrentLoc^.Name;
 UpdateLocation(CurrentLoc);
end;

const frame_showed : boolean = false;

(* text mode procedures *)
Procedure UpDateLocation(Loc:PLocation);
var a:integer;
    h:boolean;
    frame:pdevice;
    p:pcolorpen;
begin
 if dofadeloc then Palette^.fadeto(Black^,cFadeTime);
 remove_all;
 loc2locrec(loc,loc_id);

 hide_mouse;
 done_status;

{ new(p,init(0));
 screen^.map( 0,0,259,174, p );
 dispose(p,done);}

 show_locrec(loc_id,screen);
 if not frame_showed then begin
  frame:=new(PDEVICE,load(res^.loadres('FRAME')^));
  frame^.fulldevicecopy0(0,0,screen);
  dispose(frame,done);
  frame_showed := true;
 end;
 init_status;
 statusline(MousePosX,MousePOSY);
 show_mouse;

 if dofadeloc then Palette^.fadefrom(Black^,cFadeTime);
end;

Procedure Look;
begin
 dofadeloc:=false;
 UpdateLocation(CurrentLoc);
 dofadeloc:=true;
end;


end.

