{ Vga graphics library }
{ plain procedures }
{$S-,Q-,R-}

Unit PlVgaLib;


interface

const
      cOKFIT      = 0;
      cNEEDCUT    = 1;
      cHIDED      = 2;
      cERROR      = 3;

{ initiates graphics mode }
{ automatically close vga on exit }
procedure init_vgamode;
{ this is a automatically called procedure }
procedure init_textmode;
{ shapesize calculation procedure }
function shapesize(x,y,x1,y1:word):word;
{ cuts a window from shape }
procedure cut_fit(var shape; shapew,shapeh:word; x,y,w,h:word; var newshape);
{ shows sprite on screen
  no checking performed }
procedure show_full(x,y,w,h:word; var sprite; var device; devwid:word);
procedure show_sprite(x,y,w,h:word; var sprite; var device; devwid:word);
{ determines if (x,y) in (0..w-1,0..h-1) }
function inrect(x,y,w,h:integer):boolean;
{ show shape with zero fully clipped i.e. cuts it to fit in screen }
procedure full_clip( x,y:integer; shapew,shapeh,devw,devh:word; var shape;var dev);
{ show shape fully clipped i.e. cuts it to fit in screen }
procedure show_clip( x,y:integer; shapew,shapeh,devw,devh:word; var shape;var dev);
{ checks shape to fit in device }
function check_shape(x,y,x1,y1:integer; devw,devh:word):byte;
{ gets shape from screen with clipping }
function get_clip( var x,y:integer; var shapew,shapeh:word; devw,devh:word; var shape;var dev):word;

implementation

uses misc,kernel,plmove,plbuffer;

procedure init_textmode;
begin
 InitTEXTmode;
 Writeln('Back from graphics mode...');
end;

procedure init_vgamode;
begin
 InitVGAmode;
 add_exit_proc(@init_textmode);
end;

function shapesize(x,y,x1,y1:word):word;
begin
 shapesize:=(x1-x+1)*(y1-y+1)
end;


procedure cut_fit(var shape; shapew,shapeh:word; x,y,w,h:word; var newshape);
assembler; asm
  push ds

  mov ax,y
  mul shapew
  add ax,x { ax contains (x,y) point }

  lds si,shape
  add si,ax { ds:si - offset from begginng }

  mov bx,shapew
  sub bx,w { bx contains number of bytes to add to si after one line }

  les di,newshape
  mov ax,0
  mov cx,h
  @vertical: push cx
              mov cx,w

               shr cx,1
               jnc @@onlywords
               movsb
                @@onlywords:
                rep movsw


              add si,bx
             pop cx
             loop @vertical

  pop ds
end;


procedure show_full(x,y,w,h:word; var sprite; var device; devwid:word);
assembler; asm
 les di,sprite
 push es
 push di
 mov cx,devwid
 les di,device
 mov ax,cx
 mul y
 add ax,x
 add di,ax
 push es
 push di
 mov ax,w
 mul h
 push ax
 push w
 sub cx,w
 push cx
 call move_add
end;

procedure show_sprite(x,y,w,h:word; var sprite; var device; devwid:word);
assembler; asm
 les di,sprite
 push es
 push di
 mov cx,devwid
 les di,device
 mov ax,cx
 mul y
 add ax,x
 add di,ax
 push es
 push di
 push 0
 mov ax,w
 mul h
 push ax
 push w
 sub cx,w
 push cx
 call move_skip
end;

function inrect(x,y,w,h:integer):boolean;
begin
 inrect:=belongs(x,0,w-1) and belongs(y,0,h-1);
end;

function check_shape(x,y,x1,y1:integer; devw,devh:word):byte;
begin
 if inrect(x,y,devw,devh) and inrect(x1,y1,devw,devh)
 then check_shape:=cOKFIT
 else if inrect(x,y,devw,devh) or
         inrect(x1,y1,devw,devh) or
         inrect(x,y1,devw,devh) or
         inrect(x1,y,devw,devh)
      then check_shape:=cNEEDCUT
      else check_shape:=cHIDED;
