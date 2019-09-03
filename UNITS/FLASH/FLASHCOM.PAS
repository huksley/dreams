Unit FlashCom;

interface

 uses objects,tpstr;

const cMaxEval = 16;
type  TCommandProc  = procedure(Cmd:Integer; Pars:string);
      TIfCondition  = function(Cmd:Integer; Pars:string):boolean;
      TCompileError = procedure(Msg:string);
Var   FlashMake:TCommandProc;
      FlashCond:TIfCondition;
      FlashErr :TCompileError;
      FlashLine:string;
      FlashObj :string;
      FlashNum :integer;
      Index    :integer;
      Condition:boolean;
      Source   :PStringArr;

type TTokenType = (tokUnknown,tokRun,tokEval,tokIf,tokComm,tokCase,tokWhile);
     TEvalOp    = (evalAnd,evalOr);
type PFlashItem = ^TFlashItem;
     TFlashItem = object(TObject)
      procedure Run; virtual;
      procedure Store(Var S:TStream); virtual;
      procedure Load(Var S:TStream); virtual;
      procedure Compile(Var Source:TStringArr); virtual;
      function  TokenType(AToken:string):TTokenType; virtual;
     end;

     PCommand = ^TCommand;
     TCommand = object(TFlashItem)
      Command : Integer;
      Pars    : PString;
      procedure Store(Var S:TStream); virtual;
      procedure Load(Var S:TStream); virtual;
      procedure Run; virtual;
      function  Evaluate:boolean;
      procedure Compile(Var Source:TStringArr); virtual;
      destructor Done; virtual;
     end;

     PEvaluate = ^TEvaluate;
     TEvaluate = object(TFlashItem)
      Evaluates : array[0..cMaxEval-1] of PCommand;
      EvaluateI : Shortint;
      EvalOp    : TEvalOp;
      procedure Store(Var S:TStream); virtual;
      procedure Load(Var S:TStream); virtual;
      function Evaluate:boolean;
      procedure Compile(Var Source:TStringArr); virtual;
      destructor done; virtual;
     end;

     PCommands = ^TCommands;
     TCommands = object(TFlashItem)
      Commands : PCollection;
      Name     : PString;
      constructor Init;
      destructor done; virtual;
      procedure Store(Var S:TStream); virtual;
      procedure Load(Var S:TStream); virtual;
      procedure Run; virtual;
      procedure RunSmall(AName:string);
      function GetName(AName:string):PCommands;
      procedure Compile(var Source:TStringArr); virtual;
     end;

     PCase     = ^TCase;
     TCase     = object(TFlashItem)
      CaseVar  : PString;
      CaseJmp  : PCommands;
      CaseElse : PCommands;
      constructor init;
      procedure Store(Var S:TStream); virtual;
      procedure Load(Var S:TStream); virtual;
      destructor Done; virtual;
      procedure  Run; virtual;
      procedure  Compile(Var Source:TStringArr); virtual;
     end;

     PWhile     = ^TWhile;
     TWhile     = object(TFlashItem)
      Cond: PEvaluate;
      Code: PCommands;
      constructor init;
      procedure Store(Var S:TStream); virtual;
      procedure Load(Var S:TStream); virtual;
      destructor done; virtual;
      procedure run; virtual;
      procedure compile(Var Source:TStringArr); virtual;
     end;

     PCondition = ^TCondition;
     TCondition = object(TFlashItem)
      Evaluate      : PEvaluate;
      ThenDo,ElseDo : PCommands;
      constructor Init;
      procedure Store(Var S:TStream); virtual;
      procedure Load(Var S:TStream); virtual;
      destructor done; virtual;
      procedure Run; virtual;
      procedure Compile(var Source:TStringArr); virtual;
     end;

 procedure CompileCode(Acts:PCommands; Source:PStringArr; Obj:String);

 Type
      PDoubleString=^TDoubleString;
      TDoubleString=Object(TObject)
       First,Second:String;
      end;

      PDStrColl=^TDStrColl;
      TDStrColl=Object(TCollection)
       Procedure Put(cFirst,cSecond:String);
       Function Get1(Index:Word):String;
       Function Get2(Index:Word):String;
       Function Show:PStringArr;
      end;

 Var SafeCommand:TCommandProc;
     SafeIf     :TIfCondition;

     ReplaceMode:Boolean;
     Replaces:PDStrColl;

     Procedure ReplaceConvert(Var Comm:string);

     Procedure ReplaceComm(Id:integer;Comm:String);
     Function IfRepComm(Id:integer;Comm:string):Boolean;

     Procedure InitReplace;
     Procedure DoneReplace;
     Procedure ReplaceOn;
     Procedure ReplaceOff;
     Procedure Replace(s1,s2:String);

 implementation

  uses flaction,constants,tpcomms,misc,core,fx_strop,flgraph;

   procedure NextLine;
   begin
    Inc(Index);
    Inc(FlashNum);
    If Index>=Source^.Count
    then FlashErr('End of text reached')
    else FlashLine:=Source^.Get(Index);
   end;

     procedure TCommands.RunSmall;
     begin
      GetName(AName)^.Run;
     end;
     function TCommands.GetName;
      var i:integer;
          p:PCommands;
     begin
      GetName:=Nil;
      for i:=0 to Commands^.Count-1 do begin
       p:=Commands^.At(i);
       if (typeof(p^)=typeof(TCommands)) and Same(pcommands(p)^.name^,aname)
       then begin
        GetName:=p;
        Exit;
       end;
      end;
     end;

