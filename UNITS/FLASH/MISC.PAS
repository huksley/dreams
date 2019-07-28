Unit Misc;

interface

 const
      VAR_SPACY_CHAR1   =' ';
      VAR_SPACY_CHAR2   =';';
      VAR_SPACY_CHAR3   ='/';
      VAR_SPACY_CHAR4   =',';
      VAR_SPACY_CHAR5   ='|';

type
    TPoint = object
      X, Y: Integer;
    end;
    TRect=object
     x,y,x1,y1:integer;
     procedure assign(a,b,c,d:integer);
     function contains(a,b:integer):boolean;
     function equals(a,b,c,d:integer):boolean;
    end;

    bytearr=array[0..65000] of byte;
    fstring=string[8];
 function altx_pressed:boolean;
 function PressedFunc(Num:Byte):boolean;
function Esc_pressed:boolean;

 procedure loggy(filename:fstring; logstr:string);

 function exists_var(varname:string; s:string):boolean;
 function get_var(varname:string; s:string):string;
 procedure add_var(varname,value:string; var s:string);

 function testbit(bitnum:byte; inbyte:byte):boolean;
 function toBINARY(b:byte):string;
 function leftscroll(b:byte; cnt:byte):byte;
 function rightscroll(b:byte; cnt:byte):byte;

 function belongs(x,Minx,Maxx:longint):boolean;
 function tostr(a:longint):string;
 function dup(a:byte;ch:char):string;

function PtrTOStr(Ptr:pointer):string;
procedure tabto(pos:byte; ch:char);
function Str2PChar(s:string):PChar;
 function RestString(Str:String):String;

   Procedure Beep ;
   Procedure Music ;
   procedure sound(Hz:word);
   procedure voice(hz,ms:word);
   Procedure Delay(MS:Word);
   Procedure VideoMode (Mode : byte) ;
   Procedure InitVGAMode ;
   Procedure InitTextMode ;
   Function  KeyPressed : Boolean ;
   Function  ReadKey : Char ;
   Procedure ClearKBD ;

procedure WVStart;
procedure WVEnd;

implementation
Uses tpstr,swset,core,gr_err,tpdos,strings,crt;

 function RestString(Str:String):String;
 begin
  if Arguments(Str)<>0
  then RestString:=Copy(Str,Pos(' ',Str)+1,255)
  else RestString:='';
 end;
