Unit TPStr;

Interface

 Uses objects;

 Const  cStringLimit:Word=1;
        cStringGrow :Word=1;

 Function TOByte(S:String):Byte;
 Function TOInt(S:String):Integer;
 Function TOWord(S:String):Word;
 Function TOLong(S:String):LongInt;
 Function TOReal(S:String):Real;

function CharPos(CharToFind: CHAR; Source: STRING; Offs:byte): BYTE;
Function LastPos(sub,s:string):byte;
{ searching for Sub in s last time }
function FindArgument(SObject,Part:String):Integer;
{ searching for Part in arguments }
Function StrToChar(Str:String):PChar;
{ converts string to pchar with memory allocation }
Function GetString(Var S:TStream):String;
{ Taking string from stream }
Procedure PutString(Str:String;Var S:TStream);
{ writing string to stream }
Function ReadStr(Var F:Text):string;

 Type
      PStringArr=^TStringArr;
      TStringArr=object(TCollection)
       Constructor Init;
       { initialize collection }
       Procedure TakeData(Var S:TStream);virtual;
       Constructor Load(Var S:TStream);
       { filling from stream }
       Procedure Store(Var S:TStream);virtual;
       { writing to stream }
       Procedure Put(Str:String);
       { pushes Str into collection }
       Function Get(Index:Word):String;
       { takes Index item from collection }
       Procedure FreeItem(Item:Pointer);virtual;
       { standart procedure to clear space after use }
       Function Search(Str:String):Integer;
       { searching for str using _same; -1 returing if not found }
       Function SearchPart(Part:String;Index:Byte):Integer;
       { searching all Index parts for Part,using _same; -1 if not found }
       Function SearchInPart(Part:String):Integer;
       { searchin ALL parts for Part, using _same; -1 if not found }
       Procedure ReadCount(Var F:Text;Lines:Integer);
       { read in Count lines. if Count=-1 then read to the end }
       Procedure ReadTO(Var F:Text;EndLine:String);
       { read in file until the EndLine, EndLine is not read }
       Function Copy(Index,Lines:Integer):PStringArr;
       { creates new collection starting at Index,Count lines
          - it copies strings, two collections are not pointer-crossing }
       Function Move(Index,Lines:Integer):PStringArr;
       { creates new collection, and deletes old items }
       Function CopyIn(StartL,EndL:integer):PStringArr;
       { creates new collection from then [StartL;EndL] lines }
       Procedure Delete(Index,Lines:integer);
       { deletes items }
       Procedure AddMove(StrArr:PStringArr);
       { add to the end StrArr and deletes old collection
          ! it copies strings, doesn`t pointers }
       Procedure AddCopy(StrArr:PStringArr);
       { add to the end StrArr
          ! it copies string, doesn`t pointers }
       function MaxLenNum:word;
      end;

 Procedure ShowStrArr(S:PStringArr);
 Function ArgTail(S:String):string;

Procedure  UpCaseStr (VAR S : String) ;
Procedure  FormatStr (var s : string) ;
Function   Arguments (s : String) : byte ;
Function   Argument  (s : String ; n : Byte) : String ;
Function   Same      (s, s1 : String) : Boolean ;

Implementation

Uses misc,core,strings,fx_file;

Function LastPos(sub,s:string):byte;
var a:byte;
begin
 LastPos:=0;
 for a:=1 to Length(s) do if Same(Sub,copy(s,a,Length(sub)))
                          then LastPos:=a
end;

