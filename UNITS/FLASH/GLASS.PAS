Unit Glass;

interface

 procedure do_glass;
 procedure undo_glass;

implementation

Uses data,kernel,core,streams,things,flgraph,types,
     fx_mouse,fx_pens,fx_types,flscript,flaction,fx_dev,
     fx_fonts,fx_pal,res_type,fx_shape,constants,flashcom,
     sysinfo,time,fx_init,imgstack,flobjects,locview,buttons;

var save_glass:pdevice;

procedure do_glass;
 var
     glass:pconvertpen;
     temp:pdevice;
begin
 {$IFDEF DOGLASS}
 save_glass:=New(PDevice,init(cVIEW.W,cVIEW.H));
 temp:=New(PDevice,init(cVIEW.W,cVIEW.H));
 screen^.partdevicecopy(0,0,cVIEW.X,cVIEW.Y,cVIEW.W,cVIEW.H,save_glass);
 screen^.partdevicecopy(0,0,cVIEW.X,cVIEW.Y,cVIEW.W,cVIEW.H,temp);

 new(glass,init(Palette^.GlassIndex));
 hide_mouse;
 temp^.clear(glass);
 temp^.fulldevicecopy(cVIEW.X,cVIEW.Y,screen);
 show_mouse;
 dispose(glass,done);
 dispose(temp,done);
 {$ENDIF}
end;

procedure undo_glass;
begin
 {$IFDEF DOGLASS}
 hide_mouse;
 save_glass^.fulldevicecopy(cVIEW.X,cVIEW.Y,screen);
 show_mouse;
 dispose(save_glass,done);
 {$ENDIF}
end;

end.