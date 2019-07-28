Unit TpParam;
Interface
uses fx_strop,objects,tpstr;


Type  TParamClass=(cInt,cStr,cBol);

 Function FindClass(cValue:string):TParamClass;

Type
      PParam=^TParam;
      TParam=object(TObject)
       Param:String[15];
       Value:String[15];
       Kind:TParamClass;
       Constructor Reset;
       Constructor Init(cName,cValue:String);

       Constructor Load(Var S:TStream);
       Procedure Store(Var S:TStream);
      end;

      PParamColl=^TParamColl;
      TParamColl=Object(TCollection)
       Constructor Init;
       Procedure Put(P:PParam);
       Function Get(Index:Word):PParam;
       Function SearchRec(cParamName:string):PParam;
       Function Value(cParam:string):String;
       Procedure Param(cName,cValue:string);
       Procedure ChIntValue(cLine:string);
       Procedure SetValue(s:string);
       Procedure deletePar(s:string);
       Function IfValue(s:string):boolean;
       Procedure Show;
       Constructor Load(Var S:TStream);
       Procedure Store(Var S:TStream);
      end;

Implementation
Uses misc;

 Procedure TParamColl.deletePar;
  Var p:PParam;
 begin
  p:=SearchRec(s);
  if p<>nil then Delete(p);
 end;

Constructor TParamColl.Load;
 var i,Cnt:Integer;
begin
 Init;
 S.Read(Cnt,SizeOF(Cnt));
 for i:=0 to Cnt-1 do Put(New(PParam,Load(S)));
end;
Procedure TParamColl.Store;
 var i,Cnt:Integer;
begin
 Cnt:=Count;
 S.Write(Cnt,SizeOF(Cnt));
 for i:=0 to Cnt-1 do Get(I)^.Store(S);
end;
Constructor TParam.Reset;
begin
 TObject.Init;
 Param:='';Value:='';Kind:=cStr;
end;
Constructor TParam.Init;
begin
 Reset;
 Param:=cName;Value:=cValue;
 Kind:=FindClass(cValue);
end;
Constructor TParam.Load;
begin
 Init( GetString(S),GetString(S) );
 S.Read(Kind,SizeOF(Kind));
end;
Procedure TParam.Store;
begin
 PutString(Param,S);
 PutString(Value,S);
 S.Write(Kind,SizeOF(Kind));
end;
Function FindClass(cValue:string):TParamClass;
begin
 FindClass:=cStr;
 If(Same(cValue,'Yes'))or(Same(cValue,'No'))
  or(Same(cValue,'Да'))or(Same(cValue,'Нет'))
 then FindClass:=cBol;
 if (ToInt(cValue)<>0)or(Same(cValue,'0'))
 then FindClass:=cInt;
end;
Constructor TParamColl.Init;
begin
 TCollection.Init(1,3);
end;
Procedure TParamColl.Put;
begin
 Insert(P);
end;
Function TParamColl.Get;
begin
 Get:=At(Index);
end;
Function TParamColl.SearchRec;
var a:LongInt;
begin
 SearchRec:=Nil;
 for a:=0 to Count-1 do
  if Same(Get(a)^.Param,cParamName)
  then SearchRec:=Get(a);
end;
Function TParamColl.Value;
 var Par:PParam;
begin
 Par:=SearchRec(cParam);
 if Not Assigned(Par) then Value:='undefined' else Value:=Par^.Value;
end;
Procedure TParamColl.Param;
var P:PParam;
begin
 New(P,Init(cName,cValue));
 Put(P);
end;
Function DigInt(s:string):Boolean;
begin
 if (ToInt(s)<>0)or(s='0') then DigInt:=True else DigInt:=False;
end;
Function NoOp(s:string):boolean;
var a:integer;
    b:boolean;
begin
 {x=y}
 b:=False;
 for a:=1 to Length(s) do b:=b or (Belongs(Ord(s[a]),42,47));
 NoOp:=Not b;
end;
Procedure TParamColl.ChIntValue(cLine:string);
Var cParam:string;
    cValues,Val1,Val2:string;
    Op:string;
    a,b,c:longint;
    s:string;
begin
 { x=?y > 1:x,2:x?y }
 { x=y?z > 1:x,2:y?z }
 Replace('=',' ',cLine);
 FormatStr(cLine);
 cParam:=Argument(cLine,0);
 cValues:=Argument(cLine,1);
 If NoOp(cValues) then
 begin
  Val1:=cValues;
  Val2:='1';
  Op:='*';
 end else
 begin
  if Belongs(Ord(cValues[1]),42,47) then cValues:=cParam+cValues;
  for a:=1 to Length(cValues) do
  if Belongs(Ord(cValues[a]),42,47) then begin
                                         Op:=cValues[a];
                                         Replace(Op,' ',cValues);
                                        end;
  FormatStr(cValues);
  Val1:=Argument(cValues,0);
  Val2:=Argument(cValues,1);
 end;
 if not DigInt(Val1) then Val1:= Value(Val1);
 if not DigInt(Val2) then Val2:= Value(Val2);
 a:=TOLong(Val1);
 b:=TOLong(Val2);
 case Op[1] of
  '*':c:=a*b;
  '/':c:=a div b;
  '+':c:=a+b;
  '-':c:=a-b;
 end;
 s:=ToStr(c);
 SearchRec(cParam)^.Value:=s;
end;
Procedure TParamColl.SetValue;
 var i:integer;
begin
 if CharPos('=',S,0)<>0
 then for i:=0 to Length(S) do if s[i]='='
                               then s[i]:=' ';

 if Same(Argument(S,0),'set')
 then begin
       if SearchRec(Argument(s,1))<>Nil
       then SearchRec(Argument(s,1))^.Value:=Argument(s,2)
       else Param(Argument(s,1),Argument(s,2))
      end else if Same(Argument(S,0),'del')
               then DeletePar(Argument(S,1))
               else ChIntValue(S);
end;
Function TParamColl.IfValue;
begin
 IfValue:=Same(SearchRec(Argument(s,0))^.Value,Argument(s,1));
end;
Procedure TParamColl.Show;
 var a:integer;
begin
 for a:=0 to Count-1 do Writeln(Get(a)^.Param,'=',Get(a)^.Value);
end;

end.