function FindArgument(SObject,Part:String):Integer;
  var a:byte;
 begin
  for a:=0 to Arguments(SObject) do
      if Same(Argument(SObject,a),Part)
      then begin
            FindArgument:=a;
            Exit;
           end;
  FindArgument:=-1;
 end;

 Function StrToChar(Str:String):PChar;
  var StrPtr:PChar;
 begin
  GetMem(StrPtr,Length(Str)+1);
  StrPCopy(StrPtr,Str);
  StrToChar:=StrPtr;
 end;

 function GetString(Var S:TStream):String;
  var p:Pstring;
 begin
  p:=S.ReadStr;
  if p<>nil
  then GetString:=P^
  else GetString:='';
  DisposeStr(P);
 end;

 Procedure PutString(Str:String;Var S:TStream);
 begin
  S.WriteStr(@Str);
 end;

 Procedure ShowStrArr(S:PStringArr);
  var a:integer;
 begin
  If Not Assigned(S) then Exeption(cFATAL_ERR,'Trying to show not assigned TSTringArr');
  for a:=0 to S^.Count-1 do Writeln(S^.Get(a));
 end;

      Constructor TStringArr.Init;
      begin
       TCollection.Init(cStringLimit,cStringGrow);
      end;

      Procedure TStringArr.TakeData;
       var i,NumOfItems:integer;
      begin
       S.Read(NumOfItems,2);
       for i:=0 to NumOfItems-1 do Put(GetString(S));
      end;

      Constructor TStringArr.Load;
      begin
       Init;
       TakeData(S);
      end;
      function TStringArr.maxlennum;
       var a,s:integer;
      begin
       s:=0;
       for a:=1 to count-1 do if length(get(a))>length(get(s)) then s:=a;
       maxlennum:=s;
      end;

      Procedure TStringArr.Store;
       var i:integer;
           Cnt:Integer;
      begin
       Cnt:=Count;
       S.Write(Cnt,SizeOf(Cnt));
       for i:=0 to Count-1 do PutString(Get(i),S);
      end;

      Procedure TStringArr.Put(Str:String);
      begin
       If Str<>''
       then Insert(StrToChar(Str));
      end;

      Function TStringArr.Get(Index:Word):String;
      begin
       if Index<Count
       then Get:=StrPas(At(Index))
       else begin
             Exeption(cPLAIN_ERR,'Collection index out of range.');
             Get:='';
            end;
      end;

      Procedure TStringArr.FreeItem;
      begin
       StrDispose(Item);
      end;

      Function TStringArr.Search;
       var i:integer;
      begin
       for i:=0 to Count-1 do
        If Same(Get(i),Str)
        then begin
         Search:=i;
         Exit;
        end;
       Search:=-1;
      end;
      Function TStringArr.SearchPart;
       var i:integer;
      begin
       for i:=0 to Count-1 do
        If Same(Argument(Get(i),Index),Part)
        then begin
         SearchPart:=i;
         Exit;
        end;
       SearchPart:=-1;
      end;
      Function TStringArr.SearchInPart;
       var i,arg:integer;
           temp:string;
      begin
       for i:=0 to Count-1 do
        for arg:=0 to Arguments(Get(i)) do
         if Same(Part,Argument(Get(i),arg))
         then begin
          SearchInPart:=i;
          Exit;
         end;
       SearchInPart:=-1;
      end;
      Procedure TStringArr.ReadCount;
       var i:integer;
      begin
       If Lines>=0
       then While Lines>-1 do begin
         Dec(Lines);
         If Not EOF(F) then Put(ReadStr(F));
        end
       else While not eof(f) do Put(ReadStr(F));
      end;
      Procedure TStringArr.ReadTO;
       var S:String;
      begin
       S:=ReadStr(F);
       While Not Same(S,EndLine) do
       begin
        Put(S);
        S:=ReadStr(F);
       end;
      end;
      Function TStringArr.Copy;
       var i:integer;
           CopyColl:PStringArr;
      begin
       New(CopyColl,Init);
       for i:=Index to Index+Lines-1 do CopyColl^.Put(Get(i));
       Copy:=CopyColl;
      end;
      Function TStringArr.Move;
       var i:integer;
           CopyColl:PStringArr;
      begin
       New(CopyColl,Init);
       for i:=0 to Lines-1 do
           begin
            CopyColl^.Put(Get(Index));
            AtFree(Index);
           end;
       Move:=CopyColl;
      end;
      Procedure TStringArr.Delete;
       var i:integer;
      begin
       for i:=1 to Lines do AtFree(Index);
      end;
      Procedure TStringArr.AddMove;
       var i:Integer;
      begin
       for i:=0 to StrArr^.Count-1 do Put(StrArr^.Get(i));
       StrArr^.FreeAll;
      end;
      Procedure TStringArr.AddCopy;
       var i:Integer;
      begin
       for i:=0 to StrArr^.Count-1 do Put(StrArr^.Get(i));
      end;
      Function TStringArr.CopyIn(StartL,EndL:integer):PStringArr;
      { creates new collection from then [StartL;EndL] lines }
       var a:integer;
           CopyBlock:PStringArr;
      begin
       CopyBlock:=New(PStringArr,Init);
       for a:=StartL to EndL do CopyBlock^.Put(Get(a));
       CopyIn:=CopyBlock;
      end;

