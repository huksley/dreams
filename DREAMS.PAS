{$IFNDEF WINDOWS}
{$DEFINE DOSAPP}
{$ENDIF}
{$IFDEF DOSAPP}
{╔═════════════════════════════════════════════════════╗
 ║Имя пpоекта ................. "Эхо снов"             ║
 ║Кодовое имя пpоекта ......... "Dreams"               ║
 ║Дата начала ................. 31-12-95               ║
 ║Пpиблизительная дата конца .. 31-12-97               ║
 ╚═════════════════════════════════════════════════════╝ }
Program DREAMS; { graphic mode interface }
{$A+,B-,D+,E+,G+,I+,L+,P+,S-,V+,X+,Y+,T+,N+,F+,P+,G+,Q-,R-,O-}
{$M 65520,1000,655000}
{$DEFINE DEBUG}
{.$DEFINE DOGLASS}
{$DEFINE MEMSTAT}
{$DEFINE DOTEXT}
uses { core modules }
     swset,kernel,start,streams,types,misc,core,objects,tpdos,fx_file,
     { constants modules }
     data,strconst,constants,plbuffer,
     { script-related }
     tpstr,tpparam,flashcom,tptimeline,
     flobjects,flaction,flmain,textlib,flscript,
     { fx-api }
     fx_mouse,fx_pens,fx_dev,fx_types,fx_fonts,fx_pal,
     fx_shape,fx_init,imgstack,fx_form,flplay,
     { resource-file }
     res_type,paths,
     { main engine }
     locview,flgraph,acting,things,status,buttons,menu,
     { sound engine }
     play,vdialog,fontedit,GrConst,sounds;

var Switches:PSwitchBoard;

    procedure init_switches;
    begin
     New(Switches,Init('Установки пpогpаммы'));
     Switches^.AddSwitch(DebugMode,'Режим отладки пpогpаммы',@DebugMode);
     Switches^.AddSwitch(ShowLoadObjects,'Показывать пpоцесс загpyзки',@ShowLoadObjects);
     Switches^.AddSwitch(DynamicExit,'Пpоизводить стандаpтный выход',@DynamicExit);
{     Switches^.AddSwitch(SoundEnabled,'Звyковые эффекты',@SoundEnabled);}
     Switches^.AddSwitch(CloseStandartIO,'Закpывать стандаpтные файлы',@CloseStandartIO);
    end;
    procedure run_switches;
    begin
     Switches^.run;
    end;
    procedure done_switches;
    begin
     Dispose(Switches,Done);
    end;

const
      cLOADSCR_STR   = 'Загpyзка...';
      cLOADSCR_PEN   = 45;
      cLOADSCR_LEN   = 200;
      cLOADSCR_WID   = 15;

var l:longint;

procedure RestoreDef;
begin
 Palette^.Apply;
end;

procedure initgame;
var  f:text;
     p:pprocessBar;
begin
 New(P,init( New(PColorPen,init(cLOADSCR_PEN)), 0,l,cLOADSCR_LEN,cLOADSCR_WID, cLOADSCR_STR ));
 Palette^.Apply;
 P^.Center;
 flscript.init(p,ScriptFile,f);
 assign(f,Scriptfile);
 reset(f);
 LoadNames(f);
 close(f);
 Dispose(P,Done);
 init_thinger;
 dofadeloc:=false;
 Black^.Apply;
 updatelocation(currentloc);
 palette^.FadeFrom(Black^,cFadeTime);
 dofadeloc:=true;
 runpart^.run;
 Atmo^.Timeline^.ProcessEvents;
end;

procedure donegame;
begin
 flscript.done;
 done_thinger;
end;

procedure done;
begin
 donegame;
 Hide_Mouse;
 DefaultIO;
 done_status;
 clearKBD;
 donedialogs;
 done_switches;
 sounddone;
 initiate_exit;
end;


var
    menu_stat : record
     size:integer;
     list:itemlist;
    end;


const
     cMenuStart = 'MenuStart';
     cMenuEnd   = 'MenuStop';

procedure init_menu(Var F:Text);
 var txt:pStringArr;
