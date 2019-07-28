Unit Constants;

interface

Const  Yes=True;
       No=False;
       Off=False;

      cProgName='Dreams/DASP';
      cFileName='dreams';
      cDatFile ='.dat';
      cErrFile ='.err';
      cLogFile ='.log';
      cMapFile ='.map';
      cResFile ='.res';
Type
      ShortStr=String[15];
      TCommandProc=Procedure(S:String);
      TIfCondition=Function(S:String):Boolean;
      TCommandClass=(cPlain,cIf);

      TClassId=(nPlayer,nAtmo,nThing,nLoc,nAct,nHuman);
      TDirection=(nNorth,nEast,nSouth,nWest);

Const
      clFirst=nPlayer;
      clLast =nHuman;

      cNone             ='none';
      cDialog           ='Dialog';
      cPlaceDesc        ='PlaceDesc';
      cManTalk          ='ManTalk';
      cManDesc          ='ManDesc';
      cChoice           ='Choice';
      cEnd              ='end';
      cDialogEnd        ='diaend';
      cTime             ='time';
      cEvent            ='event';

      CommandClassName:Array[TCommandClass] of String[5]=
      ('Plain','If');
      cIfName        ='if';
      cThen          ='then';
      cElse          ='else';
      cEndIf         ='end';
      cAnd           ='and';
      cOr            ='or';
      cFlashComm     ='FlashComm';
      cFlashCommEnd  ='EndComm';
      cFlashAct      ='do';
      cFlashActEnd   ='enddo';
      Quiet:Boolean  =yes;

      ClassIdName:Array[TClassId] of String[8]=
      ('Player','Atmo','Thing','Location','Act','Human');

      ClassIdNames:Array[TClassId] of String[9]=
      ('Player','Atmo','Things','Locations','Acts','Humans');

      cId:Word       =$0000;
      cNoResource    ='no_resource';
      cNoName        ='no_name';
      cNoWhere       ='nowhere';
      cNoWay         ='no_way';
      cDisposed      ='disposed';

      cClass         ='Class';
      cClassEnd      ='End'; {ClassEnd}

      cDesc          ='text';
      cDescEnd       ='end';
      cArea          ='area';

      cThings        ='things';
      cThingsEnd     ='end';

      cParams        ='params';
      cParamsEnd     ='end';

      cAct           ='do';
      cActEnd        =cFlashActEnd;

      cSmallAct      ='SmallAct';
      cSmallActEnd   =cFlashActEnd;
      LastId:LongInt =0;

Function StrToClassId(S:String):TClassId;

implementation
Uses strconst,tpstr,core;


Function StrToClassId(S:String):TClassId;
 var t:TClassId;
begin
 for t:=low(t) to high(t) do
     if Same(s,ClassIdName[t]) then begin
                                     StrToClassId:=t;
                                     exit;
                                    end;
 ErrorMsg(StrToChar(cCantConvertID+s));
end;

end.
