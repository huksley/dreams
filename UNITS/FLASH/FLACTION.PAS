Unit FlAction;
{$DEFINE NOIOSYS}

InterFace

 Uses flobjects,types;

 type TGoProc=procedure(Dir:flobjects.TString);
      TFindProc=procedure(find:string);
      TProc=procedure;
      TChooseFunc=function:nstring;
const
     cCHOOSE_INFO:string = 'Выбеpите пpедмет';
     cPAR_PREFIX = 'PAR';

var Quered:string;
    SaveName:string;
    InitLoad:boolean;

 Var GoProc:TGOProc;
     LookAtProc:TProc;
     ExitProcedure:TProc;
     ScenSize:Longint;
     ShowTaken:TFindProc;
     ChooseFunc:TChooseFunc;
     CurrentThing:NString;
     ShowMenuProc:TProc;
     SwitchEditProc:TProc;

procedure GlobVarReplace(Var CMD:String);
Procedure LocalMacReplace(var Pars:String);
Procedure MakeCommand(Id:Integer; Pars:String);
Function IfCommand(Id:Integer; Pars:String):boolean;

Implementation

 uses objects,fx_strop,tpparam,tpstr,locview,
      tptimeline,flashcom,
      constants,streams,tpcomms,core,
      fx_mouse,flgraph,
      kernel,things,tpdos,play,sounds,
      misc,textlib,fx_init,vdialog,fx_cons,
      fx_form,flscript,talks,fontedit,strings
      {$IFDEF DPMI} ,winapi,appdll;
      {$ELSE} ; {$ENDIF}


{$I VARS.PAS}
{$I SAVES.PAS}

procedure comm_save(s:string);
 var p:pdosstream;
begin
 new(p,init(s,stCREATE));
  player^.save(p^);
  atmo^.save(p^);
  thinglist^.save(p^);
  loclist^.save(p^);
  actlist^.save(p^);
  humanlist^.save(p^);
 dispose(p,done);
end;
procedure comm_load(s:string);
begin
 If ExistFile(s) then begin
  Load(s);
 end else Message('You weren`t save game in this slot');
end;
procedure comm_newg(s:string);
begin
 {$IFDEF NOIOSYS}
  Message('Newgame system is in beta-mode now');
 {$ENDIF}
end;

procedure comm_i2p(s:string);
begin
 control_var(argument(s,0)+' '+findin(argument(s,1))^.playname);
end;

procedure comm_savepr(s:string);
begin
 control_var(s+' '+SaveFile(SavePrompt));
end;
procedure comm_swedit(s:string);
begin
 SwitchEditProc;
end;
procedure comm_waitaud(s:string);
begin
 WaitSound;
end;
procedure comm_playsnd(s:string);
begin
 PlaySound(S);
end;
Procedure comm_shmenu(s:string);
begin
 SHowMenuProc;
end;
Procedure comm_diarun(s:string);
begin
 freeze_hands;
 dodialog(Argument(s,0));
 unfreeze_hands;
end;
procedure Comm_fonted(s:string);
begin
 FontEditor;
end;
procedure Comm_listtopics(s:string);
begin
 list_topics;
end;

Procedure LocalMacReplace(var Pars:String);
begin
 fx_strop.Replace('CurrentLoc',CurrentLoc^.Name,Pars);
 fx_strop.Replace('LastLoc',LastLoc^.Name,Pars);
 fx_strop.replace('CurrentThing',CurrentThing,Pars);
 fx_strop.Replace('#player',Player^.Name,Pars);
 fx_strop.Replace('#atmo',Atmo^.Name,Pars);

 fx_strop.replace('#hour',ToStr(Atmo^.Timeline^.Hour),Pars);
 fx_strop.replace('#day',ToStr(Atmo^.TimeLine^.day),Pars);
 fx_strop.replace('#month',ToStr(Atmo^.TimeLine^.month),Pars);
 fx_strop.replace('#year',ToStr(Atmo^.TimeLine^.year),Pars);