function TokenType(AToken:String):TTokenType;
     begin
      if Same(Argument(AToken,0),'while')
      then TokenType:=tokWhile
      else
      if Same(Argument(AToken,0),'case')
      then TokenType:=tokCase
      else
      if Same(Argument(AToken,0),cFlashComm)
      then TokenType:=tokComm
      else
      if Same(Argument(AToken,0),cIfName)
      then TokenType:=tokIf
      else
      if FindComm(Argument(AToken,0))<>-1
      then TokenType:=tokRun
      else
      if FindCond(Argument(AToken,0))<>-1
      then TokenType:=tokEval
      else
      TokenType:=tokUnknown;
     end;

function CreateNextToken(Token:String):PFlashItem;
 {$IFNDEF DELPHI}
 var result:PFlashItem;
 {$ENDIF}
begin
 Case TokenType(Token) of
  tokUnknown : result:=nil;
  tokRun     : result:=new(PCommand,init);
  tokEval    : result:=new(PEvaluate,init);
  tokComm    : begin
                result:=new(PCommands,init);
                PCommands(result)^.Name:=NewStr(Argument(Token,1));
               end;
  tokIf      : result:=new(PCondition,init);
  tokCase    : result:=new(PCase,init);
  tokWhile   : result:=new(PWhile,init);
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
      S:=Source.get(index);
      { achieving operation type }
      if Same(argument(s,1),'and')
      then Evaluate^.EvalOp:=evalAND
      else if Same(argument(s,1),'or')
           then Evaluate^.EvalOp:=evalOR
           else FlashErr('Can`t understand eval op: '+s);

      { compiling conditions }
      nextline; Evaluate^.Compile(Source);
      { compiling then part }
      if not Same(Source.get(Index),'then')
      then FlashErr('Can`t find then')
      else begin
       nextline; ThenDo^.Compile(Source);
      end;
      { compiling else part }
      If not Same(Source.get(Index),cEND)
      then if not Same(Source.get(index),'else')
           then FlashErr('Expected else or end')
           else begin
            nextline; ElseDo^.Compile(Source);
           end;
      nextline;
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
      inherited done;
     end;
     procedure TCommands.run;
      var a:integer;
     begin
      for a:=0 to Commands^.Count-1 do PFlashItem(Commands^.At(A))^.Run;
     end;
     procedure TCommands.compile;
      var Curr:PFlashItem;
          CurrType : TTokenType;
     begin
      while not ( Same(Source.get(Index),cFlashCommEnd) or
                  Same(Source.get(Index),cEnd) or
                  Same(Source.get(Index),cElse) ) do begin
       CurrType:=TokenType(Source.get(index));
       Curr:=CreateNextToken(Source.get(Index));
       if Curr=nil then FlashErr('Can`t compile next line into commands')
       else begin
        { adjusting position }
        if CurrType = tokComm then nextline;
        Curr^.Compile(Source);
        if CurrType = tokComm then nextline;
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
      DisposeStr(Name);
      inherited done;
     end;

     procedure TEvaluate.Compile;
     begin
      Condition:=True;
      While (Not Same(Source.Get(Index),cThen)) and
            (Not Same(Source.Get(Index),'do')) do begin
       New(Evaluates[EvaluateI],Init);
       Evaluates[EvaluateI]^.Compile(Source);
       Inc(EvaluateI);
       if EvaluateI=16 then FlashErr('Too mush conditions');
      end;
      Condition:=False;
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
      if Pars<>nil
      then FlashMake(Command,Pars^)
      else FlashMake(Command,'');
     end;
     procedure TCommand.Compile;
      var S:String;
     begin
      S:=Source.Get(Index);
      if not Condition
      then Command:=FindComm(Argument(S,0))
      else Command:=FindCond(Argument(S,0));
      if Command=-1 then FlashErr('Unknown identifier');
      Pars:=NewStr(RestString(S));
      nextline;
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
      TokenType:=FlashCom.TokenType(AToken);
     end;

 procedure Error(Msg:string);
 begin
  putline_text('Compile error: '+Msg);
  putline_text(FlashObj+'('+ToStr(FlashNum+1)+'): '+FlashLine);
  show_text;
  Fatalmsg('Can`t proceed - exiting');
 end;

 procedure CompileCode;
 begin
  FlashObj:=Obj;
  FlashLine:='';
  FlashNum:=0;
  Index:=0;
  FlashCom.Source:=Source;
  if Source^.Count>0 then begin
   { patching for 'end' at end }
   Source^.put('end');
   { compiling data }
   Acts^.Compile(Source^);
  end;
 end;

      Procedure TDStrColl.Put;
       Var P:PDoubleString;
      begin
       New(P,Init);
       P^.First:=cFirst;
       P^.Second:=cSecond;
       Insert(P);
      end;

      Function TDStrColl.Get1;
       Var P:PDoubleString;
      begin
       P:=At(Index);
       Get1:=P^.First;
      end;

      Function TDStrColl.Get2;
       Var P:PDoubleString;
      begin
       P:=At(Index);
       Get2:=P^.Second;
      end;

      Function TDStrColl.Show;
       Var Index:Word;
           P:PStringArr;
      begin
       P:=New(PStringArr,Init);
       if Count>0
       then For Index:=0 to Count-1 do P^.Put(Get1(Index)+':'+Get2(Index));
       Show:=P;
      end;

     Procedure ReplaceConvert(Var Comm:string);
      Var Index:Word;
          S:String;
     begin
      S:=Comm;
      If ReplaceMode
      then if Replaces^.Count>0
           then For Index:=0 to Replaces^.Count-1 do
                    fx_strop.Replace(Replaces^.Get1(Index),
                                    Replaces^.Get2(Index),
                                    S);
      Comm:=S;
     end;

     Procedure ReplaceComm;
     begin
      ReplaceConvert(Comm);
      SafeCommand(Id,Comm);
     end;

     Function IfRepComm;
     begin
      ReplaceConvert(Comm);
      IfRepComm:=SafeIf(Id,Comm);
     end;

     Procedure InitReplace;
     begin
      New(Replaces,Init(1,1));
      ReplaceMode:=True;

      SafeCommand:=FlashMake;
      SafeIf     :=FlashCond;

      FlashMake:=ReplaceComm;
      FlashCond:=IfRepComm;
     end;
     Procedure DoneReplace;
     begin
      FlashMake:=SafeCommand;
      FlashCond:=SafeIf;
      ReplaceMode:=off;
      Dispose(Replaces,Done);
     end;
     Procedure ReplaceOn;
     begin
      ReplaceMode:=True;
     end;
     Procedure ReplaceOff;
     begin
      ReplaceMode:=off;
     end;
     Procedure Replace(s1,s2:String);
     begin
      Replaces^.Put(S1,s2);
     end;

      constructor TCase.init;
      begin
       new(CaseJmp,init);
       new(CaseElse,init);
      end;
      destructor TCase.Done;
      begin
       DisposeStr(CaseVar);
       Dispose(CaseJmp,Done);
       Inherited done;
      end;
      procedure  TCase.Run;
       var value:string[16];
      begin
       if Same(CaseVar^,'Query')
       then Value:=Quered
       else begin
        value:='$'+CaseVar^;
        GlobVarReplace(Value);
       end;
       if CaseJmp^.Getname(Value)=nil
       then CaseElse^.run
       else CaseJmp^.Getname(Value)^.run;
      end;
      procedure  TCase.Compile(Var Source:TStringArr);
       var curr:PCommands;
      begin
       CaseVar:=NewStr(Argument(Source.get(Index),1));
       nextline;
       while not same(Source.get(index),'end') do begin
        if Same(Argument(Source.get(index),0),'on')
        then begin
         new(Curr,Init);
         Curr^.name:=NewStr(Argument(Source.get(Index),1));
         nextline; Curr^.Compile(Source); nextline;
         CaseJmp^.Commands^.Insert(Curr);
        end else if Same(Argument(Source.get(index),0),'else')
                 then begin
                  nextline;
                  CaseElse^.Compile(Source);
                  nextline;
                 end;
       end; nextline;
      end;

      constructor TWhile.init;
       begin
        inherited init;
        New(Code,init);
        New(Cond,init);
       end;
      destructor TWhile.done;
      begin
       Dispose(Code,done);
       Dispose(Cond,done);
       inherited done;
      end;
      procedure TWhile.run;
      begin
       while Cond^.Evaluate do Code^.run;
      end;
      procedure TWhile.compile(Var Source:TStringArr);
      var s:string;
     begin
      S:=Source.get(index);
      { achieving operation type }
      if Same(argument(s,1),'and')
      then Cond^.EvalOp:=evalAND
      else if Same(argument(s,1),'or')
           then Cond^.EvalOp:=evalOR
           else FlashErr('Can`t understand loop op: '+s);

      { compiling conditions }
      nextline; Cond^.Compile(Source);
      { compiling then part }
      if not Same(Source.get(Index),'do')
      then FlashErr('Can`t find do of while')
      else begin
       nextline;
        Code^.Compile(Source);
       nextline;
      end;
      end;

