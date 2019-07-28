Unit FlMain;

interface

Uses kernel,crt,fx_file,misc,core,TPStr,
     objects,Constants,TPParam,types,
     FlashCom,TPTimeLine,flobjects,flaction,
     SysInfo,time,fx_form;

const
      cLoadingPlayer = 'Загpyжается описание Игpока';
      cLoadingAtmo   = 'Загpyжается описание Окpyжения';
      cLoadingThing  = 'Загpyжается описание энкантеpа - ';
      cLoadingLoc    = 'Загpyжается описание локации - ';
      cLoadingAct    = 'Загpyжается описание акта - ';
      cLoadingHuman  = 'Загpyжается описание человека - ';
      cLoadingMain   = 'Загpyжается запyскаемая часть';

Type
    TSwitches=record
     IdRecord,
     CopyRight,
     Year,
     Version,
     MinorVersion:NString;
    end;

Function NewClass(cName,cPlayName,cResKey:TString;cClass:TClassId):Pointer;
Procedure DoneAll;
Procedure InitFile(Pr:PProcessBar; Var F:Text);
Procedure ConfigureSwitches(Var Switches:TSwitches;Var F:Text);

implementation
uses swset,tpdos,flgraph,fx_pens,fx_init;

(* workout procedures *)
Function NewClass(cName,cPlayName,cResKey:TString;cClass:TClassId):Pointer;
 var P:Pointer;
begin
 case cClass of
  nPlayer : P:=New(PPlayer,Init(cName,cPlayName));
  nAtmo   : P:=New(PAtmo,Init(cName,cPlayName));
  nThing  : P:=New(PThing,Init(cName,cPlayName));
  nLoc    : P:=New(PLocation,Init(cName,cPlayName));
  nAct    : P:=New(PAct,Init(cName,cPlayName));
  nHuman  : P:=New(PHuman,Init(cName,cPlayName));
 end;
 PFlashObject(P)^.Kind:=cClass;
 PFlashObject(P)^.ResKey:=cResKey;
 NewClass:=P;
end;


Procedure DoneAll;
begin
 Dispose(Player,Done);
 Dispose(Atmo,Done);
 Dispose(ThingList,Done);
 Dispose(LocList,Done);
 Dispose(ActList,Done);
 Dispose(HumanList,Done);
 Dispose(RunPart,Done);
end;

Const
      cLazyMessX  = 0;
      cLazyMessY  = 10;
      cLazyMessW  = 250;
      cLazyMessH  = 9;
      cLazyMessCol= 145;

Procedure LazyMessage(S:String);
 var p:pcolorpen;
begin
 If Not DoItemBar then Exit;
 New(P,init(0));
  Screen^.Map( cLazyMessX,cLazyMessY,
               cLazyMessX+cLazyMessW-1,cLazyMessY+cLazyMessH-1,P);
 P^.SetColor(cLazyMessCol);
  LightFont^.Writeln(cLazyMessX,cLazyMessY,Screen,S);
 Dispose(P,DOne);
end;

Procedure InitFile;
 Var S:String;
     Kind:String;
     ClassId:TClassId;
     P:Pointer;
     i:integer;

     Str:PStringArr;
begin
 (* reading player *)
 LazyMessage(cLoadingPlayer);
 S:=Value(F,ClassIdName[nPlayer]);
 Player:=NewClass(Argument(S,0),Argument(S,1),Argument(S,2),nPlayer);
 Player^.Compile(F);
 (* reading atmo *)
 LazyMessage(cLoadingAtmo);
 S:=Value(F,ClassIdName[nAtmo]);
 Atmo:=NewClass(Argument(S,0),Argument(S,1),Argument(S,2),nAtmo);
 Atmo^.Compile(F);
 (* init lists *)
 New(ThingList,Init(1,3));
 New(LocList,Init(1,3));
 New(ActList,Init(1,3));
 New(HumanList,Init(1,3));
 New(RunPart,Init);
 (* reading things,locations,acts and humans *)
 (* they can be mixed *)
 DirectVideo:=false;
 S:=''; i:=0;
 S:=ReadStr(F);
 While not Eof(F) do
 begin
  inc(i);

  if DoLogOut then if S<>'' then loggy('dreams',S);
  if DoProcessBar then if belongs(TextPos(F) mod 1000,0,100) then Pr^.NextVal(TextPos(F));

  Kind:=Argument(S,0);
  If Same(Kind,ClassIdName[nThing])
  then begin
   LazyMessage(cLoadingThing+Argument(S,1));
   P:=NewClass(Argument(S,1),Argument(S,2),Argument(S,3),nThing);
   PThing(P)^.Compile(F);
   ThingList^.Put(P);
  end;

  If Same(Kind,ClassIdName[nLoc])
  then begin
   LazyMessage(cLoadingLoc+Argument(S,1));
   P:=NewClass(Argument(S,1),Argument(S,2),Argument(S,3),nLoc);
   PLocation(P)^.Compile(F);
   LocList^.Put(P);
  end;

  If Same(Kind,ClassIdName[nAct])
  then begin
   LazyMessage(cLoadingAct+Argument(S,1));
   P:=NewClass(Argument(S,1),Argument(S,2),Argument(S,3),nAct);
   PAct(P)^.Compile(F);
   ActList^.Put(P);
  end;

  If Same(Kind,ClassIdName[nHuman])
  then begin
   LazyMessage(cLoadingHuman+Argument(S,1));
   P:=NewClass(Argument(S,1),Argument(S,2),Argument(S,3),nHuman);
   PHuman(P)^.Compile(F);
   HumanList^.Put(P);
  end;

  If Same(Kind,'Main') then begin
     LazyMessage(cLoadingMain+Argument(S,1));
     Str:=New(PStringArr,Init);
     Str^.ReadTo(F,'Endmain');
     CompileCode(RunPart,Str,'Main');
     Dispose(Str,Done);
  end;

  S:=ReadStr(F);
 end;
 LazyMessage('');
 (* initing of Currentloc and LastLoc *)
 CurrentLoc:=Plocation(LocList^.Find(Player^.Place));
 LastLoc:=CurrentLoc;
 If CurrentLoc=nil then ErrorMSG('Player place undefined');
end;

 Procedure ConfigureSwitches(Var Switches:TSwitches;Var F:Text);
 begin
  Reset(F);
  With Switches do begin
   IdRecord:=Value(F,'IdRecord');
   CopyRight:=Value(F,'Copyright');
   Year:=Value(F,'Year');
   Version:=Value(F,'Version');
   MinorVersion:=Value(F,'MinorVersion');
  end;
 end;

end.