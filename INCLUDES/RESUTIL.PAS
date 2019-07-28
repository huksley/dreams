{ show dev in center if it smaller or equ than at,
  or cut to fit if larger }
procedure show_at(dev:pdevice; at:viewrec; screen:pdevice);
 var actx,acty,actw,acth:word;
begin
 if (at.w<=dev^.width) and
    (at.h<=dev^.height) then
 begin
  actx:= at.x + (at.w-dev^.width) div 2;
  acty:= at.y + (at.h-dev^.height) div 2;
  dev^.fulldevicecopy(actx,acty,screen);
 end else begin
  actw:=at.w; acth:=at.h;
  dev^.partdevicecopy(at.x,at.y,0,0,actw,acth,screen);
 end;
end;

procedure showresdev(name:string; at:viewrec;screen:pdevice);
 var image:pdevice;
begin
 new(image,load(res^.loadres(name)^));
 show_at(image,at,screen);
 dispose(image,done);
end;