{ fx_strop.replace('',,Pars);}

 fx_strop.replace('#emsfree',tostr(ems_memavail div 1024),Pars);
 fx_strop.replace('#xmsfree',tostr(xms_memavail div 1024),Pars);
 fx_strop.replace('#memfree',tostr(memavail div 1024),Pars);
 fx_strop.replace('#diskfree',tostr(disk_memavail div 1024),Pars);
 fx_strop.replace('#diskfree',tostr(disk_memavail div 1024),Pars);

 fx_strop.replace('#idrecord',Switches.idrecord,Pars);
 fx_strop.replace('#copyright',Switches.copyright,Pars);
 fx_strop.replace('#year',Switches.year,Pars);
 fx_strop.replace('#version',Switches.version,Pars);
 fx_strop.replace('#minorver',Switches.minorversion,Pars);
 {$IFDEF DPMI}
 fx_strop.replace('#apptype','dpmi',Pars);
 {$ELSE}
 fx_strop.replace('#apptype','real',Pars);
 {$ENDIF}
 fx_strop.replace('#scenario',TOStr(ScenSize),Pars);

 fx_strop.Replace('#query',Quered,Pars);
 GlobVarReplace(Pars);
end;

Procedure comm_Beep(s:string);
begin
 Writeline('BEEP');
end;
Procedure comm_Message(s:string);
begin
 Writeline(s);
end;
procedure comm_showit(s:string);
begin
 show_text;
end;
Procedure comm_Pause(s:String);
begin
 anyclick;
end;
Procedure comm_go(s:string);
begin
 if LocList^.Find(s)<>nil
 then GoProc(s)
 else begin
  Message('Can`t go there - location not exist');
  updatelocation(currentloc);
 end;
end;

Procedure comm_console(s:string);
begin
 Show_console;
end;

Procedure comm_die(s:string);
begin
 LastLoc:=CurrentLoc;
 CurrentLoc:=PLocation(LocList^.Find('Void'));
 If Not Assigned(CurrentLoc) then FatalMSG('Can`t find void location');
 Player^.Place:='Void';
 UpdateLocation(CurrentLoc);
end;
procedure comm_topic(s:string);
begin
 printtopic(s);
end;
Procedure comm_field(s:string);
 var name:string;
     field:string;
     value:string;
     obj:Pointer;
begin
 Name:=Argument(s,0);
 Field:=Argument(s,1);
 Value:=Copy(s,Pos(Field,s)+Length(Field)+1,255);

 Obj:=FindIn(Name);
 if Assigned(Obj) then PFlashObject(Obj)^.chField(Field,Value)
 else Message('Can`t find object '+Name);
end;
procedure comm_year(s:String);
begin
 Atmo^.TimeLine^.Year:=ToWord(s);
end;
Procedure comm_month(s:string);
begin
 Atmo^.TimeLine^.Month:=ToWord(S);
end;
Procedure Comm_Day(S:string);
begin
 Atmo^.TimeLine^.Day:=ToWord(S);
end;
Procedure Comm_Hour(S:string);
begin
 Atmo^.TimeLine^.Hour:=ToWord(S);
end;
Procedure comm_showtime(s:string);
begin
 Message(Atmo^.TimeLine^.ShowTime);
end;
Procedure comm_hinc(s:string);
begin
 Atmo^.TimeLine^.IncHour(1);
end;
Procedure comm_dinc(s:string);
begin
 Atmo^.TimeLine^.IncTime(0,0,1,0);
end;
Procedure comm_currevent(s:string);
 var i:integer;
begin
 Writeline('Current underway events');
 for i:=0 to Atmo^.Timeline^.Count-1 do
  if Atmo^.TimeLine^.CheckEvent(Atmo^.TimeLine^.Get(i)^.Event)
  then Writeline(Atmo^.TimeLine^.Get(i)^.Event);
 Show_text;
end;
Procedure comm_offevent(s:string);
 var p:PTimeUnit;
begin
 P:=Atmo^.TimeLine^.SearchEvent(s);
 if Not Assigned(P)
 then ErrorMSG(Str2Pchar('Cannot be found event to turn off:'+s))
 else P^.Year:=1;
end;
Procedure comm_query(s:string);
begin
 Quered:=Receive(S);
end;
Procedure comm_mem(s:string);
begin
 Message('Free memory on-host available: '+TOSTR(MemAvail div 1024)+' Kbytes')
end;
Procedure comm_look(s:string);
begin
 LookAtProc;
end;
Procedure comm_resstr(s:string);
 var p:PFlashObject;
begin
 p:=findin(s);
 if p=nil then quered:='no such object'
          else quered:=p^.reskey;
end;
procedure comm_act(s:string);
 var name:string;
     value:string;

     obj:PAct;
begin
 Name:=Argument(s,0);
 Value:=Copy(s,Pos(Name,s)+Length(Name)+1,255);
 obj:=PAct(ActList^.Find(Name));
 obj^.run(Value);
end;
procedure comm_choice(s:string);
 var butt:pbutton_line;
     a,b,i:integer;
