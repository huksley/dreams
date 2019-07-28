Unit fx_init;

interface

Uses misc,core,kernel,streams,objects,
     fx_mouse,fx_pens,fx_dev,fx_types,
     fx_fonts,fx_pal,res_type,fx_shape,
     sysinfo,time,imgstack;

const ShortInit : boolean = false;

var Palette,Black:PPaletteDevice;
    Screen:PDevice;
    LightFont,DarkFont:PFont;
    res:pres_file;
    texture:byte;
    images:pimage_stack;

procedure setcur(x,y,x1,y1:word; resname:string);

 procedure init_res(resfile:string);
  function loaddev(resname:string):byte;
 procedure done_res;

 procedure done_graph;
 procedure init_graph;

 procedure init_mouse;

 function check_system:boolean;
 function check_resfile(filetocheck:string):boolean;

 function anyclick:boolean;
 procedure cleargr;

procedure init_api(resfile:string);

implementation
 Uses swset,data,flplay,paths,tpdos,grConst;

const
  cCPU        = cpu80386;
 {$IFDEF DPMI}
  cEMS_kbytes = 0;
  cXMS_kbytes = 0;
  cSWP_kbytes = 0;
  cMEM_kbytes = 2048;
 {$ELSE}
  cEMS_kbytes = 0;
  cXMS_kbytes = 1024;
  cSWP_kbytes = 1024;
  cMEM_kbytes = 200;
 {$ENDIF}


 function LoadDev(resname:string):byte;
  var tmp:pdevice;
 begin
  new(tmp,load(res^.loadres(resname)^));
  loaddev:=images^.store(tmp);
  dispose(tmp,done);
 end;

     Procedure ReplaceColor(Var Font:PFont;col,tocol:byte);
      var a:integer;
     begin
      for a:=0 to 255 do
      if Assigned(Font^.List[a]) then Font^.List[a]^.ReplaceColor(col,tocol);
     end;


 procedure init_res(resfile:string);
  var tmp:pdevice;
 begin
  Writeln(cRES_INIT);
  new(res,init(resfile,stOpenRead,stOpenRead));
  new(screen,initat(ptr(SegA000,0),320,200));
  new(palette,fullload(res^.loadres('stPALETTE')^));
  new(lightfont,load(res^.loadres('stFONT')^));
  replacecolor(lightfont,font_col.curr,font_col.light);
  new(darkfont,load(res^.loadres('stFONT')^));
  replacecolor(darkfont,font_col.curr,font_col.dark);
  new(black,init(0,0,0));
  new(images,init);
  texture:=Loaddev('stTEXTURE');

{  Writeln('init_resource');}
  add_exit_proc(@done_res);
 end;

 procedure done_res;
 begin
  Writeln(cRES_DONE);
  dispose(screen,done);
  dispose(palette,done);
  dispose(lightfont,done);
  dispose(darkfont,done);
  dispose(black,done);
  dispose(res,done);
  dispose(images,done);
 end;

 procedure done_graph;
 begin
  initTextmode;
  Writeln(cVga_DONE);
 end;
 procedure init_graph;
 begin
  Writeln(cVGA_INIT);
  if DoFading then FadeText;
  InitVGAmode;
   black^.apply;
  if DOFading then begin
    Palette^.fadefrom(black^,cFadeTime);
    palette^.apply;
  end;
  add_exit_proc(@done_graph);
 end;

 procedure init_mouse;
  var cursor:pcursor;
 begin
  new(cursor,load(res^.loadres('stCURSOR')^));
  InitMouseHandler(Cursor);
  add_exit_proc(@DoneMouseHandler);
 end;


 function check_mouse:boolean;
  var a:word;
 begin
  asm
   mov ax,0
   int 33h
   mov a,ax
  end;
  check_mouse:=a=$FFFF;
 end;

function check_system:boolean;

 var    cputype:cpu;
   {$IFNDEF DELPHI}
    Var Result:boolean;
   {$ENDIF}

begin
 result:=true;
 if not DoStartChecking then  begin
  Writeln('Warning !!! System check have been disabled');
  Writeln('Incorrect configuration may cause program to run unpredictably !!!');
  Writeln('[press any key]');
  readkey;
  Exit;
 end;

 cputype:=GetCPUtype;
 Writeln('Performing system test...');
 { performing CPU test }
 Write('CPU found ',CPUName[CPUType],', need ',CPUName[cCPU],', ');
 if CPUType>=cCPU
 then Writeln('OK.')
 else begin
  result:=false;
  Writeln('Error.');
 end;
 {$IFDEF DPMI}
 Write('Memory found ',memavail div 1024,'k, need ',cMem_kbytes,'k, ');
 if (MemAvail div 1024) >= cMEM_kbytes
 then Writeln('OK.')
 else begin
  result:=false;
  Writeln('Error.');
 end;
 {$ELSE}
 { searching for free ems memory }
 Write('EMS found ',EMS_memavail div 1024,'k, need ',cEMS_kbytes,'k, ');
 if (EMS_MemAvail div 1024) >= cEMS_kbytes
 then Writeln('OK.')
 else begin
  result:=false;
  Writeln('Error.');
 end;
 { counting free xms memory }
 Write('XMS found ',XMS_memavail div 1024,'k, need ',cXMS_kbytes,'k, ');
 if (XMS_MemAvail div 1024) >= cXMS_kbytes
 then Writeln('OK.')
 else begin
  result:=false;
  Writeln('Error.');
 end;
 {$ENDIF}
 { searching free disk space }
 Write('HARD space found ',DISK_Memavail div 1024,'k, need ',cSWP_kbytes,'k, ');
 if (DISK_MemAvail div 1024) >= cSWP_kbytes
 then Writeln('OK.')
 else begin
  result:=false;
  Writeln('Error.');
 end;

 result:=result and check_mouse;
 if check_mouse
 then Writeln('Mouse driver found, OK.')
 else Writeln('Mouse driver not found, Error.');

 if result
 then Writeln('System have correct configuration, running program...')
 else Writeln('Correct system configuration and run again.');

 check_system:=result;
end;


 function check_resfile(filetocheck:string):boolean;
 begin
  check_resfile:=existfile(filetocheck);
 end;

 function anyclick:boolean;
 begin
  while (not keypressed) and (mousebuttons=0) do;
  case MouseButtons of
   01 : AnyClick:=True;
   02: AnyClick:=False;
  end;
  if keypressed then readkey;
  while mousebuttons<>0 do;
 end;
 procedure cleargr;
  var p:pcolorpen;
 begin
  new(p,init(0));
  screen^.clear(p);
  dispose(p,done);
 end;


procedure init_api(resfile:string);
begin
 Writeln;
 Writeln(cDreamsLine);
 Writeln;
 Writeln(cSwitchNotify);

 if not check_system
 then begin
  Writeln(cDoingExit);
  Halt;
 end;
 if Keypressed and (Readkey=' ') then Readkey;

 if not check_resfile(resfile)
 then begin
  Writeln(cCantFindRes,resfile);
  Halt;
 end;

{ ----- system checked successfully ------ }
 init_res(resfile); init_graph;
 init_mouse;
{ ----- system inited successfully ------ }
end;

procedure setcur(x,y,x1,y1:word; resname:string);
 var
     p:pcursor;
begin
 new(p,load(res^.loadres(resname)^));
 put_handler(p,x,y,x1,y1);
end;

end.
