{       General string manipulation unit        }
{ ┌───────────────────────────────────────────┐ }
{ │ } Unit Parsing;                         { │ }
{ └───────────────────────────────────────────┘ }

                  interface

 uses Dos,Objects;

 procedure UpCaseStr(Var Str:String);
  {- upcases string, with international support }
 function Same(Str1,Str2:String):boolean;
  {- compares strings, not case sensitive }
 function  Arguments(Str:string):byte;
  {- returns number of arguments, don`t breaks quotes("") }
 function  Argument(Str:string; n:byte):string;
  {- returns specified argument, don`t breaks quotes("") }
 procedure TrimSpaces(var Str:string);
  {- removes leading, trailing and inned spaces }
  {  removes all from ";" char to the end       }
 function Tail(Str:String; n:integer):string;
  {- returns tail of string, without n`th first arguments }
  {  string must be already trimed                        }
 function FindArg(Part,Str:String):integer;
  {- searching for part as argument of str }
  {  returns number is found, -1 otherwise }
 function ArgumentQuoted(Str:string; i:integer):string;
  {- returns, argument of string                         }
  {  if argument is in quotes, returns it without quotes }

 var ConvertError : integer;      { error result         }
     StrWidth     : integer;      { width for ???2Str    }
     StrDecimals  : integer;      { decimals for ???2Str }

 procedure ConvertReset;
 { ordinal -> string convesion }
 function Int2Str(Int:longint):string;
 function Real2Str(Float:real):string;
 function Date2Str(Date:DateTime):string;
 function Time2Str(Time:DateTime):string;
 function Pointer2Str(Ptr:Pointer):string;
 function PChar2Str(StrP:PChar):string;
 function PString2Str(PStr:PString):string;
 { string -> ordinal conversion }
 function Str2Int(Str:string; Default:Longint):longint;
 function Str2Real(Str:String; Default:Real):real;
 function Str2Date(Str:String; var Date:DateTime):boolean;
 function Str2Time(Str:String; var Time:DateTime):boolean;
 function Str2PChar(Str:string):PChar;
 function Str2PString(Str:String):PString;

                implementation

 uses tpstring,strings,memory;

procedure UpCaseAsm;
assembler; asm
 mov cl,es:[di]
 xor ch,ch
 inc di
 @@upit:
  mov al,es:[di]
  cmp al,61h
  jae @@Froma
  inc di
  loop @@upit
  jmp @@fin
  @@Froma:
   cmp al,07Ah
   jbe @@Toz
   cmp al,$A0
   jae @@fromra
   inc di
   loop @@upit
   jmp @@fin
  @@Toz:
   sub al,32
   mov es:[di],al
   inc di
   loop @@upit
   jmp @@fin
  @@Fromra:
   cmp al,$E0
   jae @@Fromrr
   cmp al,$AF
   jbe @@Torp
   inc di
   loop @@upit
   jmp @@fin
  @@Torp:
   sub al,32
   mov es:[di],al
   inc di
   loop @@upit
   jmp @@fin
  @@Fromrr:
   cmp al,$F1
   je @@Ise
   cmp al,$EF
   jbe @@Toria
   inc di
   loop @@upit
   jmp @@fin
  @@Toria:
   sub al,80
   mov es:[di],al
   inc di
   loop @@upit
   jmp @@fin
  @@Ise:
   dec al
   mov es:[di],al
   inc di
   loop @@upit
   jmp @@fin
 @@fin:
end;

procedure UpCaseStr(Var Str:String);
assembler; asm
 les di,Str
 call UpCaseAsm
end;

function Same(Str1,Str2:String):boolean;
assembler; asm
 push ds
  lds si,Str1
  les di,Str2
  mov cl,ds:[si]
  mov ch,es:[di]
  cmp cl,ch
  jne @@No
  les di,Str1
  call upcaseasm
  les di,Str2
  call upcaseasm
  lds si,Str1
  les di,Str2
  mov cl,ds:[si]
  xor ch,ch
  inc di
  inc si
  cld
  repe cmpsb
  jne @@No
  jmp @@Yes
  @@Yes:
   mov al,1
   jmp @@Fin
  @@No:
   mov al,0
   jmp @@Fin
  @@Fin:
 pop ds
end;

function Arguments(Str:string):byte;
assembler; asm { es:di - string; al - starting pos }
 les di,Str
 mov al,1
 mov cl,es:[di]
 mov ah,$FF
 cmp cl,0
 je @@fin
 mov ah,0
 xor ch,ch
 sub cl,al
 inc cl
 add di,ax
  @@scantoken:
   mov al,es:[di]
   cmp al,'"'    { scanning for end of quote }
   jne @@skipscan
    @@doskan:
     inc di
     dec cl
     mov al,es:[di]
     cmp al,'"'
     je @@found
     cmp cl,0
     jne @@doskan
     @@found:
     cmp cl,0
     je @@fin
  @@skipscan:
   cmp al,' '
   je @@space
   inc di
   loop @@scantoken
   jmp @@fin
  @@space:
   inc ah
   inc di
   loop @@scantoken
 @@fin:
  mov al,ah
  inc al
end;

procedure FindQuote;
assembler; asm
{ expects es:di - string
          cl    - size }
 @@notfound:
  inc di
  mov al,es:[di]
  cmp al,'"'
  je @@found
  loop @@notfound
 @@found:
end;
procedure ScanArg(Str:String; arg:byte);
assembler; asm
{ returns al - starting pos of Argument,
          ah - size of arg, al=0 if error }
 les di,Str
 mov cl,es:[di]
 cmp cl,0
 je @@Error
 dec cl
 inc di
 xor ch,ch
 mov ah,0
 mov dl,0
  @@scantoken:
   mov al,es:[di]
   cmp al,'"'
   jne @@donext
    dec cl
    call findquote
    cmp cl,0
    je @@Fin
    mov al,es:[di]
   @@donext:
    cmp al,' '
    jne @@skipinc
    inc ah
    @@skipinc:
    cmp ah,arg
    je @@docount
    ja @@fin
    @@notstop:
    inc di
    inc dh
    loop @@scantoken
    jmp @@endstr
   @@docount:
    cmp dl,0
    jne @@areready
    mov dl,cl
    mov dh,0
    @@areready:
    inc di
    inc dh
    loop @@scantoken
    jmp @@endstr
   @@dostop:
    cmp cl,0
    je @@endstr
    jmp @@fin
 @@Error:
  mov dl,0
  mov dh,0
  jmp @@fin
 @@Endstr:
  mov al,dl
  mov ah,dl
  inc ah
  cmp arg,0
  jne @@NotFirst
  jmp @@Stop
 @@Fin:
  mov al,dl
  mov ah,dl
  sub ah,cl
  cmp arg,0
  jne @@NotFirst
  jmp @@Stop
  @@NotFirst:
  dec al
  dec ah
 @@Stop:
end;

function Argument(Str:string; n:byte):string;
 var a,b:byte;
begin
 ScanArg(Str,n);
 asm
  mov a,al
  mov b,ah
 end;
 if b=0
 then Argument:=''
 else Argument:=System.Copy(Str,Length(Str)-a,b);
end;

 procedure TrimSpaces(var Str:string);
  {- removes leading, trailing and inned spaces }
  {  removes all from ";" char to the end       }
  var i,n:integer;
 begin
  If pos(';',Str)<>0 then Delete(Str,Pos(';',Str),255);
  while Str[1]=' ' do delete(Str,1,1);
  while Str[Length(Str)]=' ' do Delete(Str,Length(Str),1);
  for i:=2 to Length(Str) do begin
   if Str[i]='"' then begin
    for n:=i+1 to Length(Str) do if Str[n]='"' then break;
    i:=n;
   end;
   if (Str[i-1]=' ') and (Str[i]=' ')
   then begin
    Delete(Str,i,1); i:=i-1;
   end;
  end;
 end;

 function Tail(Str:String; n:integer):string;
  {- returns tail of string, without n`th first arguments }
  {  string must be already trimed                        }
  var i,s:integer;
 begin
  s:=0; for i:=0 to n-1 do s:=s+Length(Argument(Str,i))+1;
  Tail:=Copy(Str,S+1,255);
 end;

 function FindArg(Part,Str:String):integer;
  {- searching for part as argument of str }
  {  returns number is found, -1 otherwise }
  var i:integer;
 begin
  FindArg:=-1;
  for i:=0 to Arguments(Str)-1 do
   if Same(Argument(Str,i),Part)
   then begin
    FindArg:=i; exit;
   end;
 end;

 function ArgumentQuoted(Str:string; i:integer):string;
  {- returns, argument of string                         }
  {  if argument is in quotes, returns it without quotes }
 begin
  ArgumentQuoted:=Argument(Str,i);
  If Copy(Argument(Str,i),1,1)='"'
  then ArgumentQuoted:=Copy(Argument(Str,i),2,Length(Argument(Str,i))-2);
 end;

 { Conveting functions }
 { If Error occurs, stores result in ConvertError }
 var
     StrTemp      : string;       { temporary string     }
     IntTemp      : longint;
     RealTemp     : real;

 procedure ConvertReset;
 begin
  StrWidth:=0;
  StrDecimals:=0;
  ConvertError:=0;
 end;

 { ordinal -> string convesion }

 function Int2Str(Int:longint):string;
 begin
  Str(Int:StrWidth,StrTemp);
  Int2Str:=StrTemp;
 end;
 function Real2Str(Float:real):string;
 begin
  Str(Float:StrWidth:StrDecimals,StrTemp);
  Real2Str:=StrTemp;
 end;
 function Date2Str(Date:DateTime):string;
 begin
  Date2Str:= LeftPadCh(Int2Str(Date.Day),'0',2)+'/'+
             LeftPadCh(Int2Str(Date.Month),'0',2)+'/'+Int2Str(Date.Year);
 end;
 function Time2Str(Time:DateTime):string;
 begin
  Time2Str:= LeftPadCh(Int2Str(Time.Hour),'0',2)+':'+
             LeftPadCh(Int2Str(Time.Min),'0',2);
 end;
 function Pointer2Str(Ptr:pointer):string;
 begin
  Pointer2Str:=HexPtr(Ptr);
 end;
 function PChar2Str(StrP:PChar):string;
 begin
  PChar2Str:=StrPas(StrP);
 end;
 function PString2Str(PStr:PString):string;
 begin
  PString2Str:=PStr^;
 end;

 { string -> ordinal conversion }
 function Str2Int(Str:string; Default:Longint):longint;
 begin
  Val(Str,IntTemp,ConvertError);
  if ConvertError<>0
  then Str2Int:=Default
  else Str2Int:=IntTemp;
 end;
 function Str2Real(Str:String; Default:Real):real;
 begin
  Val(Str,RealTemp,ConvertError);
  if ConvertError<>0
  then Str2Real:=Default
  else Str2Real:=RealTemp;
 end;
 function Str2Date(Str:String; var Date:DateTime):boolean;
  var i:integer;
 begin
  Str2Date:=false;
  if pos('/',Str)<>0
  then begin
   i:=Str2Int(Copy(Str,1,Pos('/',Str)-1),-1);
   if i<>-1
   then begin
    Date.Day:=i;
    Delete(Str,1,Pos('/',Str));
    if Pos('/',Str)<>0
    then begin
     i:=Str2Int(Copy(Str,1,Pos('/',Str)-1),-1);
     if i<>-1
     then begin
      Date.Month:=i;
      Delete(Str,1,Pos('/',Str));
      i:=Str2Int(Str,-1);
      if i<>-1 then begin
       Date.Year:=i;
       Str2Date:=True;
      end;
     end;
    end;
   end;
  end;
 end;
 function Str2Time(Str:String; var Time:DateTime):boolean;
  var i:integer;
 begin
  Str2Time:=false;
  if pos(':',Str)<>0
  then begin
   i:=Str2Int(Copy(Str,1,Pos(':',Str)-1),-1);
   if i<>-1 then begin
    Time.Hour:=i;
    Delete(Str,1,Pos(':',Str));
    i:=Str2Int(Str,-1);
    if i<>-1 then begin
     Time.Min:=i;
     Str2Time:=True;
    end;
   end;
  end;
 end;
 function Str2PChar(Str:string):PChar;
 begin
  Str2PChar:=StrPCopy(MemAlloc(Length(Str)+1),Str);
 end;
 function Str2PString(Str:String):PString;
 begin
  Str2PString:=NewStr(Str);
 end;

end.