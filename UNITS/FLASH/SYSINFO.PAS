
  Unit SysInfo ;

  Interface
  Uses
    CPUType ;


  Type
    CPU     = ( cpu8088,
                cpu8086,
                cpu80286,
                cpu80386,
                cpu80486,
                cpuPentium,
                cpuFuture );

  Const
    CPUName : Array[CPU] of string[16] =
     ('8088','8086','80286','80386','80486','Pentium','Pentium Pro');
 type
    ST3 = String[3] ;

  Function GetCPUType : CPU ;
  Function GetCPUTypeStr : String ;
  Function GetFPUTypeStr : String ;
  Function GetCPUSpeed : Integer ;

  Function GetOSVersion : word ;
  Function GetOSName : String ;

                 {  For Version used
                       Writeln ('Version ', hi (Ver), '.', lo (Ver));
                 }

  Function GetBaseRAM : Word ;
  Function GetExtendedRAM : Word ;

  Function CheckEMS : Boolean ;  { пpовеpяет наличие EMS }
  Function CheckXMS : Boolean ;  { пpовеpяет наличие XMS }

  Function GetEMSVersion : String ;
  Function GetTotalEMS : Word ;
  Function GetAvailableEMS : Word ;


  Implementation
  Uses
    DOS ;


  Type
    str17 = String[17] ;

  Const
    In_DV  : Boolean = False; { are we in DESQview? }
    In_VM  : Boolean = False; { are we in a 386+ virtual machine? }
    In_OS2 : Boolean = False; { are we in OS/2? }

  Var
    Regs : Registers ;


  {-------======= Non Interfaced Functions =======---------}



     {$L CPU.OBJ}

     {$F+}
     Function WhichCPU : Cpu ; EXTERNAL ;
     {$F-}


   Function OS2_GetVersion: Word; Assembler;
   Asm
     MOV    AH, 30h  { Dos Get Version Call }
     INT    21h      { AL = major version * 10, AH = minor version }
     MOV    BH, AH   { save minor version }
     xor    AH, AH
     MOV    CL, 10
     div    CL       { divide by 10 to get the major version }
     MOV    AH, BH   { restore minor version }
     XCHG   AH, AL   { AH = major, AL = minor }
   end;

   Function DV_GetVersion: Word; Assembler;
   Asm
     MOV    CX,'DE'     { CX+DX to 'DESQ' (invalid date) }
     MOV    DX,'SQ'
     MOV    AX,02B01H   { Dos' set date funct. }
     INT    21H         { call Dos }
     CMP    AL,0FFH     { Was it invalid? }
     JE     @No_dv      { yep, no dv }
     MOV    AX,BX       { AH=major AL=minor }
     MOV    In_DV,1     { Set In_DV flag }
     JMP    @DvGv_x     { other routines }
    @No_dv:
     xor    AX,AX       { Return 0 or no DV }
    @DvGv_x:
   end; { DV_GetVersion }


   Function Win3X : Boolean;
   { Routine to determine if Windows is currently running }
   begin
     Regs.AX := $4680;    { Win 3.x Standard check }
     Intr($2F, Regs);     { Call Int 2F }
     if Regs.AX <> 0 then { if AX = 0 Win in Real mode }
     begin                { else check For enhanced mode }
       Regs.AX := $1600;  { Win 3.x Enhanced check }
       Intr($2F, Regs);   { Call Int 2F }
       if Regs.AL in [$00,$80,$01,$FF] then { Check returned value }
         Win3X := False   { Nope not installed }
       else
         Win3X := True;   { Ya it is }
     end
     else
       Win3X := True;     { Return True }
   end;


   Function WinVer :Word;
   {  Returns a Word containing the version of Win Running }
   {  Should only be used after checking For Win installed }
   {  Or value returned will be meaningless                }
   begin
     Regs.AX := $1600;    {  Enhanced mode check }
     Intr($2F, Regs);     {  Call Int 2F         }
     WinVer := Regs.AX;   {  Return proper value }
   end;


   function TestNowell : Boolean ;
   var
     R : registers;
     Reply_buffer : array [1..50] of char;
   begin
     R.ax := $EA01;
     R.bx := 0;
     R.es := Seg (Reply_buffer);
     R.di := Ofs (Reply_buffer);
     MsDos (R);
     if R.bx = 0 then TestNowell := false
                else TestNowell := true;
   end;


   FUNCTION Running4DOS : Boolean;
   VAR Regs : Registers;
   begin
      With Regs do
         begin
            ax := $D44D;
            bx := $00;
         end;
      Intr ($2F, Regs);
      if Regs.ax = $44DD then Running4DOS := TRUE
                         else Running4DOS := FALSE
   end;


   Function IsDoubleDOS : Boolean ;
   type
     Taskers = (NoTasker, DesqView, DoubleDOS, Windows, OS2, NetWare);
   Var
     MultiTasker : Taskers ;
     InDosFlag : ^Word ;
   Begin
     asm
      @CheckDV:
        mov   AX, $2B01
        mov   CX, $4445
        mov   DX, $5351
        int   $21
        cmp   AL, $FF
        je    @CheckDoubleDOS
        mov   MultiTasker, DesqView
        jmp   @CheckDone

      @CheckDoubleDOS:
        mov   AX, $E400
        int   $21
        cmp   AL, $00
        je    @CheckWindows
        mov   MultiTasker, DoubleDOS
        jmp   @CheckDone

      @CheckWindows:
        mov   AX, $1600
        int   $2F
        cmp   AL, $00
        je    @CheckOS2
        cmp   AL, $80
        je    @CheckOS2
        mov   MultiTasker, Windows
        jmp   @CheckDone

      @CheckOS2:
        mov   AX, $3001
        int   $21
        cmp   AL, $0A
        je    @InOS2
        cmp   AL, $14
        jne   @CheckNetware
      @InOS2:
        mov   MultiTasker, OS2
        jmp   @CheckDone

      @CheckNetware:
        mov   AX,$7A00
        int   $2F
        cmp   AL,$FF
        jne   @NoTasker
        mov   MultiTasker, NetWare
        jmp   @CheckDone

      @NoTasker:
        mov   MultiTasker, NoTasker

      @CheckDone:
        jmp @Done

      @Done:
      {-Get InDos flag }
        mov   AH, $34
        int   $21
        mov   WORD PTR InDosFlag, BX
        mov   WORD PTR InDosFlag + 2, ES
      end;
      if MultiTasker = DoubleDOS  then
        isDoubleDOS := true
      else
        isDoubleDOS := false ;
    End ;

   {----------========= Interfaced Functions ==============----------}


     Function GetOSVersion : word ;
     Var
       i : Byte ;
     Begin
       GetOSVersion := Swap (DosVersion) ;
       if Win3X then
         GetOSVersion := Swap (WinVer)
       else
         if In_OS2 then
           GetOSVersion := OS2_GetVersion
         else
           if In_DV then
             GetOSVersion := DV_GetVersion
           else
             if In_VM then
               GetOSVersion := 0
             else
               if TestNowell then
                 GetOSVersion := 0
               else
                 if Running4DOS then
                   GetOSVersion := 0
                 else
                   if isDoubleDOS then
                     GetOSVersion := 0
     End ;


     Function GetOSName : String ;
     Var
       OS : String ;
     Begin
       OS := 'MS-DOS' ;
       if Win3X then
         OS := 'Windows'
       else
         if In_OS2 then
           OS := 'OS/2'
         else
           if In_DV then
             OS := 'DesqView'
           else
             if In_VM then
               OS := 'Virtul Machine'
             else
               if TestNowell then
                 OS := 'Novell WS Shell'
               else
                 if Running4DOS then
                   OS := '4DOS'
                 else
                   if isDoubleDOS then
                     OS := 'DoubleDOS' ;
       GetOSName := OS ;
     End ;

     Function GetBaseRAM : Word ;
     Const
       int15: longint = $f000f859;
     Var
       baseram : word;
     begin
       asm
         int   12h
         mov   baseram,ax
       end ;
       GetBaseRAM := baseram ;
     end ;


     Function GetExtendedRAM : Word ;
     Const
       int15: longint = $f000f859;
     Var
       extram: word;
     begin
       asm
         mov   ah,88h
         pushf
         call  int15
         mov   extram,ax
       end;
       GetExtendedRAM := extram ;
     end ;



  Function CheckEMS : Boolean ;
  TYPE
    PtrType = RECORD                  {Define a pointer record    }
      Offset  : Word;                 {  type so we can access the}
      Segment : Word                  {  individual pointer fields}
      END;
  DeviceName = ARRAY[1..8] OF Char; {Defined to test device Name}

  Var 
    EmsVector : Pointer ;
  Begin
    GetIntVec($67,EmsVector);
    PtrType(EmsVector).Offset := 10;
    IF (DeviceName(EmsVector^) = 'EMMXXXX0') THEN 
       CheckEMS := TRUE
    else
       CheckEMS := False ;
  End;


 Function CheckXms : Boolean ;
 Var
   regs  :  registers;
 begin
   regs.ax := $4300;
   intr($2F,regs);
   CheckXMS := regs.al = $80;
 end;

     Function GetEMSVersion : String ;
     Var
       Version_String : String ;
       Regs : Registers ;
       Word_Part, Fractional_Part : Char;
     Begin
       if CheckEMS then
       with Regs do
         begin
           AH:=$46;
           Intr($67,Regs);
           If AH=0 then
             Begin
               Word_Part   := Char( AL shr 4 + 48);
               Fractional_Part:= Char( AL and $F +48);
               Version_String:= Word_Part+'.'+Fractional_Part;
             end;
           GetEMSVersion:=Version_String ;
         end;
     End;


     Function GetTotalEMS : Word ;
     Var
       Regs: Registers;
     Begin
       with Regs do
         begin
           AH:=$42;
           intr($67,Regs);
           GetTotalEMS:=DX*16;
         end;
     End ;

     Function GetAvailableEMS : Word ;
     Var
       Regs: Registers;
     Begin
       with Regs do
         begin
           AH:=$42;
           intr($67,Regs);
           GetAvailableEMS := BX*16 ;
         end;
     End ;

     Function GetCpuType : Cpu ;
     Const
       CpuTypeIdentified : Boolean = False;
     Var
       ConfirmedCpuType : Cpu ;
     Procedure IdentifyCpuType ;
     Begin
       If Not CpuTypeIdentified Then
       Begin
         ConfirmedCpuType  := WhichCPU ;
         CpuTypeIdentified := True ;
       End;
     End;
     Begin
       IdentifyCpuType ;
       GetCpuType := ConfirmedCpuType ;
     End;

     Function GetCpuTypeStr : String ;
     Var
       S1, S2, S3 : String ;
     Begin
       S1 := CPU_TypeStr ;
       if isCyrix then
         begin
           Str (CxStep, S2) ;
           Str (CxRevision, S3) ;
           S1 := S1 + ' Step ' + S2 + ' Revision ' + S3 ;
         end ;
       GetCpuTypeStr := S1 ;
     End ;

     Function GetCPUSpeed : Integer ;
     Begin
       GetCPUSpeed := intCPUSpeed ;
     End ;

     Function GetFPUTypeStr : String ;
     Begin
       GetFPUTypeStr := CoPro_TypeStr ;
     End ;

  Begin
    DV_GetVersion;
    Asm
      MOV AX, 1680h
      INT 2Fh
      not AL
      MOV CL, 7
      SHR AL, CL
      MOV In_VM, AL
    end;
    In_OS2 := (OS2_GetVersion >= $0100);
  End.