{ Stream Load/Store procedures }
procedure TFlashItem.Store;
begin
 Abstract;
end;
procedure TFlashItem.Load;
begin
 Abstract;
end;

procedure TCommand.Store;
begin
 S.Write(Command,Sizeof(Command));
 S.WriteStr(Pars);
end;
procedure TCommand.Load;
begin
 S.Read(Command,Sizeof(Command));
 Pars:=S.ReadStr;
end;

procedure TEvaluate.Store;
 var a:shortint;
begin
 S.Write(EvalOp,Sizeof(EvalOp));
 S.Write(EvaluateI,Sizeof(EvaluateI));
 for a:=0 to EvaluateI-1 do
  Evaluates[a]^.Store(S);
end;
procedure TEvaluate.Load;
 var a:shortint;
begin
 S.Read(EvalOp,Sizeof(EvalOp));
 S.Read(EvaluateI,Sizeof(EvaluateI));
 for a:=0 to EvaluateI-1 do
  begin
   New(Evaluates[a],init);
   Evaluates[a]^.Load(S);
  end;
end;

procedure TCommands.Store;
 var a:integer;
     p1:pflashitem;
     p:pointer;
     t:TTokenType;
     w:word;
begin
 S.WriteStr(Name);
 w:=Commands^.Count;
 S.Write(w,sizeof(w));
 for a:=0 to Commands^.Count-1 do begin
  p1:=Commands^.at(a); p:=typeof(p1^);
        if p=typeof(TCommand)      then   t:=tokRun
  else  if p=typeof(TEvaluate)     then   t:=tokEval
  else  if p=typeof(TCommands)     then   t:=tokComm
  else  if p=typeof(TCondition)    then   t:=tokIf
  else  if p=typeof(TCase)         then   t:=tokCase
  else  if p=typeof(TWhile)        then   t:=tokWhile;
  S.Write(t,sizeof(t));
  p1^.Store(S);
 end;