end;

procedure full_clip( x,y:integer; shapew,shapeh,devw,devh:word; var shape;var dev);
 var
    x1,y1,
    cutx,cuty,realw,realh,
    realx,realy:integer;
begin
 case check_shape(x,y,x+shapew-1,y+shapeh-1,devw,devh) of
  cOKFIT: show_full(x,y,shapew,shapeh,shape,dev,devw);
  cNEEDCUT: begin
             x1:=x+shapew-1; y1:=y+shapeh-1;

             if x1>devw-1 then realw:=shapew-(x1-devw+1)
                          else realw:=shapew;
             if y1>devh-1 then realh:=shapeh-(y1-devh+1)
                          else realh:=shapeh;

             if x<=0 then begin
                           realx:=0; cutx:=abs(x);
                           realw:=shapew-cutx;
                         end else begin
                          realx:=x; cutx:=0;
                         end;

             if y<=0 then begin
                           realy:=0; cuty:=abs(y);
                           realh:=shapeh-cuty;
                         end else begin
                          realy:=y; cuty:=0;
                         end;

             cut_fit(shape,shapew,shapeh,cutx,cuty,realw,realh,buffer_ptr^);
             show_full(realx,realy,realw,realh,buffer_ptr^,dev,devw);
            end;
  cHIDED:
 end;
end;
procedure show_clip( x,y:integer; shapew,shapeh,devw,devh:word; var shape;var dev);
 var
    x1,y1,
    cutx,cuty,realw,realh,
    realx,realy:integer;
begin
 case check_shape(x,y,x+shapew-1,y+shapeh-1,devw,devh) of
  cOKFIT: show_sprite(x,y,shapew,shapeh,shape,dev,devw);
  cNEEDCUT: begin
             x1:=x+shapew-1; y1:=y+shapeh-1;

             if x1>devw-1 then realw:=shapew-(x1-devw+1)
                          else realw:=shapew;
             if y1>devh-1 then realh:=shapeh-(y1-devh+1)
                          else realh:=shapeh;

             if x<=0 then begin
                           realx:=0; cutx:=abs(x);
                           realw:=shapew-cutx;
                         end else begin
                          realx:=x; cutx:=0;
                         end;

             if y<=0 then begin
                           realy:=0; cuty:=abs(y);
                           realh:=shapeh-cuty;
                         end else begin
                          realy:=y; cuty:=0;
                         end;

             cut_fit(shape,shapew,shapeh,cutx,cuty,realw,realh,buffer_ptr^);
             show_sprite(realx,realy,realw,realh,buffer_ptr^,dev,devw);
            end;
  cHIDED:
 end;
end;

function get_clip;

 var
    x1,y1,
    cutx,cuty,realw,realh,
    realx,realy:integer;
begin
 case check_shape(x,y,x+shapew-1,y+shapeh-1,devw,devh) of
  cOKFIT: begin
           cut_fit(dev,devw,devh,x,y,shapew,shapeh,shape);
           get_clip:=shapew*shapeh;
          end;
  cNEEDCUT: begin
             x1:=x+shapew-1; y1:=y+shapeh-1;

             if x1>devw-1 then realw:=shapew-(x1-devw+1)
                          else realw:=shapew;
             if y1>devh-1 then realh:=shapeh-(y1-devh+1)
                          else realh:=shapeh;

             if x<=0 then begin
                           realx:=0; cutx:=abs(x);
                           realw:=shapew-cutx;
                         end else begin
                          realx:=x; cutx:=0;
                         end;

             if y<=0 then begin
                           realy:=0; cuty:=abs(y);
                           realh:=shapeh-cuty;
                         end else begin
                          realy:=y; cuty:=0;
                         end;

             cut_fit(dev,devw,devh,realx,realy,realw,realh,shape);
             x:=realx; y:=realy; shapew:=realw; shapeh:=realh;
             get_clip:=shapew*shapeh;
            end;

  cHIDED: get_clip:=0;
 end;
end;

end.