procedure UpcaseStr(var s:string);
 var
     a:byte;
 function UpCaseCh ( ch : char ) : char ;
  begin
    if (ch>='a') and (ch<='z') then
      ch:=chr (ord ('A')+ord (ch)-ord ('a'))
    else
      if (ch>='а') and (ch<='п') then
        ch:=chr (ord ('А')+ord (ch)-ord ('а'))
      else
        if (ord (ch)>=224) and (ch<='я') then
          ch:=chr(ord ('Р')+ord (ch)-224) ;
    UpCaseCh:=ch ;
  end ;
begin
 for a:=1 to length(s) do s[a]:=upcasech(s[a]);
end;

  FUNCTION Empty( s: STRING ): BOOLEAN; ASSEMBLER;
  ASM
         CLD
         XOR   CH, CH
         LES   DI, s
         MOV   CL, BYTE PTR ES:[DI]
         JCXZ  @@1
         INC   DI
         MOV   AL, ' '
         REPE  SCASB
         JZ    @@1          { empty }
         MOV   AL, False
         JMP   @@2
  @@1:   MOV   AL, True
  @@2:
  END;


  FUNCTION StrTran( Source, Old, New : STRING ) : STRING;
  VAR p : INTEGER;
  BEGIN
       WHILE POS( Old, Source ) <> 0 DO BEGIN
             p := POS( Old, Source );
             DELETE( Source, p, LENGTH( Old ) );
             INSERT( New, Source, p );
       {W}END;
       StrTran := Source;
  END; { StrTran }


  FUNCTION LTrim( s: STRING; c: CHAR ): STRING; Assembler;
  ASM
        PUSH   DS
        LDS    SI, s
        XOR    AX, AX
        LODSB
        XCHG   AX, CX
        LES    DI, @Result
        INC    DI
        JCXZ   @@2

        MOV    BL, c
        CLD
  @@1:  LODSB
        CMP    AL, BL
        LOOPE  @@1
        DEC    SI
        INC    CX
        REP    MOVSB

  @@2:  XCHG   AX, DI
        MOV    DI, WORD PTR @Result
        SUB    AX, DI
        DEC    AX
        STOSB
        POP    DS
  END;


  FUNCTION RTrim( s: STRING; c: CHAR ): STRING;
  BEGIN
        WHILE (LENGTH(s) > 0) AND (s[LENGTH(s)] = c) DO DEC(s[0]);
        RTrim := s;
  END;

  FUNCTION AllTrim( str : STRING ) : STRING;
  BEGIN
       IF LENGTH( Str ) > 0 THEN
           AllTrim := LTrim(RTrim(str, ' '), ' ')
       ELSE
           AllTrim := Str;
  END;


  FUNCTION CharPos(CharToFind: CHAR; Source: STRING; Offs:byte): BYTE;
  ASSEMBLER;
  ASM
          CLD

          XOR AX,AX

          LES DI,[Source]
          MOV CX,[ES:DI]
          XOR CH,CH
          MOV AL,[Offs]
          XOR BH,BH
          INC AL
          CMP AL,CL
          JA @@Done

          DEC AL
          SUB CX,AX
          ADD DI,AX
          INC DI

          XOR BH,BH
          MOV BL,CL
          MOV AL,[CharToFind]
          REPNE SCASB
          JNE @@Done

          SUB BL,CL
          MOV BH,BL
          ADD BH,[Offs]

  @@Done:
          MOV AL,BH
  END;


  FUNCTION StringExtract(Source: STRING; Offs: BYTE; Count: BYTE): STRING;
  ASSEMBLER;
  ASM
          CLD

          PUSH DS

          XOR AX,AX
          XOR BX,BX
          XOR CX,CX

          LDS SI,[Source]
          LES DI,[@Result]
          LODSB
          MOV BL,[Offs]
          CMP BL,AL
          JAE @@DoneZero

          ADD SI,BX
          MOV CL,[Count]
          ADD BX,CX
          CMP BX,AX
          JBE @@MoveIt

          SUB BX,AX
          SUB CX,BX

  @@MoveIt:
          MOV [ES:DI],CL
          INC DI
          SHR CX,1
          JNC @@DoWords

          MOVSB

  @@DoWords:
          REP MOVSW
          JMP @@Done

  @@DoneZero:
          XOR AL,AL
          MOV [ES:DI],AL

  @@Done:
          POP DS
  END;


  FUNCTION StringRemove(Source: STRING; Offs: BYTE; Count: BYTE): STRING;
  ASSEMBLER;
  ASM
          CLD

          PUSH DS

          XOR AX,AX
          XOR CX,CX

          LDS SI,[Source]
          LES DI,[@Result]

          LODSB
          MOV CL,[Offs]
          CMP CL,AL
          JBE @@Ok

          MOV CL,0
          MOV [Count],CL
          MOV [Offs],CL

  @@Ok:
          SUB AX,CX
          MOV BX,DI
          INC DI
          SHR CX,1
          JNC @@DoWords1

          MOVSB

  @@DoWords1:
          REP MOVSW

          MOV CL,[Count]
          CMP CX,AX
          JBE @@MoveIt

          MOV CX,AX

  @@MoveIt:
          MOV DX,AX
          SUB DX,CX
          ADD SI,CX
          MOV CX,DX

          SHR CX,1
          JNC @@DoWords2

          MOVSB

  @@DoWords2:
          REP MOVSW

          ADD DL,[Offs]
          MOV [ES:BX],DL

          POP DS
  END;

  FUNCTION StringInsert(SubString: STRING; Source: STRING; Offs: BYTE): STRING;
  ASSEMBLER;
  VAR
          BeforeCount: WORD;
          InCount: WORD;
          AfterCount: WORD;
  ASM
          PUSH DS

          CLD

          MOV [BeforeCount],0
          MOV [InCount],0
          MOV [AfterCount],0

          LES DI,[@Result]
          INC DI

          LDS SI,[SubString]
          XOR CX,CX
          MOV CL,[DS:SI]

          LDS SI,[Source]
          XOR AX,AX
          MOV AL,[DS:SI]
          INC SI

          XOR BX,BX
          MOV BL,[Offs]

          CMP BX,AX
          JB @@Adjust1

          MOV [BeforeCount],AX
          MOV BX,AX
          JMP @@DoCopies

  @@Adjust1:
          MOV [BeforeCount],BX
          SUB AX,BX
          ADD BX,CX
          CMP BX,255
          JBE @@Adjust2

          SUB BX,255
          SUB CX,BX
          MOV [InCount],CX
          MOV BX,255
          JMP @@DoCopies

  @@Adjust2:
          MOV [InCount],CX
          ADD BX,AX
          CMP BX,255
          JA @@Ohoh

          MOV [AfterCount],AX
          JMP @@DoCopies

  @@Ohoh:
          SUB BX,255
          SUB AX,BX
          MOV [AfterCount],AX
          MOV BX,255

  @@DoCopies:
          MOV CX,[BeforeCount]
          JCXZ @@DoIn

          SHR CX,1
          JNC @@DoWords1

          MOVSB

  @@DoWords1:
          REP MOVSW

  @@DoIn:
          MOV CX,[InCount]
          JCXZ @@DoAfter

          LDS SI,[SubString]
          INC SI

          SHR CX,1
          JNC @@DoWords2

          MOVSB

  @@DoWords2:
          REP MOVSW

  @@DoAfter:
          MOV CX,[AfterCount]
          JCXZ @@DoNothing

          LDS SI,[Source]
          INC SI
          ADD SI,[BeforeCount]

          SHR CX,1
          JNC @@DoWords3

          MOVSB

  @@DoWords3:
          REP MOVSW

  @@DoNothing:
          MOV AX,[WORD PTR @Result]
          MOV DI,AX
          MOV [ES:DI],BL

  @@Done:
          POP DS
  END;



  FUNCTION RightAt( sub: STRING; s: STRING ): BYTE; ASSEMBLER;
  VAR
     nResult: WORD;
  ASM
        MOV     nResult,0
        PUSH    DS
        XOR     CX, CX

        LDS     SI, sub
        XOR     AX, AX
        LODSB
        MOV     BX, AX
        CMP     BX, 0
        JBE     @@3

        LES     DI, s
        XOR     DX, DX
        MOV     DL, BYTE PTR ES:[DI]
        INC     DI
        CMP     DX, 0
        JBE     @@3

        PUSH    DX

        CMP     BX, DX
        JAE     @@3

        DEC     BX
        CLD
  @@1:  MOV     SI, WORD PTR sub
        INC     SI
        LODSB

        MOV     CX, DX
        REPNE   SCASB
        JNZ     @@3

        MOV     DX, CX
        MOV     CX, BX
        REPE    CMPSB
        JZ      @@4

        ADD     DI, CX
        SUB     DI, BX
  @@2:  CMP     DX, BX
        JA      @@1
  @@3:  XOR     AL, AL
        JMP     @@5
  @@4:  SUB     DI, BX
        DEC     DI
        SUB     DI, WORD PTR s
        MOV     nResult, DI
        ADD     DI, WORD PTR s
        ADD     DI,CX
        INC     DI
        JMP     @@2
  @@5:
        POP     BX
        MOV     AX, nResult
        CMP     AX, 0
        JE      @@6
        XCHG    AX, BX
        SUB     AX, BX
        INC     AX
  @@6:  POP     DS
  END;


  Function HowMany (var str1,str2) : integer ;
  begin
  Inline(                  {Assembly by Inline 02/23/88 21:28}
                           {;Function HowMany(var str1,str2):integer;}
                           {;str1 and str2 are strings of any type.}
                           {;function compares them character by}
                           {;character for up to min(length(str1),length(str2))}
                           {;characters.  Function is the number of consecutive}
                           {;characters (starting with string 1) for which the}
                           {;two strings are equal. e.g., if str1 is cats and}
                           {;str2 is catchup, function result is 3.  If str1 is}
                           {;cat and str2 is dog, function result is 0.}
    $1E/                   {        push    ds}
    $C5/$B6/>STR1/         {        lds     si, >str1[bp]   ;addressing str1}
    $C4/$BE/>STR2/         {        les     di, >str2[bp]   ;addressing str2}
    $31/$C9/               {        xor     cx,cx           ;zero cx}
    $8A/$0D/               {        mov     cl,[di]         ;get length str2}
    $3A/$0C/               {        cmp     cl,[si]         ;compare lengths}
    $72/$02/               {        jb      diless}
    $8A/$0C/               {siless: mov     cl, [si]}
    $89/$CB/               {diless: mov     bx, cx          ;save length}
    $E3/$0A/               {        jcxz    j2}
    $FC/                   {        cld                     ;move forward}
    $46/                   {        inc     si              ;to start of string}
    $47/                   {        inc     di              ; "}
    $F3/$A6/               {repe    cmpsb                   ;string compare}
    $74/$01/               {        je      j1              ;equal for full length}
    $41/                   {        inc     cx              ;correct, last byte ne}
    $29/$CB/               {j1:     sub     bx,cx           ;# matching bytes}
    $89/$5E/$FE/           {j2:     mov     [bp-2],bx       ;function result}
    $1F);                  {        pop     ds}
  end;



  Function Equal_Structures (var a,b;size:integer) : boolean ;
  begin
  Inline(                  {Assembly by Inline 02/23/88 21:28}
    $1E/                   {       push   ds}
    $C6/$46/$FF/$01/       {       mov    by [bp-1],1  ;set up a true result}
    $C4/$BE/>A/            {       les    di,>a[bp]     ;get first structure, es:di}
    $C5/$B6/>B/            {       lds    si,>b[bp]     ;get second structure, ds:si}
    $8B/$8E/>SIZE/         {       mov    cx,>size[bp]  ;get length of structures}
    $FC/                   {       cld}
    $F3/$A6/               {repe   cmpsb                ;compare, byte by byte}
    $74/$04/               {       je     quit          ;if still equal, done}
    $C6/$46/$FF/$00/       {       mov    by [bp-1],0  ;set result for unequal}
    $1F);                  {quit:  pop    ds}
  end;


  Function Arguments(S:String):Byte;
   var a,i:Byte;
  begin
   i:=0; for a:=1 to Length(S) do if S[a]=' ' then Inc(I);
   Arguments:=i;
  end;

  Function Argument (s : String ; n : Byte) : String ;
  Var
    i, j, k, l : Byte ;
  Begin
    i := 0 ;
    j := 0 ;
    While i <> n do
     begin
      k := CharPos (' ', s, j) ;
      if k <> 0 then
        begin
          j := k ;
          inc (i) ;
        end
      else
        begin
         Argument:='';
         Exit;
        end ;
     end ;
    i := CharPos (' ', s, j) ;
    if i <> 0 then
      Argument := StringExtract (s, j, i - 1 - j)
    else
      Argument := StringExtract (s, j, length (s) - j) ;
  End ;

  Function   Same      (s, s1 : String) : Boolean ;
  Var
    i : Integer ;
  Begin
   UPCaseStr(s);
   UpCaseStr(S1);
    if length (s) <> length (s1) then
      Same := FALSE
    else
      Same := S1=S;
  End ;

  Procedure FormatStr (var s:string) ;
  Var
    st : string ;
    i : integer ;
  Begin
    st:='' ;
    if not empty (s) then
      begin
{        S := StrTran (S,',',' ') ;}
        i := CharPos (';', s, 0) ;
        if i <> 0 then
          S := StringRemove (S, i - 1, length (s) - i + 1) ;
        i := CharPos (' ', s, 0) ;
        s := AllTrim (s) ;
        while i <> 0  do
          begin
            s:=LTrim (s,' ') ;
            st := st + StringExtract (s, 0, i) ;
            s := StringRemove (s, 0, i) ;
            i := CharPos (' ', s, 0) ;
          end ;
      end ;
    s := st + s ;
  End ;

  {=Unit Initialisation==============================================}

 Function TOByte(S:String):Byte;
  var tmp:byte;
      code:integer;
 begin
  Val(S,Tmp,Code);
  TOByte:=Tmp;
 end;
 Function TOInt(S:String):Integer;
  var tmp:integer;
      code:integer;
 begin
  Val(S,Tmp,Code);
  TOint:=Tmp;
 end;
 Function TOWord(S:String):Word;
  var tmp:Word;
      code:integer;
 begin
  Val(S,Tmp,Code);
  TOWord:=Tmp;
 end;
 Function TOLong(S:String):LongInt;
  var tmp:LongInt;
      code:integer;
 begin
  Val(S,Tmp,Code);
  TOLong:=Tmp;
 end;
 Function TOReal(S:String):Real;
  var tmp:real;
      code:integer;
 begin
  Val(S,Tmp,Code);
  TOReal:=Tmp;
 end;

 function ReadStr;
  var s:string;
 begin
  readln(f,s);
  formatstr(s);
  readstr:=s;
 end;
function ArgTail(S:String):string;
 var name:string;
begin
 Name:=Argument(s,0);
 ArgTail:=Copy(s,Pos(Name,s)+Length(Name)+1,255);
end;

end.
