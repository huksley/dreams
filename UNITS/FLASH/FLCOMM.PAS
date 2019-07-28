{Unit FlComm;}

 Uses Crt,Objects,TpStr,Constants,misc,fx_strop,tpcomms;

 function RestString(Str:String):String;
 begin
  RestString:=Copy(Str,Pos(' ',Str)+1,255);
 end;

const cMaxEval = 16;
type  TCommandProc  = procedure(Cmd:Integer; Pars:string);
      TIfCondition  = function(Cmd:Integer; Pars:string):boolean;
      TCompileError = procedure(Msg:string);
Var   FlashMake:TCommandProc;
      FlashCond:TIfCondition;
      FlashErr :TCompileError;
      FlashLine:string;
      FlashNum :word;

type TTokenType = (tokUnknown,tokRun,tokEval,tokIf);
     TEvalOp    = (evalAnd,evalOr);
type PFlashItem = ^TFlashItem;
     TFlashItem = object(TObject)
      procedure Run; virtual;
      procedure Compile(Var Source:TStringArr; Var Index:Integer); virtual;
      function  TokenType(AToken:string):TTokenType; virtual;
     end;

     PCommand = ^TCommand;
     TCommand = object(TFlashItem)
      Command : Integer;
      Pars    : PString;
      procedure Run; virtual;
      function  Evaluate:boolean;
      procedure Compile(Var Source:TStringArr; Var Index:Integer); virtual;
      destructor Done; virtual;
     end;

     PEvaluate = ^TEvaluate;
     TEvaluate = object(TFlashItem)
      Evaluates : array[0..cMaxEval-1] of PCommand;
      EvaluateI : integer;
      EvalOp    : TEvalOp;
      function Evaluate:boolean;
      procedure Compile(Var Source:TStringArr; var Index:integer); virtual;
      destructor done; virtual;
     end;

     PCommands = ^TCommands;
     TCommands = object(TFlashItem)
      Commands : PCollection;
      Name : PString;
      constructor Init;
      destructor done; virtual;
      procedure Run; virtual;
      procedure Compile(var Source:TStringArr; var Index:integer); virtual;
     end;

     PCondition = ^TCondition;
     TCondition = object(TFlashItem)
      Evaluate : PEvaluate;
      ThenDo,ElseDo : PCommands;
      constructor Init;
      destructor done; virtual;
      procedure Run; virtual;
      procedure Compile(var Source:TStringArr; var Index:integer); virtual;
     end;

function TokenType(AToken:String):TTokenType;
     begin
      if Same(Argument(AToken,0),cIfName)
      then TokenType:=tokIf
      else if FindComm(Argument(AToken,0))<>-1
           then TokenType:=tokRun
           else if FindCond(Argument(AToken,0))<>-1
                then TokenType:=tokEval
                else TokenType:=tokUnknown;
     end;

function CreateNextToken(Token:String):PFlashItem;
 {$IFNDEF DELPHI}
 var result:PFlashItem;
 {$ENDIF}
begin
 Case TokenType(Token) of
  tokUnknown : result:=nil;
  tokRun     : result:=new(PCommands,init);
  tokEval    : result:=new(PEvaluate,init);
  tokIf      : result:=new(PCondition,init);
 end;
 {$IFNDEF DELPHI}
 CreateNextToken:=Result;
 {$ENDIF}