begin
 a:=arguments(s); if (a mod 2) <> 0
 then Message('Incorrect number of args in choice')
 else begin
  a:=a div 2;
  if a>10 then a:=10;
  new(butt,init(a,menumaxlen,argument(s,0)));
   for b:=0 to a-1 do butt^.add_butt(argument(s,b*2+1));
   hide_mouse;
   butt^.center;
   show_mouse;
   while true do
    if mousebuttons<>0 then begin
     i:=butt^.pressed(mouseposx,mouseposy);
     if i<>-1 then begin
      playSound(sndClick);
      quered:=argument(s,i*2+2);
      break;
     end;
     while mousebuttons<>0 do;
   end;
  while mousebuttons<>0 do;
  hide_mouse;
  dispose(butt,done);
  show_mouse;
 end;
 while mousebuttons<>0 do;
end;
procedure comm_newname(s:string);
 var name:string;
begin
 if Argument(s,0)<>'' then name:=Argument(s,0) else
 begin
  name:=Receive('Your name?>');
 end;
 Player^.Name:=name; Player^.PlayName:=Name;
end;
procedure comm_exit(s:string);
begin
 ExitProcedure;
end;
procedure comm_log(s:string);
 var f:text;
begin
 loggy(cFILENAME,S)
end;
procedure comm_move(s:string);
 var name:string;
     tipe:tclassid;
     Kind:pFlashObject;
     par:string;
begin
 tipe:=strToClassId(argument(s,0));
 name:=argument(s,1);
 par:=argument(s,2);
 Kind:=findin(name);
 if Kind=nil then FatalMSG(Str2Pchar('cant find in move:'+s));
 case tipe of
  nPlayer  : quered:=PPLayer(Kind)^.params^.value(par);
  nAtmo    : quered:=PATmo(Kind)^.params^.value(par);
  nLoc     : quered:=PLocation(Kind)^.params^.value(par);
  nThing   : quered:=PThing(Kind)^.params^.value(par);
  nHuman   : quered:=PHuman(Kind)^.params^.value(par);
 end;
end;

procedure comm_pick(s:string);
 var res:string;
     name:string;
     value:string;
begin
 Name:=Argument(s,0);
 Value:=Copy(s,Pos(Name,s)+Length(Name)+1,255);
 if Value<>'' then cCHOOSE_INFO:=Value;

 Res:=ChooseFunc;

 if res<>'' then begin

   if Same(Name,'Query')
   then Quered:=res
   else control_var(Name+' '+Res);

 end else Quered:='VOID';
end;

procedure comm_hide(s:string);
begin
 hide_find(s,loc_id,screen);
 showtaken(s);
end;

procedure comm_toplayer(s:string);
begin
 showtaken(s);
end;
procedure comm_dllrun(s:string);
 {$IFNDEF DPMI}
  begin
   ErrorMSG('Can`t run dll from not a DPMI app');
  end;
 {$ELSE}
  var index:integer;
begin
 index:=ToInt(S);
 If Not Belongs(Index,1,10)
 then Message('Only external functions with indexes 1..10 are allowed')
 else AppDll.CallExternal(Index);
end;
 {$ENDIF}

Procedure MakeCommand;
 var Comm:PCommands;
     i:integer;
begin
 LocalMacReplace(Pars);
 if Id=-1 then ErrorMSG('Can`t run act(-1)');
 Comm:=Player^.Acts^.GetName(ActName[Id]);
 if Comm<>nil then begin
  for i:=0 to Arguments(Pars) do
      control_var(cPAR_PREFIX+tostr(i)+' '+Argument(Pars,i));
  LocalMacReplace(Pars);
  Comm^.Run;
 end else MakeComm(Id,Pars);
end;

Function cond_debug(s:string):boolean;
begin
 cond_debug:=true;
end;
Function cond_event(s:string):boolean;
begin
 cond_event:=Atmo^.Timeline^.checkevent(Argument(S,0));
end;
function cond_equal(s:string):boolean;
begin
 cond_equal:=Same(argument(s,0),argument(s,1));
end;
function cond_check(s:string):boolean;
 var s1:string;
     p:pFlashCommon;
begin
 cond_check:=false;
 p:=PFlashCommon(findin(argument(s,0)));
 if p<>nil then
 begin
  if P^.acts^.getname(argument(s,1))<>nil
  then cond_check:=true;
 end;
end;
Function cond_field(s:string):boolean;
 var name:string;
     field:string;
     value:string;
     obj:Pointer;