begin
 txt:=nil;
 menu_stat.size:=0;
 While not eof(f) do
 begin
  if Same(ReadStrf(f),cMenuStart)
  then begin
   new(txt,init);
   txt^.readto(F,cMenuEnd);
   Break;
  end;
 end;
 if txt<>nil then begin
  menu_stat.size:=menu.unpack_arr(txt,menu_stat.list);
  dispose(Txt,Done);
 end;
end;

procedure ShowMenu;
begin
 if menu_stat.size<>0 then begin
  showItems(menu_stat.list,menu_stat.size);
 end;
end;


procedure init;
 var a:integer;
     s:string[15];
     f:text;
begin
 Randomize;
 {$IFDEF DPMI}
 Writeln('DOS Protected mode application');
 {$ELSE}
 Writeln('DOS Real mode application');
 Writeln('Warning ! Some functions are not available');
 {$ENDIF}
 init_api(ResourceFile);
 PreError:=RestoreDef;
 init_forms;
 soundInit;
 init_buffer;
 offcountmsg;

 cleargr;
 clearinput;
 palette^.apply;

 {$IFDEF DOTEXT}
 images^.center(texture,screen);
 {$ENDIF}

 init_main;

 if ExistFile(ScriptFile)
 then begin
  Assign(F,ScriptFile);

  Reset(F); Init_menu(f); Reset(f);
  Reset(F); buttons_init(f); Reset(F);
  Reset(F); init_dialogs(f); Reset(F);

  l:=TextFileSize(F);
  Close(F);
 end else l:=0;

 GOProc:=Go; LookAtProc:=Look;
 ExitProcedure:=Done; ScenSize:=ScriptSize;
 ChooseFunc:=ChooseThing;
 ShowMenuProc:=ShowMenu;
 SwitchEditProc:=run_switches;

 Black^.Apply;
 showtaken:=take_thing;
 images^.show(menu_dev,sidex,sidey,screen);
 show_buttons;
 init_switches;
 {dshow_em(100,screen);}
 initgame;
end;


procedure DreamsLogoShow;
begin
 freeze_hands;
 clearinput;
 aboutmenu;
 unfreeze_hands;
end;

procedure WizeLogoShow;
begin
 freeze_hands;
 clearinput;
 wizemenu;
 unfreeze_hands;
end;

procedure ProcessViewClick(x,y:integer; b:byte);
 var dir:boolean;
begin
              clearinput;
              dir:=is_dir(x,y,loc_id);
              case b of
               01: if dir
                   then begin
                         done_status;
                         freeze_hands;
                         dirdefaultact(get_find(x,y,loc_id));
                         unfreeze_hands;
                         init_status;
                        end
                   else begin
                    freeze_hands;
                    act_default(PFlashCommon(findin(get_find(x,y,loc_id))));
                    unfreeze_hands;
                   end;
               02: if dir
                   then
                   else begin
                    freeze_hands;
                    act_list(PFlashCommon(findin(get_find(x,y,loc_id))));
                    unfreeze_hands;
                   end;
              end;

end;
procedure ProcessButtonsClick(x,y:integer);
begin
 freeze_hands;
 buttons_click(x,y);
 unfreeze_hands;
end;

procedure ProcessThingBar(x,y:integer; b:byte);
begin
 freeze_hands;
 clearinput;
 do_thingbar(b,x,y);
 unfreeze_hands;
end;

 var i:integer;
     b:byte;
     dir:boolean;
     x,y:word;

begin
 InitLoad:=False;
 init;


 x:=mouseposx;
 y:=mouseposy;

 While not altx_pressed do
 begin

  if (mouseposx<>x) or (mouseposy<>y)
  then begin
   x:=mouseposx; y:=mouseposy;
   StatusLine(x,y);
  end;

  b:=MouseButtons;

  if b<>0
  then if cDREAMS.contains(x,y)
       then DreamsLogoShow
       else if cWIZECORE.contains(x,y)
            then WizeLogoShow
            else if cVIEW.contains(x,y)
                 then ProcessViewClick(x,y,b)
                 else if in_buttons(x,y)
                      then ProcessButtonsClick(x,y)
                      else if in_thingbar(x,y)
                           then ProcessThingBar(x,y,b)
                           else ClearInput;
 end;
 done;
end
{$ELSE}
 Uses WinCrt;
 begin
  Writeln('This program is not compilable for windows');
 end
{$ENDIF}.


