Unit Core;
{ Core functions module }
interface

{$S+,Q+,R+,F+,B+}
const  cFATAL_ERR    = 1001;
       cPLAIN_ERR    = 1002;
type
     tmessageproc=procedure(message:string);
     tchoicey_n  =function(message:string):boolean;
     tproc       =procedure;

Var PreError:tproc;

Procedure Halt;
{ if TRUE - stack,heap,ems,xms information will be
  printed at exit, else quietly ends program }
procedure SetExitInfo(Val:Boolean);
{ setting handler to call at exit }
Procedure SetCloseHandler(Handler:Pointer);
{ setting methods to input,output - defaults for text mode,
  advise: change for graphic mode
  must  : be changed for unknown SVGA mode }
procedure SetIOmethods(forMESSAGE:TMESSAGEProc; forCHOICE:tChoiceY_n);
procedure DefaultIO;
{ initiates exit - closing program }
procedure initiate_exit;
{ exeption - cant ignore this error }
procedure Exeption(Num:word;Message:Pchar);
{ standart error - prompts for ignore }
procedure Error(Num:word;Message:PChar);
{ same as error, returns number cPLAIN_ERR }
procedure ErrorMSG(Message:PChar);
{ same as exeption, returns number cFATAL_ERR }
procedure FatalMSG(Message:PChar);
{ initiates core error handling }
procedure initiate_core;

implementation

 uses
      swset,strings,streams,tpcrt,
      tpstring,plreg;

const
      cHEAP_RUNTIME = 0;
      cHEAP_NIL     = 1;
      cHEAP_OK      = 2;
      cIGNORE_MESS  = 'Press "Y" to ignore, other to continue';
var
     doExitStat:boolean;
     CloseHandler:Pointer;
     MessageProc:TMessageProc;
     ChoiceFunc:TChoiceY_N;

procedure SetExitInfo;
begin
 doExitStat:=Val;
end;
Procedure SetCloseHandler(Handler:Pointer);
begin
 CloseHandler:=Handler;
end;
procedure SetIOmethods(forMESSAGE:TMESSAGEProc; forCHOICE:tChoiceY_n);
begin
 MessageProc:=forMessage;
 ChoiceFunc:=forChoice;
end;

procedure showStat;
begin
  Writeln( 'Program closed.');

  Writeln( 'Stack: SP=',hexw(SPtr),'h SS=',hexw(SSeg),'h');
  {$IFDEF DPMI}
  Writeln( 'Free : ',MemAvail div 1024,' kbytes');
  {$ELSE}
  Writeln( 'Heap : Org=',HexPtr(HeapOrg),' Ptr=',HexPtr(HeapPtr),
                 ' End=',HexPtr(HeapEnd),' Free=',MemAvail:6,' Max=',MaxAvail:6);
  Writeln( 'XMS  : Free=',XMS_MemAvail:8,' Max=',XMS_MaxAvail:8,'  EMS : Free=',EMS_MemAvail:8,' Max=',EMS_MaxAvail:8);
  {$ENDIF}
end;

Procedure Halt;
begin
 Initiate_exit;
end;

procedure initiate_exit;
begin
  if assigned(CloseHandler)
  then asm
   call CloseHandler;
  end;

  asm
   mov AX,SEG doExitStat
   mov ES,AX
   mov al,ES:doExitStat
   cmp al,0
   je @@SKIPSHOW
     call showStat
   @@SKIPSHOW:
  end;
{ if CloseStandartIO then begin
  Close(Input);
  Close(Output);
 end;}
{ if not DynamicExit then}
  asm
   mov ax,ExitCode
   mov ah,4ch
   int 21h
  end{ else begin
   ExitProc:=Nil;
   System.Halt;
  end};
end;

 procedure FatalExit( ErrorNo:word; CS,IP:Word; Message:PChar );
 begin
  MessageProc(StrPas(Message)+'(#'+Long2Str(ErrorNo)+') at '+HexW(CS)+':'+HexW(IP));
  ExitCode:=ErrorNo;
  ErrorAddr:=Ptr(CS,IP);
  initiate_exit;
 end;

 procedure ErrorExit( ErrorNo:word; CS,IP:Word; Message:PChar );
 begin
  MessageProc(StrPas(Message)+'(#'+Long2Str(ErrorNo)+') at '+HexW(CS)+':'+HexW(IP));

  If ChoiceFunc(cIGNORE_MESS)
  then
   begin
    asm
     pop ax
     pop bx
     pop dx
     pop es
     pop di
     pop es
     pop di
     push dx
     push bx
    end;
    ExitCode:=0;
    ErrorAddr:=Nil;
  end else begin
   ExitCode:=ErrorNo;
   ErrorAddr:=Ptr(CS,IP);
   initiate_exit;
  end;
 end;


procedure Exeption(Num:word;Message:Pchar);
assembler; asm
  mov ax,SS:[BP+4]
  mov bx,SS:[BP+2]
  sub ax,PrefixSeg
  sub ax,$10

  push num
  push ax
  push bx
  les di,Message
  push es
  push di

  call FatalExit
end;

procedure Error(Num:word;Message:Pchar);
assembler; asm
  mov ax,SS:[BP+4]
  mov bx,SS:[BP+2]
  sub ax,PrefixSeg
  sub ax,$10

  push num
  push ax
  push bx
  les di,Message
  push es
  push di

  call ErrorExit
end;

procedure ErrorMSG(Message:Pchar);
assembler; asm
  mov ax,SS:[BP+4]
  mov bx,SS:[BP+2]
  sub ax,PrefixSeg
  sub ax,$10

  push cPLAIN_ERR
  push ax
  push bx
  les di,Message
  push es
  push di

  call ErrorExit
end;

procedure FatalMSG(Message:Pchar);
assembler; asm
  mov ax,SS:[BP+4]
  mov bx,SS:[BP+2]
  sub ax,PrefixSeg
  sub ax,$10

  push cFATAL_ERR
  push ax
  push bx
  les di,Message
  push es
  push di

  call FatalExit
end;



procedure Core_ExitProc;
begin
 if Exitcode<>0
 then FatalExit(ExitCode,Seg(ErrorAddr^),Ofs(ErrorAddr^),find_err_message(ExitCode))
 else initiate_exit;
end;

procedure default_message(message:string);
begin
 if Assigned(PreError) then PreError;
 Writeln(Message);
 Readkey;
end;

function default_yes_no(message:string):boolean;
begin
 Writeln(message);
 default_yes_no:=(UpCase(Readkey)='Y');
end;

 function HeapHandler(Size:Word):Integer;
 begin
  if Memavail<Size then begin
   MessageProc('Can`t allocate '+Long2Str(Size)+' bytes of memory.');
   If ChoiceFunc(cIGNORE_MESS)
   then HeapHandler:=cHEAP_NIL
   else HeapHandler:=cHEAP_RUNTIME;
  end else HeapHandler:=cHEAP_OK;
 end;

procedure initiate_core;
begin
 ExitProc:=@Core_exitproc;
 doExitStat:=True;
 MessageProc:=default_message;
 ChoiceFunc:=default_yes_no;
 HeapError:=@HeapHandler;
 CloseHandler:=nil;
 DirectVideo:=false;
 PreError:=Nil;
end;

procedure DefaultIO;
begin
 MessageProc:=default_message;
 ChoiceFunc:=default_yes_no;
end;

end.