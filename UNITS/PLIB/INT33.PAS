unit int33;

interface

 procedure reset_mouse_driver(x_res,y_res:word);

implementation

 procedure reset_mouse_driver(x_res,y_res:word);
 assembler; asm
  mov ax,0021h
  int 33h      { resetting driver }

  mov ax,0000
  int 33h      { software reset }

  mov ax,0007h
  mov cx,0
  mov dx,x_res
  int 33h      { setting hor range 0..x_res }

  mov ax,0008h
  mov cx,0
  mov dx,y_res { setting ver range 0..y_res }
 end;

end.