begin
 Name:=Argument(s,0);
 Field:=Argument(s,1);
 Value:=Copy(s,Pos(Field,s)+Length(Field)+1,255);

 obj:=FindIn(Name);
 if Obj=nil then ErrorMSG(Str2PChar('Cant find '+Name));
 cond_field:=PFlashObject(Obj)^.ifField(Field,Value);
end;
Function cond_here(s:string):boolean;
begin
 cond_here:=CurrentLoc^.Things^.Search(s)<>-1;
end;
Function cond_place(s:string):boolean;
begin
 cond_place:=Same(CurrentLoc^.Name,s)
end;
Function cond_quer(s:string):boolean;
begin
 cond_quer:=same(s,quered);
end;
function cond_real(s:string):boolean;
begin
 {$IFDEF DPMI}
 cond_real:=false;
 {$ELSE}
 cond_real:=true;
 {$ENDIF}
end;
function cond_dpmi(s:string):boolean;
begin
 {$IFDEF DPMI}
 cond_dpmi:=true;
 {$ELSE}
 cond_dpmi:=false;
 {$ENDIF}
end;
Function IfCommand;
 var Name,Params:string;

begin
 if Pars[1]='~'
 then IfCommand:=Not IfCommand(Id,Copy(Pars,2,255))
 else begin
  LocalMacReplace(Pars);
  IfCommand:=MakeCond(Id,Pars);
 end;
end;

procedure comm_rething(s:string);
begin
 refresh_thinger;
end;

{$I acttalk.pas}

begin
 init_globvars;
 AppendComm('beep',comm_Beep);
 AppendComm('message',comm_Message);
 AppendComm('pause',comm_pause);
 AppendComm('go',comm_go);
 AppendComm('field',comm_field);
 AppendComm('year',comm_year);
 AppendComm('month',comm_month);
 AppendComm('day',comm_day);
 AppendComm('hour',comm_hour);
 AppendComm('showtime',comm_showtime);
 AppendComm('hourinc',comm_hinc);
 AppendComm('dayinc',comm_dinc);
 AppendComm('currevents',comm_currevent);
 AppendComm('offevent',comm_offevent);
 AppendComm('die',comm_die);
 AppendComm('query',comm_query);
 AppendComm('freemem',comm_mem);
 AppendComm('look',comm_look);
 AppendComm('changename',comm_newname);
 AppendComm('showtopic',comm_topic);
 AppendComm('runact',comm_act);
 AppendComm('choice',comm_choice);
 AppendComm('transfer',comm_move);  { transfer TOM time }
 AppendComm('exit',comm_exit);
 AppendComm('logstring',comm_log);
 AppendComm('showit',comm_showit);
 AppendComm('stackres',comm_resstr);
 AppendComm('takeobj',comm_hide);
 AppendComm('freshthings',comm_rething);
 Regist_TALK;
 { New Commands }
 { Пpосит пользователя выбpать пpедмет }
 { пеpвый паpаметp - пеpеменная или QUERY }
 AppendComm('pickthing',comm_pick);
 { Кладет вещь в меню вещей игpока }
 { Hе пеpемещает ее }
 AppendComm('taketoplayer',comm_toplayer);
 { Упpавление пеpеменными }
 { Var Size 10  }
 { Message $SIZE }
 { Выводит "10" }
 AppendComm('var',control_var);
 { Запpашивает пpомпт файла }
 AppendComm('fileprompt',comm_savepr);
 AppendComm('savegame',comm_save);
 AppendComm('loadgame',comm_load);
 AppendComm('newgame',comm_newg);
 { Показывает меню игpока }
 AppendComm('showmenu',comm_shmenu);
 { Выводит yказанный диалог на экpан }
 { Сохpаняет pезyльтат диалога в QUERY }
 AppendComm('dialog',comm_diarun);
 { Выводит диалог изменения yстановок }
 AppendComm('switchedit',comm_swedit);
 AppendComm('fontedit',comm_fonted);
 { Runs dll with specified function - index }
 AppendComm('dllrun',comm_dllrun);
 AppendComm('waitaud',comm_waitaud);
 AppendComm('audio',comm_playsnd);
 AppendComm('console',comm_console);
 AppendComm('topics',comm_listtopics);
 AppendComm('id2play',comm_i2p);

 AppendIf('field',cond_field);
 AppendIf('debug',cond_debug);
 AppendIf('here',cond_here);
 AppendIf('place',cond_place);
 AppendIf('event',cond_event);
 AppendIf('entered',cond_quer);
 AppendIF('equal',cond_equal);
 AppendIF('check',cond_check);
 AppendIF('isreal',cond_real);
 AppendIF('isdpmi',cond_dpmi);
end.
{ field objname <field> value }
