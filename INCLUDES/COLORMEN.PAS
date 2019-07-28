
procedure colormenu;

 procedure showcolor(x,y,x1,y1:word; colornum:byte);
  var c,c0:pcolorpen;
 begin
  new(c,init(colornum));
  new(c0,init(0));
   screen^.rectangle(x,y,x1,y1,c0);
   screen^.map(x+1,y+1,x1-1,y1-1,c);
   lightfont^.writeln(x+1,y+1,screen,tostr(colornum));
  dispose(c,done);
  dispose(c0,done);
 end;

 const
   cmenux=10;
   cmenuy=10;

 var
   menu:pbutton_line;
   c:byte;
   i:integer;
begin
 hide_mouse;
 clip;
 show_mouse;
 new(menu,init(4,60,'Color'));
  menu^.add_butt('more_number');
  menu^.add_butt('less_number');
  menu^.add_butt('edit_number');
  menu^.add_butt('exit');
  hide_mouse;
  menu^.show(cmenux,cmenuy);
  show_mouse;
  c:=0;
  hide_mouse;
  showcolor(100,10,130,40,c);
  show_mouse;
   while true do
    if mousebuttons<>0
    then begin
     i:=menu^.pressed(mouseposx,mouseposy);
{     while mousebuttons<>0 do;}
     if i<>-1
     then begin
      press_snd.play;
      case i of
       0: {$R-,Q-} inc(c);
       1: {$R-,Q-} dec(c);
       2: c:=tobyte(Receive('Color?>'));
       3: break;
      end;
     end;
     hide_mouse;
     showcolor(100,10,130,40,c);
     show_mouse;
   end;
 hide_mouse;
 dispose(menu,done);
 clipoff;
 show_mouse;
end;
