Unit pureasm;

interface
{ input   : AX - Width, BX - Height
  output  : AX - Size in bytes of image
  alter   : NONE[AX,BX] }
procedure ASM_shapesize;

implementation

procedure ASM_shapesize; assembler; asm
 mul bx
end;

end.