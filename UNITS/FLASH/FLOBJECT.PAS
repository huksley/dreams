Unit FlObjects;

interface

Uses Objects,TPStr,TpParam,FlashCom,
     TpTimeLine,Constants;

type TString = string[75];
     IdentString = string[16]; { identifier string }

     PIdentifiers = ^TIdentifiers;
     TIdentifiers = object(TStringArr)
      procedure Change(Ident:IdentString);
      { / syntax /
       <ident>   // puts identifier in array
       -<ident>  // deletes ident if exist
       -*        // deletes all idents
       -#<num>   // deletes <num>-ident }
     end;

type PFlashObject = ^TFlashObject;
     TFlashObject = object(TObject)
      { standart data }
      Name     : IdentString;  { identifier         }
      PlayName : TString;      { in-play name       }
      Reskey   : TString;      { resources          }
      Kind     : TClassId;
      { init/done }
      constructor init(AName:IdentString; APlayName:TString);
      procedure restore(var S:TStream); virtual;
      procedure save(var S:TStream); virtual;
      { standart procedures }
      procedure chField(Field:IdentString; Value:tstring); virtual;
      function  ifField(Field:IdentString; Value:tstring):boolean; virtual;
      procedure Process(Field:IdentString; Value:tstring; var f:text); virtual;
      procedure Compile(Var F:Text);
     end;

     PFlashCommon = ^TFlashCommon;
     TFlashCommon = object(TFlashObject)
      { common data }
      Acts    : PCommands;
      Text    : PStringArr;
      Params  : PParamColl;
      { init/done }
      constructor init(AName:IdentString; APlayName:TString);
      procedure restore(var S:TStream); virtual;
      procedure save(var S:TStream); virtual;
      destructor  done; virtual;
      { overrided procedures }
      procedure chField(Field:IdentString; Value:tstring); virtual;
      function ifField(Field:IdentString; Value:tstring):boolean; virtual;
      procedure Process(Field:IdentString; Value:tstring; var f:text); virtual;
     end;

     PPlayer = ^TPlayer;
     TPlayer = object(TFlashCommon)
      Place   : IdentString;
      Things  : PIdentifiers;
      { init/done }
      constructor init(AName:IdentString; APlayName:TString);
      procedure restore(var S:TStream); virtual;
      procedure save(var S:TStream); virtual;
      destructor  done; virtual;
      { overrided procedures }
      procedure chField(Field:IdentString; Value:tstring); virtual;
      function ifField(Field:IdentString; Value:tstring):boolean; virtual;
      procedure Process(Field:IdentString; Value:tstring; var f:text); virtual;
     end;

     PThing  = ^TThing;
     TThing  = object(TFlashCommon)
      Place   : IdentString;
      procedure restore(var S:TStream); virtual;
      procedure save(var S:TStream); virtual;
      { overrided procedures }
      procedure chField(Field:IdentString; Value:tstring); virtual;
      function ifField(Field:IdentString; Value:tstring):boolean; virtual;
      procedure Process(Field:IdentString; Value:tstring; var f:text); virtual;
     end;

     PLocation = ^TLocation;
     TLocation = object(TFlashCommon)
      Things     : PIdentifiers;
      Directions : PStringArr;
      { init/done }
      constructor init(AName:IdentString; APlayName:TString);
      procedure restore(var S:TStream); virtual;
      procedure save(var S:TStream); virtual;
      destructor  done; virtual;
      { overrided procedures }
      procedure chField(Field:IdentString; Value:tstring); virtual;
      function ifField(Field:IdentString; Value:tstring):boolean; virtual;
      procedure Process(Field:IdentString; Value:tstring; var f:text); virtual;
     end;

     PHuman = ^THuman;
     THuman = object(TPlayer)
     end;

     PAtmo = ^TAtmo;
     TAtmo = object(TFlashObject)
      Params  : PParamColl;
      TimeLine: PTimeLine;
      { init/done }
      constructor init(AName:IdentString; APlayName:TString);
      procedure restore(var S:TStream); virtual;
      procedure save(var S:TStream); virtual;
      destructor  done; virtual;
      { overrided procedures }
      procedure chField(Field:IdentString; Value:tstring); virtual;
      function ifField(Field:IdentString; Value:tstring):boolean; virtual;
      procedure Process(Field:IdentString; Value:tstring; var f:text); virtual;
     end;

     PAct = ^TAct;
     TAct = object(TFlashObject)
      Acts    : PCommands;
      Params  : TString;
      { init/done }
      constructor init(AName:IdentString; APlayName:TString);
      procedure restore(var S:TStream); virtual;
      procedure save(var S:TStream); virtual;
      destructor  done; virtual;
      { overrided procedures }
      procedure chField(Field:IdentString; Value:tstring); virtual;
      function ifField(Field:IdentString; Value:tstring):boolean; virtual;
      procedure Process(Field:IdentString; Value:tstring; var f:text); virtual;
      { other }
      procedure   Run(cParams:TString);
     end;

Type (* List definition *)
     PList=^TList;
     TList=object(TCollection)
      Procedure Put(Item:PFlashObject);
      Function Get(Index:Integer):PFlashObject;
      Function Find(cName:TString):PFlashObject;
      procedure restore(Var S:TStream);
      procedure save(Var S:TStream);
     end;
Var
    BaseName:String;
    (* base parts of program *)
    Player:PPlayer;
    Atmo:PAtmo;
    ThingList,
    LocList,
    ActList,
    HumanList:PList;
    CurrentLoc,LastLoc:PLocation;
    (* running part *)
    RunPart:PCommands;

Function FindIn(Name:String):PFlashObject;

implementation

 uses core,misc,flgraph;

     procedure TFlashObject.Restore;
     begin
      S.Read(Kind,Sizeof(Kind));
      Name:=GetString(S);
      PlayName:=GetString(S);
      Reskey:=GetString(S);
     end;
     procedure TFlashObject.Save;
     begin
      S.Write(Kind,Sizeof(Kind));
      PutString(Name,S);
      PutString(PlayName,S);
      PutString(Reskey,S);
     end;

     procedure TFlashCommon.Restore;
     begin
      inherited restore(s);
{      new(acts,init); acts^.load(s);}
      dispose(text,done); new(text,load(s));
      dispose(params,done); new(params,load(s));
     end;
     procedure TFlashCommon.Save;
     begin
      inherited save(s);
     { acts^.store(s); }
      text^.store(s);
      params^.store(s);
     end;

     procedure TPlayer.Restore;
     begin
      inherited restore(s);
      dispose(things,done); new(things,load(s));
      Place:=GetString(S);
     end;
     procedure TPlayer.Save;
     begin
      inherited save(s);
      things^.store(s);
      PutString(Place,S);
     end;

     procedure TThing.Restore;
     begin
      inherited restore(s);
      Place:=GetString(S);
     end;
     procedure TThing.Save;
     begin
      inherited save(s);
      PutString(Place,S);
     end;

     procedure TLocation.Restore;
     begin
      inherited restore(s);
      dispose(things,done); new(things,load(s));
      dispose(directions,done); new(directions,load(s));
     end;
     procedure TLocation.Save;
     begin
      inherited save(s);
      things^.store(s);
      directions^.store(s);
     end;

     procedure TAtmo.Restore;
     begin
      inherited restore(s);
      dispose(params,done); new(Params,load(s));
      Timeline^.restore(s);
     end;
     procedure TAtmo.Save;
     begin
      inherited save(s);
      params^.store(s);
      timeline^.save(s);
     end;

     procedure TAct.Restore;
     begin
      inherited restore(s);
      Params:=GetString(S);
{      new(Acts,init); acts^.load(s);}
     end;
     procedure TAct.Save;
     begin
      inherited save(s);
      PutString(Params,S);
{      acts^.store(s);}
     end;

Function FindIn(Name:String):PFlashObject;
var obj:Pointer;
begin
 if Same(Player^.Name,Name)
 then obj:=Player
 else if Same(Atmo^.Name,Name)
      then Obj:=Atmo
      else if ThingList^.Find(Name)<>Nil
           then Obj:=ThingList^.Find(Name)
           else if LocList^.Find(Name)<>Nil
                then Obj:=LocList^.Find(Name)
                else if ActList^.Find(Name)<>Nil
                     then Obj:=ActList^.Find(Name)
                     else if HumanList^.Find(Name)<>Nil
                          then Obj:=HumanList^.Find(Name)
                          else Obj:=Nil;
 FindIn:=Obj;
end;

     Procedure TList.Put;
     begin
      if Assigned(Item)
      then Insert(Item)
      else ErrorMSG('Trying to put unassigned object');
     end;
     Function TList.Get;
     begin
      If (Index<Count)and(Index>=0)
      then Get:=At(Index)
      else ErrorMSG('Index out of range');
     end;
     Function TList.Find;
      var I:Integer;
     begin
      For I:=0 to Count-1 do
       if Same(Get(I)^.Name,cName)
       then begin
        Find:=Get(I);
        Exit;
       end;
      Find:=Nil;
     end;
     procedure TList.save(Var S:TStream);
      var a:integer;
     begin
      a:=Count;
      S.Write(a,sizeof(a));
      for a:=0 to Count-1 do
       get(a)^.save(s);
     end;
     function TestKind(Var S:TStream):TClassId;
      var c:tclassid;
     begin
      S.Read(c,sizeof(c));
      S.Seek(S.GetPos-sizeof(c));
      TestKind:=c;
     end;
     procedure TList.Restore(Var S:TStream);
      var a,b:integer;
          p:pflashobject;
     begin
      S.Read(b,sizeof(b));
      for a:=0 to b-1 do begin
{       case TestKind(S) of
        nPLAYER : p:=new(PPlayer,Load(S));
        nATMO   : p:=new(PAtmo,Load(S));
        nTHING  : p:=new(PThing,Load(S));
        nLOC    : p:=new(PLocation,Load(S));
        nACT    : p:=new(PAct,Load(S));
        nHUMAN  : p:=new(PHUMAN,Load(S));
        else p:=nil;
       end;
       if p<>nil then Insert(p) else ErrorMSG('Read error');}
       get(a)^.restore(s);
      end;
     end;

     procedure TIdentifiers.Change;
     begin
      if Ident[1]<>'-'
      then Put(Ident)
      else case Ident[2] of
            '*' : Delete(0,Count);
            '#' : Delete(ToInt(System.Copy(Ident,3,255)),1);
            else  Delete(Search(System.Copy(Ident,2,255)),1);
           end;
     end;

procedure ChangeCommands(var Comms:PCommands; Value:tstring);
 var p:pflashitem;
begin
 p:=Comms^.GetName(Value);
 if p=nil
 then ErrorMsg(Str2PChar('Can`t run specified act '+Value))
 else p^.run;
end;

procedure ChangePlace(var Place:TString; Value:tstring);
begin
 Place:=Value;
end;
procedure ChangeThings(var Things:PIdentifiers; Value:IdentString);
begin
 Things^.Change(Value);
end;
procedure ChangeText(var Text:PStringArr; Value:tstring);
begin
 Text^.Put(Value);
end;
procedure ChangeParams(var Params:PParamColl; Value:tstring);
begin
 Params^.SetValue(Value);
end;
procedure ChangeDirs(var Dirs:PStringArr; Value:TString);
 var Act:IdentString;
     I:Integer;
begin
 Act:=Argument(Value,0);
 Value:=RestString(Value);
 UpcaseStr(Act);
      if act='ADD'      then Dirs^.Put(Value)
 else if act='DEL'      then begin
                              I:=Dirs^.SearchPart(Value,1);
                              if I<>-1
                              then Dirs^.Delete(I,1)
                              else ErrorMSG(Str2PChar('Can`t find dirID: '+Value));
                             end
 else if act='DELALL'   then Dirs^.Delete(0,Dirs^.Count);

end;

Procedure ReadThings(Things:PIdentifiers; Var F:Text);
begin
 Things^.ReadTO(f,cThingsEnd);
end;
Procedure ReadText(Desc:PStringArr; Var F:TExt);
begin
 Desc^.ReadTo(F,cDescEnd);
end;
Procedure ReadDirs(Dirs:PStringArr;Var F:Text);
begin
 Dirs^.ReadTo(F,'end');
end;
Procedure ReadParams(Params:PParamColl; var F:text);
 var s:TString;
begin
 S:=ReadStr(F);
 While not(Same(S,cParamsEnd)) do
  begin
   Params^.SetValue(S);
   S:=ReadStr(F);
  end;
end;
Procedure ReadActs(Name:string; Acts:PCommands;Var F:Text);
var P:PStringArr;
begin
 P:=New(PStringArr,Init);
 P^.ReadTo(F,'enddo');
 CompileCode(Acts,P,Name);
 Dispose(P,Done);
end;

     constructor TFlashObject.init;
     begin
      inherited init;
      Name:=AName;
      PlayName:=APlayName;
      upcasestr(Name);
     end;

var  CurrObj : PFlashObject;

procedure ObjError(Msg:string);
begin
 ErrorMSG(Str2PChar('ObjErr('+CurrObj^.Name+'): '+Msg));
end;

     procedure TFlashObject.process;
     begin
           if field='RES'          then Reskey:=Value
      else if field='PLAYNAME'     then PlayName:=Value;
     end;
     procedure TFlashObject.chField;
     begin
      CurrObj:=@Self;
      upcasestr(field);
           If Field='NAME'         then Name:=Value
      else If Field='PLAYNAME'     then PlayName:=Value
      else If Field='RESKEY'       then Reskey:=Value
      { Reskey part changing }
      else If Field='RESX'         then add_var('x',value,ResKey)
      else if field='RESY'         then add_var('y',value,ResKey)
      else if field='RESW'         then add_var('w',value,Reskey)
      else if field='RESH'         then add_var('h',value,reskey)
      else if field='RESCUR'       then add_var('cur',value,reskey)
      else if field='RESPIC'       then add_var('res',value,reskey)
      else if field='RESICO'       then add_var('icon',value,reskey);
     end;
     function TFlashObject.ifField;
      {$IFNDEF DELPHI}
      var result:boolean;
      {$ENDIF}
     begin
      CurrObj:=@Self;
      upcasestr(field);
      result:=false;
           if field='NAME'      then result:=Same(Name,value)
      else if field='PLAYNAME'  then result:=Same(Playname,value)
      else if field='RESX'      then result:=Same(Get_Var('x',ResKey),Value)
      else if field='RESY'      then result:=Same(Get_var('y',reskey),Value)
      else if field='RESW'      then result:=Same(Get_var('w',reskey),Value)
      else if field='RESH'      then result:=Same(Get_var('h',reskey),Value)
      else if field='RESCUR'    then result:=Same(Get_var('cur',reskey),Value)
      else if field='RESPIC'    then result:=Same(Get_var('res',reskey),Value)
      else if field='RESICO'    then result:=Same(Get_var('icon',reskey),Value);
      IfField:=result;
     end;
     procedure TFlashObject.Compile;
      var Field : IdentString;
          Value : TString;
          S     : String;
     begin
      CurrObj:=@Self;
      repeat
       s:=ReadStr(f); formatStr(s);
       field:=Argument(s,0);
       upcasestr(field);
       value:=RestString(s);
       process(field,value,f);
      until (field='END') or eof(f);
      if eof(f) then ErrorMSG('Unexpected eof');
     end;

     constructor TAct.init;
     begin
      inherited init(AName,APlayName);
      New(Acts,init);
     end;
     destructor TAct.done;
     begin
      dispose(Acts,done);
      inherited done;
     end;
     procedure TAct.chField;
     begin
      inherited chField(Field,Value);
      upcasestr(Field);
           if field='PARAMS'    then Params:=Value
      else if field='RUN'       then Run(Value);
     end;
     function  TAct.ifField;
      {$IFNDEF DELPHI}
      var result:boolean;
      {$ENDIF}
     begin
      result:=inherited ifField(Field,Value);
      UpCaseStr(Field);
           if field='PARAMS'    then result:=Same(Params,Value)
      else if field='ACT'       then result:=Acts^.Getname(Value)<>nil;
      IfField:=result;
     end;
     procedure TAct.Process;
     begin
      inherited process(field,value,f);
           if field='DO'        then ReadActs(Name,Acts,f)
      else if field='WITH'
           then Params:=Value;
     end;
     Procedure TAct.Run;
      var a:integer;
     begin
      if Same(Argument(Params,0),'#') and (cParams<>'')
      then begin
        InitReplace;ReplaceOn;
        for a:=0 to TOInt(Argument(Params,1))-1 do
          FlashCom.Replace( Argument(Params,2)+TOStr(a+1),
                            Argument(cParams,a));
        Acts^.Run;
        ReplaceOff;
        DoneReplace;
      end else if Same(Params,cParams) then Acts^.Run
                                       else Message('Can`t run act');
     end;
     constructor TAtmo.init;
     begin
      inherited init(AName,APlayName);
      New(Params,init);
      New(Timeline,init);
     end;
     destructor TAtmo.done;
     begin
      dispose(Params,done);
      dispose(Timeline,done);
      inherited done;
     end;
     procedure TAtmo.chField;
      var p:ptimeunit;
     begin
      inherited chField(Field,Value);
      upcasestr(Field);
           if field='PARAMS' then ChangeParams(Params,Value)
      else if field='PARAM'  then ChangeParams(Params,Value)
      else if field='EVENT'  then begin
                                   p:=TimeLine^.SearchEvent(Value);
                                   if p<>nil then p^.act^.run
                                   else ObjError('Can`t find '+Value+' event');
                                  end;
     end;
     function  TAtmo.ifField;
      {$IFNDEF DELPHI}
      var result:boolean;
      {$ENDIF}
     begin
      result:=inherited ifField(Field,Value);
      UpCaseStr(Field);
           if field='PARAMS'    then result:=Same(Params^.Value(Argument(Value,0)),RestString(Value))
      else if field='EVENT'     then result:=Same(Timeline^.CurrTimeEvent,Value);
      IfField:=result;
     end;
     procedure TAtmo.Process;
      var event:PTimeUnit;
     begin
      inherited process(field,value,f);
           if field='PARAMS'    then ReadParams(Params,f)
      else if field='PARAM'     then Params^.SetValue(Value)
      else if field='TIME'      then Timeline^.ReadTime(Field+' '+Value)
      else if field='TIMEEVENT' then begin
                                 new(Event,init);
                                 event^.read(f);
                                 Timeline^.Put(Event);
                                end;
     end;

     constructor TLocation.init;
     begin
      inherited init(AName,APlayName);
      new(Things,init);
      new(Directions,init);
     end;
     destructor TLocation.done;
     begin
      dispose(Things,done);
      dispose(Directions,done);
      inherited done;
     end;
     procedure TLocation.chField;
     begin
      inherited chField(Field,Value);
      upcasestr(field);
           if field='THINGS'    then ChangeThings(Things,Value)
      else if field='THING'     then ChangeThings(Things,Value)
      else if field='DIR'       then ChangeDirs(Directions,Value);
     end;
     function TLocation.ifField;
      {$IFNDEF DELPHI}
      var result:boolean;
      {$ENDIF}
     begin
      result:=inherited ifField(Field,Value);
      UpCaseStr(Field);
           if field='THING'     then result:=Things^.Search(Value)<>-1
      else if field='THINGS'    then result:=Things^.Search(Value)<>-1
      else if field='DIR'       then result:=Directions^.SearchPart(Value,1)<>-1;
      IfField:=result;
     end;
     procedure TLocation.process;
     begin
      inherited process(field,value,f);
           if field='THINGS' then ReadThings(Things,f)
      else if field='THING'  then Things^.put(Value)
      else if field='DIRS'   then ReadDirs(Directions,f);
     end;

     procedure TThing.chField;
     begin
      inherited chField(Field,Value);
      upcasestr(field);
      if field='PLACE' then Place:=Value;
     end;
     function TThing.ifField;
      {$IFNDEF DELPHI}
      var result:boolean;
      {$ENDIF}
     begin
      result:=inherited ifField(Field,Value);
      UpCaseStr(Field);
      if field='PLACE' then result:=Same(Place,value);
      IfField:=result;
     end;
     procedure TThing.process;
     begin
      inherited process(field,value,f);
      if field='PLACE' then Place:=Value
     end;

     constructor TPlayer.init;
     begin
      inherited init(AName,APlayName);
      new(Things,init);
     end;
     destructor TPlayer.done;
     begin
      dispose(Things,done);
      inherited done;
     end;
     procedure TPlayer.chField;
     begin
      inherited chField(Field,Value);
      upcasestr(field);
           if field='PLACE'     then Place:=Value
      else if field='THINGS'    then ChangeThings(Things,Value)
      else if field='THING'     then ChangeThings(Things,Value);
     end;
     function TPlayer.ifField;
      {$IFNDEF DELPHI}
      var result:boolean;
      {$ENDIF}
     begin
      result:=inherited ifField(Field,Value);
      UpCaseStr(Field);
           if field='PLACE'     then result:=Same(Place,value)
      else if field='THING'     then result:=Things^.Search(Value)<>-1
      else if field='THINGS'    then result:=Things^.Search(Value)<>-1;
      IfField:=result;
     end;
     procedure TPlayer.process;
     begin
      inherited process(field,value,f);
           if field='PLACE'     then Place:=Value
      else if field='THINGS'    then ReadThings(Things,f);
     end;

     constructor TFlashCommon.init;
     begin
      inherited init(AName,APlayName);
      New(Acts,init);
      New(Text,init);
      New(Params,init);
     end;
     destructor TFlashCommon.done;
     begin
      dispose(Acts,done);
      dispose(Text,done);
      dispose(Params,done);
      inherited done;
     end;
     procedure TFlashCommon.chField;
     begin
      inherited chField(Field,Value);
      upcasestr(Field);
           if field='TEXT'      then ChangeText(Text,Value)
      else if field='PARAMS'    then ChangeParams(Params,Value)
      else if field='PARAM'     then ChangeParams(Params,Value)
      else if field='RUN'       then ChangeCommands(Acts,Value);
     end;
     function  TFlashCommon.ifField;
      {$IFNDEF DELPHI}
      var result:boolean;
      {$ENDIF}
     begin
      result:=inherited ifField(Field,Value);
      UpCaseStr(Field);
           if field='PARAMS'    then result:=Same(Params^.Value(Argument(Value,0)),RestString(Value))
      else if field='PARAM'     then result:=Same(Params^.Value(Argument(Value,0)),RestString(Value))
      else if field='ACT'       then result:=Acts^.Getname(Value)<>nil;
      IfField:=result;
     end;
     procedure TFlashCommon.Process;
     begin
      inherited process(field,value,f);
           if field='DO'        then ReadActs(Name,Acts,f)
      else if field='TEXT'      then ReadText(Text,f)
      else if field='PARAMS'    then ReadParams(Params,f)
      else if field='PARAM'     then Params^.SetValue(Value);
     end;


begin
end.