end;
     procedure TCondition.run;
     begin
      if Evaluate^.Evaluate
      then ThenDo^.Run
      else ElseDo^.Run;
     end;
     procedure TCondition.compile;
      var s:string;
     begin
      s:=Source.get(index);
      if Same(argument(s,1),'and')
      then Evaluate^.EvalOp:=evalAND
      else if Same(argument(s,1),'or')
           then Evaluate^.EvalOp:=evalOR
           else FlashErr('Can`t understand eval op:'+s);
      Evaluate^.Compile(Source,Index);
      ThenDo^.Compile(Source,Index);
      If not Same(Source.get(Index),cEND)
      then ElseDo^.Compile(Source,Index);
     end;
     constructor TCondition.Init;
     begin
      inherited init;
      new(Evaluate,init);
      new(Thendo,init);
      new(Elsedo,init);
     end;
     destructor TCondition.done;
     begin
      Dispose(Evaluate,done);
      Dispose(ThenDo,done);
      dispose(Elsedo,done);
     end;
     procedure TCommands.run;
      var a:integer;
     begin
      for a:=0 to Commands^.Count-1 do PFlashItem(Commands^.At(A))^.Run;
     end;
     procedure TCommands.compile;
      var curr:PFlashItem;
     begin
      while (not Same(Source.get(Index),cFlashCommEnd)) and
            (not Same(Source.get(Index),cEnd)) and
            (not Same(Source.get(Index),cElse)) do begin
       FlashLine:=Source.get(index);
       Inc(FlashNum);
       Curr:=CreateNextToken(Source.get(Index));
       if Curr=nil
       then FlashErr('Can`t compile next line into commands')
       else begin
        Curr^.Compile(Source,Index);
        Commands^.Insert(Curr);
       end;
      end;
     end;
     destructor TCommand.Done;
     begin
      DisposeStr(Pars);
      inherited done;
     end;
     destructor TEvaluate.done;
      var a:integer;
     begin
      for a:=0 to EvaluateI-1 do Dispose(Evaluates[a],Done);
      inherited Done;
     end;
     constructor TCommands.Init;
     begin
      inherited init;
      New(Commands,Init(5,5));
      Name:=Nil;
     end;
     destructor TCommands.done;
     begin
      Dispose(Commands,done);
      inherited done;
     end;

     procedure TEvaluate.Compile;
     begin
      While Not Same(Source.Get(Index),cThen) do begin
       New(Evaluates[EvaluateI],Init);
       Evaluates[EvaluateI]^.Compile(Source,Index);
       Inc(EvaluateI);
       if EvaluateI=16
       then begin
        FlashErr('Too mush conditions');
        Exit;
       end;
      end;
     end;
     function TEvaluate.Evaluate;
      {$IFNDEF DELPHI}
       var result:boolean;
      {$ENDIF}
       var a:integer;
     begin
      case EvalOp of
       evalAND : result:=true;
       evalOr  : result:=false;
      end;
      for a:=0 to EvaluateI-1 do
        case EvalOp of
         evalAND : begin
                    result:=result and Evaluates[a]^.Evaluate;
                    if result=false then break;
                   end;
         evalOR  : begin
                    result:=result or Evaluates[a]^.Evaluate;
                    if result=true then break;
                   end;
        end;
      {$IFNDEF DELPHI}
      Evaluate:=result;
      {$ENDIF}
     end;

     procedure TCommand.Run;
     begin
      FlashMake(Command,Pars^);
     end;
     procedure TCommand.Compile;
      var S:String;
     begin
      S:=Source.Get(Index);
      Command:=FindComm(Argument(S,0));
      if Command=-1 then Command:=FindCond(Argument(S,0));
      if Command=-1 then FlashErr('Can`t find Comm or Cond Id for :'+Argument(S,0));
      Pars:=NewStr(RestString(S));
      Inc(Index);
      FlashLine:=Source.Get(index);
      Inc(FlashNum);
     end;
     function TCommand.Evaluate;
     begin
      Evaluate:=FlashCond(Command,Pars^);
     end;

     procedure TFlashItem.Run;
      begin
       Abstract;
      end;
    procedure TFlashItem.Compile;
     begin
      Abstract;
     end;
    function TFlashItem.TokenType;
     begin
      if Same(Argument(AToken,0),cIfName)
      then TokenType:=tokIf
      else if FindComm(Argument(AToken,0))<>-1
           then TokenType:=tokRun
           else if FindCond(Argument(AToken,0))<>-1
                then TokenType:=tokEval
                else TokenType:=tokUnknown;
     end;

 procedure DummyRun(Command:integer; pars:string);
 begin
  Writeln('Runid',Command,'pars :'+Pars);
 end;
 function DummyIf(Command:integer; pars:string):boolean;
 begin
  Writeln('Ifid ',Command,' pars :'+Pars);
  DummyIf:=Readkey='1';
 end;
 procedure Error(Msg:string);
 begin
  Writeln('Error :'+Msg);
  Writeln('Line(',FlashNum,')'+FlashLine);
  Halt;
 end;

 var p:PStringArr;
     f:text;
     c:PCommands;
     i:integer;
begin
 FlashMake:=DummyRun;
 FlashCond:=DummyIf;
 FlashErr:=Error;

 FlashNum:=1;
 New(P,init);
 assign(f,'1.txt');
 reset(f);
 P^.ReadCount(f,-1);
 New(C,init);
  i:=1;
  c^.compile(P^,i);
  c^.run;
 Dispose(C,done);
 Dispose(P,done);
 close(f);
end.