end;
procedure TCommands.Load;
 var t:ttokentype;
     b,a:word;
     p:pflashitem;
begin
 Name:=S.ReadStr;
 S.Read(a,Sizeof(a));
 if a>0 then
  for b:=0 to a-1 do begin
   S.Read(t,sizeof(t));
   case t of
    tokRun     : p:=new(PCommand,Init);
    tokEval    : p:=new(PEvaluate,init);
    tokComm    : p:=new(PCommands,init);
    tokIf      : p:=new(PCondition,init);
    tokCase    : p:=new(PCase,init);
    tokWhile   : p:=new(PWhile,init);
    else         continue;
   end;
   p^.load(s);
  end;
end;
procedure TCondition.Store;
begin
 Evaluate^.Store(S);
 ThenDo^.Store(S);
 ElseDo^.Store(S);
end;
procedure TCondition.Load;
begin
 Evaluate^.Load(S);
 ThenDo^.Load(S);
 ElseDo^.Load(S);
end;
procedure TCase.Store;
begin
 S.WriteStr(CaseVar);
 CaseJmp^.Store(S);
 CaseElse^.Store(S);
end;
procedure TCase.Load;
begin
 CaseVar:=S.ReadStr;
 CaseJmp^.Load(S);
 CaseElse^.Load(S);
end;
procedure TWhile.Store;
begin
 Cond^.Store(S);
 Code^.Store(S);
end;
procedure TWhile.Load;
begin
 Cond^.Load(S);
 Cond^.Store(S);
end;

begin
 FlashErr:=Error;
end.