function Esc_pressed:boolean;
begin
 Esc_pressed:=keypressed and (ReadKey=#27);
end;
function PressedFunc(Num:Byte):boolean;
begin
 PressedFunc:= Keypressed and (ReadKey=#0) and
           Keypressed and (ReadKey=Chr(58+Num));
end;

function dup;
 var b:integer;
     s:string;
begin
 s:='';
 for b:=1 to a do s:=s+ch;
 dup:=s;
end;

procedure clearbuff;
begin
 if keypressed then Readkey;
end;
function Belongs;
begin
 if (x>=Minx) and (x<=Maxx) then Belongs:=true else Belongs:=false;
end;
function tostr(a:longint):string;
var s:string;
begin
 str(a,s);
 tostr:=s;
end;

 Const
   MCh: Byte=0;

   Procedure SpeakerOn (toneout : word) ; Assembler ;
   asm
     mov al, 182       { prepare timer to start generating sound }
     out 43h, al
     mov ax, toneout   { TONEOUT = word: 1193180 / frequency }
     out 42h, al       { send low byte to port 42h }
     mov al, ah
     out 42h, al       { send high byte to port 42h }
     in al, 61h        { get current value of port 61h }
     or al, 3          { set lowest two bits of 61h "on" -- activate speaker }
     out 61h, al       { rewrite to port 61h }
   end;

   Procedure SpeakerOff ; Assembler ;
   asm
     in al, 61h        { set lowest two bits of 61h "off" -- deactive speaker }
     and al, 252       { this line turns the lowest two bits "off" }
     out 61h, al
   end;

   Procedure Beep ;
   Begin
    if SoundEnabled then begin
     SpeakerOn (800) ;
     delay(3);
     SpeakerOff ;
    end;
   End ;

   Procedure Music ;
   Begin
     SpeakerOn (1600) ;
     delay (3) ;
     SpeakerOn (1700) ;
     delay (3) ;
     SpeakerOn (1500) ;
     delay (3) ;
     SpeakerOn (1600) ;
     delay (3) ;
     SpeakerOn (1700) ;
     delay (3) ;
     SpeakerOff ;
   End ;

   Procedure VideoMode ( Mode : Byte );
   Begin { VideoMode }
     Asm
       Mov  AH,00
       Mov  AL,Mode
       Int  10h
     End;
   End;  { VideoMode }

   Procedure InitVGAMode ;
   Begin
     VideoMode (19) ;
     gr_err.set_gr_io;
   End ;

   Procedure InitTextMode ;
   Begin
     VideoMode (03) ;
     core.defaultio;
   End ;

   function altx_pressed:boolean;
begin
  altx_pressed:=
    keypressed          and
    (ord(readkey)=00)   and
    keypressed          and
    (ord(readkey)=45)   ;
end;


   Function ReadKey ; Assembler;
   Asm
     mov  al,MCh
     mov  byte ptr MCh,00
     or   al,al
     jne  @0338
     xor  ah,ah
     int  16h
     or   al,al
     jne  @0338
     mov  MCh,ah
     or   ah,ah
     jne  @0338
     mov  al,03h
   @0338:
   End;

   Function KeyPressed ; Assembler;
   Asm
     cmp  byte ptr MCh,00
     jne  @0317
     mov  ah,01h
     int  16h
     mov  al,00h
     je   @0319
   @0317:
     mov  al,01h
   @0319:
   End;

   Procedure ClearKBD ; Assembler;
   Asm
   @@Begin:
     mov  ah,01h
     int  16h
     je   @@Exit
     xor  ah,ah
     int  16h
     jmp  @@Begin
   @@Exit:
   End;
  procedure Delay;
  begin
   crt.delay(ms);
  end;

procedure WVStart;
assembler; asm
        push    ax
        push    dx

        mov     dx, 03dah
@@11:
        in      al,dx
        test    al,08h
        jnz     @@11
@@22:
        in      al,dx
        test    al,08h
        jz      @@22

        pop     dx
        pop     ax
END;


procedure WVEnd;
assembler; asm

        pusha

        mov     dx,03dah
@@33:
        in      al,dx
        test    al,08h
        jz     @@33
@@44:
        in      al,dx
        test    al,08h
        jnz      @@44

        popa
        ret
END;

function PtrTOStr(Ptr:pointer):string;
begin
 if not assigned(Ptr)
 then PtrTOStr:='nil'
 else PtrTOStr:=TOStr(Seg(Ptr^))+':'+ToStr(Ofs(Ptr^));
end;

 procedure sound;
 begin
  crt.sound(hz);
 end;
 procedure voice;
 begin
  crt.sound(hz);
  delay(ms);
  crt.nosound;
 end;

 procedure tabto(pos:byte; ch:char);
 begin
  if wherex<pos then
  while wherex<>pos do write(ch);
 end;

 function testbit(bitnum:byte; inbyte:byte):boolean;
 assembler; asm
  mov al,inbyte
  mov cl,bitnum
  shr al,cl
  shl al,7
  shr al,7
 end;

 function toBINARY(b:byte):string;
  var a:byte;
      s:string[8];
 begin
  s:='';
  for a:=0 to 7 do
   if testbit(a,b) then s:=concat('1',s) else s:=concat('0',s);
  toBINARY:=s+'b';
 end;
function leftscroll(b:byte; cnt:byte):byte;
assembler; asm
 mov al,b
 mov cl,cnt
 rol al,cl
end;
function rightscroll(b:byte; cnt:byte):byte;
assembler; asm
 mov al,b
 mov cl,cnt
 ror al,cl
end;
 procedure loggy(filename:fstring; logstr:string);
  var f:text;
 begin
  assign(f,filename+'.log');

  if existfile(filename+'.log')
  then Append(f) else Rewrite(f);

  writeln(f,logstr);
  close(f);
 end;
  function space_char(ch:char):boolean;
  begin
   space_char:= (ch=VAR_SPACY_CHAR1) or
                (ch=VAR_SPACY_CHAR2) or
                (ch=VAR_SPACY_CHAR3) or
                (ch=VAR_SPACY_CHAR4) or
                (ch=VAR_SPACY_CHAR5);
  end;

 function get_var(varname:string; s:string):string;
  var a,b:byte;

 begin
  b:=pos(varname+':',s);
  if b<>0 then begin
   for a:=b+length(varname)+1 to length(s) do if space_char(s[a]) then break;
   if (not space_char(s[length(s)])) and (a=length(s)) then a:=a+1;
   get_var:=copy(s,b+length(varname)+1,a-b-length(varname)-1)
  end else get_var:='';
 end;
 function exists_var(varname:string; s:string):boolean;
 begin
  exists_var:=(pos(varname+':',s)<>0);
 end;
 procedure add_var(varname,value:string; var s:string);
  var a:byte;
 begin
  if not exists_var(varname,s)
  then s:=s+varname+':'+value+VAR_SPACY_CHAR1
  else begin
   for a:=pos(varname+':',s)+1 to length(s) do
    if space_char(s[a]) then exit;
    s:=copy(s,1,pos(varname+':',s)) + varname+':'+value + copy(s,a,255);
  end;
 end;

     procedure trect.assign;
     begin
      x:=a; y:=b; x1:=c; y1:=d;
     end;
     function trect.contains;
     begin
      contains:= belongs(a,x,x1) and
                 belongs(b,y,y1);
     end;
     function trect.equals;
     begin
      equals:=(x=a) and (y=b) and (x1=c) and (y1=d);
     end;
function Str2PChar(s:string):PChar;
 var p:Pointer;
begin
 GetMem(p,Length(s)+1);
 Str2PCHar:=StrPCopy(p,S);
end;
end.
