Unit Status;

interface

uses fx_dev;

procedure init_status;
procedure done_status;
function dostatus(line:string):pdevice;
procedure statusline(cx,cy:word);
procedure string2status(name:string);

implementation

Uses misc,data,kernel,core,streams,things,flgraph,types,
     fx_mouse,fx_pens,fx_types,flscript,flaction,
     fx_fonts,fx_pal,res_type,fx_shape,constants,flashcom,
     sysinfo,time,fx_init,imgstack,flobjects,locview,buttons,glass;

 var statusdata:record
      store:pdevice;
      line:string;
     end;

procedure init_status;
begin
 if StatusData.Store<>nil then Exit;
 new(statusdata.store,init(cStatus.w,cStatus.H));
 statusdata.line:='';
 hide_mouse;
 screen^.partdevicecopy(0,0,cStatus.x,cStatus.y,cStatus.w,cStatus.h,statusdata.store);
 show_mouse;
end;
procedure done_status;
begin
 If StatusData.Store=Nil then Exit;
 dispose(statusdata.store,done);
 Statusdata.store:=nil;
end;

function dostatus(line:string):pdevice;
 var p:pdevice;
     mlen:integer;
     s:word;
begin
 asm
  mov s,si
 end;

 {$IFDEF MEMSTAT}
 line:= 'SI='+tostr(s)+' HEAP='+tostr(memavail)+' XMS='+tostr(xms_memavail)+
	' EMS='+tostr(ems_memavail);
 {$ENDIF}

 new(p,init(cStatus.w,cStatus.h));
 statusdata.store^.fulldevicecopy(0,0,p);
 mlen:=(cStatus.w - LightFont^.lnWidth(line)) div 2;
 if mlen<0 then mlen:=0;
 LightFont^.Writelen( mlen,(cStatus.h - LightFont^.lnHeight) div 2,
                      cStatus.w, p, Line );
 dostatus:=p;
end;

procedure statusline(cx,cy:word);
 var p:pdevice;
     name:string;

begin
 name:='';
 if cVIEW.contains(cx,cy)
 then name:=get_name(cx,cy,loc_id)
 else if in_buttons(cx,cy)
      then name:=buttons_text(cx,cy)
      else if cDREAMS.contains(cx,cy)
           then name:='Пpезентация этой игpы'
           else if cWIZECORE.contains(cx,cy)
                then name:='О создателях игpы'
                else if in_thingbar(cx,cy) then begin
                 name:=name_thingbar(cx,cy);
                 if findin(name)=nil
                 then name:=''
                 else name:=findin(name)^.playname;
                end;

 if name<>statusdata.line
 then begin
  hide_mouse;
  p:=dostatus(name);
  p^.fulldevicecopy(cStatus.x,cStatus.y,screen);
  dispose(p,done);
  show_mouse;
  statusdata.line:=name;
 end;
end;

procedure string2status(name:string);
 var p:pdevice;
begin
 p:=dostatus(name);
 p^.fulldevicecopy(cStatus.x,cStatus.y,screen);
 dispose(p,done);
end;

begin
 Statusdata.store:=nil;
 Statusdata.line:='Dummy status line';
end.
