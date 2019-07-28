Unit TPComms;

Interface

Uses TPstr;

 Const
      cActs=100;
      cConds=60;

 Type
      TActProc=procedure(s:string);
      TIfFunc=function(s:string):boolean;

      TActProcs=array[0..cActs-1] of TActProc;
      TActName=array[0..cActs-1] of String[15];

      TIfFuncs=array[0..cConds-1] of TIfFunc;
      TIfName=array[0..cConds-1] of String[15];

 Var
     Act: TActProcs;
 ActName: TActName;
    Acts: Word;

     Cond: TIfFuncs;
 CondName: TIfName;
    Conds: Word;

 Procedure InitComms;

 Procedure AppendComm(Name:string;Comm:TActProc);
 Procedure AppendIf(Name:string;Comm:TIfFunc);

 Function FindComm(Name:string):integer;
 Procedure MakeComm(Id:Integer;Params:string);

 Function FindCond(Name:String):Integer;
 Function MakeCond(Id:Integer; Params:string):Boolean;

implementation

Uses misc,core,flgraph;

 Procedure InitComms;
  var a:Word;
 begin
  Acts:=0;
  for a:=0 to cActs-1 do
  begin
   ActName[a]:='';
   Act[a]:=Nil;
  end;

  Conds:=0;
  for a:=0 to cConds-1 do
  begin
   CondName[a]:='';
   Cond[a]:=Nil;
  end;
 end;

 Procedure AppendComm(Name:string;Comm:TActProc);
 begin
  if Acts<cActs then
  begin
   Act[Acts]:=Comm;
   ActName[Acts]:=Name;
   Inc(Acts);
  end else FatalMSG('[AppendCom]: Not enough space to add new method');
 end;

 Procedure AppendIf(Name:string;Comm:TIfFunc);
 begin
  if Conds<cConds then
  begin
   Cond[Conds]:=Comm;
   CondName[Conds]:=Name;
   Inc(Conds);
  end else FatalMSG('[AppendIf]: Not enough space to add new ifmethod');
 end;

 Function FindComm(Name:string):integer;
  var a:word;
 begin
  for a:=0 to Acts do
   if Same(ActName[a],Name)
   then begin
    FindComm:=a;
    Exit;
   end;
  FindComm:=-1;
 end;

 Procedure MakeComm;
 begin
  if Id=-1
  then ErrorMSG(Str2PChar('Can`t find command '+TOStr(Id)))
  else Act[Id](Params);
 end;

 Function FindCond(Name:String):Integer;
  var a:word;
 begin
  for a:=0 to Conds do
   if Same(CondName[a],Name)
   then begin
    FindCond:=a;
    Exit;
   end;
  FindCond:=-1;
 end;

 Function MakeCond;
 begin
  if id=-1
  then ErrorMSG(Str2Pchar('Can`t find condition '+TOstr(Id)))
  else MakeCond:=Cond[Id](Params);
 end;

begin
 InitComms;
end.
