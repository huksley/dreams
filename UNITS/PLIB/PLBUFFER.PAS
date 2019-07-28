Unit plBuffer;

     interface

      const     cBUFFERSIZE = 4*1024-$F;
      var       buffer_ptr:pointer;

 procedure init_buffer;

 { input   : NONE
   output  : ES:DI - buffer pointer
   alter   : NONE[ES,DI] }
 procedure ASM_buff_esdi;

 { input   : NONE
   output  : AX - buffer size in bytes
   alter   : NONE[AX] }
 procedure ASM_buff_size;



     implementation

 uses kernel;

 procedure done_buffer;
 begin
  freemem(buffer_ptr,cBUFFERSIZE);
 end;

 procedure init_buffer;
 begin
  getmem(buffer_ptr,cBUFFERSIZE);
  add_exit_proc(@done_buffer);
 end;
 { input   : NONE
   output  : ES:DI - buffer pointer
   alter   : NONE[ES,DI] }
 procedure ASM_buff_esdi; assembler; asm
  push ds
  push ax

  mov ax,SEG buffer_ptr
  mov ds,ax
  les di,buffer_ptr

  pop ax
  pop ds
 end;
 { input   : NONE
   output  : AX - buffer size in bytes
   alter   : NONE[AX] }
 procedure ASM_buff_size; assembler; asm
  mov ax,cBUFFERSIZE
 end;

end.
