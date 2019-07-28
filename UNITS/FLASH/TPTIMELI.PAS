Unit TPTimeLine;

interface

uses objects,core,misc,
     tpparam,tpstr,
     tpday,flashcom,constants,flgraph;

Type
        PTimeUnit=^TTimeUnit;
        TTimeUnit=object(TObject)
         Year,Month,Day,Hour:Word;
         Event:string[15];
         Act:PCommands;
         Constructor Init;
         Destructor Done;virtual;
         Constructor Load(Var S:TStream);
         Procedure Store(Var S:TStream);
         Procedure Read(Var F:Text);
         Procedure Show;
         procedure save(var s:TStream);
         procedure restore(var s:TStream);
        end;
        PTimeLine=^TTimeLine;
        TTimeLine=object(TCollection)
         Year,Month,Day,Hour:Word;
         { time procedures }
         Procedure SetTime(Yr,Mn,Dy,Hr:Word);
         Procedure IncTime(Yr,Mn,Dy,Hr:Word);
         Procedure IncHour(Hr:Word);
         Function  ShowTime:string;
         Procedure ReadTime(S:string);
         Function CorrectTime(yr,mn,dy,hr:word):boolean;
         { array procedures }
         Constructor Init;
         Procedure Put(P:PTimeUnit);
         Function Get(Index:Word):PTimeUnit;
         Procedure Read(Var F:Text);
         Procedure Show;
         Function SearchEvent(cName:String):PTimeUnit;
         Function CurrTimeEvent:string;
         Function Current(P:PTImeUnit):Boolean;
         Function CheckEvent(cName:String):Boolean;
         Procedure ProcessEvents;

         Constructor Load(Var S:TStream);
         Procedure Store(Var S:TStream);
         procedure save(var s:TStream);
         procedure restore(var s:TStream);
        end;
Implementation
        Procedure TTimeUnit.Store;
        begin
         S.Write(Year,SizeOF(Year));
         S.Write(Month,SizeOf(Month));
         S.Write(Day,SizeOF(Day));
         S.Write(Hour,SizeOF(Hour));
         PutString(Event,S);
         Act^.Store(S);
        end;
        procedure TTimeUnit.save(var s:TStream);
        begin
         S.Write(Year,SizeOF(Year));
         S.Write(Month,SizeOf(Month));
         S.Write(Day,SizeOF(Day));
         S.Write(Hour,SizeOF(Hour));
         PutString(Event,S);
        end;
        procedure TTimeUnit.restore(var s:TStream);
        begin
         S.Read(Year,SizeOF(Year));
         S.Read(Month,SizeOf(Month));
         S.Read(Day,SizeOF(Day));
         S.Read(Hour,SizeOF(Hour));
         Event:=GetString(S);
        end;
       Constructor TTimeUnit.Load;
        begin
         S.Read(Year,SizeOF(Year));
         S.Read(Month,SizeOf(Month));
         S.Read(Day,SizeOF(Day));
         S.Read(Hour,SizeOF(Hour));
         Event:=GetString(S);
         New(Act,init); Act^.Load(S);
        end;
        Constructor TTimeUnit.Init;
        begin
         Year:=0; Month:=0; Day:=0; Hour:=0;
         Event:='';
         New(Act,Init);
        end;
        Procedure TTimeUnit.Read;
         Var S:string;
             P:PStringArr;
        begin
         Readln(f,s); FormatStr(s);
{         S:=ReadStr(f);}
         While Not Same(s,cEnd) do
         begin
          if Same(Argument(s,0),cTime)
          then begin
                if Arguments(s)<4
                then ErrorMsg('Can`t set time');
                year:=toword(Argument(s,1));
                month:=toword(Argument(s,2));
                day:=toword(Argument(s,3));
                hour:=toword(Argument(s,4));
               end;
          if Same(Argument(s,0),cEvent) then Event:=Argument(s,1);
          if Same(Argument(s,0),cFlashAct)
          then begin
                New(P,Init);
                P^.ReadTO(F,cFlashActEnd);
                CompileCode(Act,P,'Event '+Event);
                {    Act^.LoadDATA(P);}
                Dispose(P,Done);
               end;
          Readln(f,s); FormatStr(s);
{          S:=ReadStr(f);}
        end;
        end;
        Procedure TTimeUnit.Show;
        begin
         putline_text(
{         Writeline( }tostr(Day)+'/'+
                    tostr(Month)+'/'+
                    tostr(Year)+' '+
                    tostr(Hour)+':00' );
         if Event<>'' then {Writeline}putline_text(Event);
         {Writeline}putline_text('Acts '+TOStr(Act^.Commands^.Count));
{         show_text;}
        end;
        Destructor TTimeUnit.Done;
        begin
         Dispose(Act,Done);
         TObject.Done;
        end;
        Constructor TTimeLine.Load;
         var i,Cnt:Integer;
        begin
         inherited init(1,1);
         S.Read(Year,SizeOF(Year));
         S.Read(Month,SizeOf(Month));
         S.Read(Day,SizeOF(Day));
         S.Read(Hour,SizeOF(Hour));
         S.Read(Cnt,SizeOF(Cnt));
         for i:=0 to Cnt-1 do Put(New(PTimeUnit,Load(S)));
        end;
        Procedure TTimeLine.Store;
         var i,Cnt:Integer;
        begin
         S.Write(Year,SizeOF(Year));
         S.Write(Month,SizeOf(Month));
         S.Write(Day,SizeOF(Day));
         S.Write(Hour,SizeOF(Hour));
         Cnt:=Count;
         S.Write(Cnt,SizeOF(Cnt));
         for i:=0 to Cnt-1 do Get(i)^.Store(S);
        end;
        procedure TTimeLine.save(var s:TStream);
         var i,Cnt:Integer;
        begin
         S.Write(Year,SizeOF(Year));
         S.Write(Month,SizeOf(Month));
         S.Write(Day,SizeOF(Day));
         S.Write(Hour,SizeOF(Hour));
         Cnt:=Count;
         S.Write(Cnt,SizeOF(Cnt));
         for i:=0 to Cnt-1 do Get(i)^.Save(S);
        end;
        procedure TTimeLine.restore(var s:TStream);
         var i,Cnt:Integer;
        begin
         S.Read(Year,SizeOF(Year));
         S.Read(Month,SizeOf(Month));
         S.Read(Day,SizeOF(Day));
         S.Read(Hour,SizeOF(Hour));
         S.Read(Cnt,SizeOF(Cnt));
         for i:=0 to Cnt-1 do Get(i)^.Restore(S);
        end;
        Procedure TTimeLine.ReadTime;
        begin
         if Arguments(s)<4
         then ErrorMsg('Can`t set time');
         Year :=toword(Argument(s,1));
         Month:=toword(Argument(s,2));
         Day  :=toword(Argument(s,3));
         Hour :=toword(Argument(s,4));
        end;
        Procedure TTimeLine.SetTime(Yr,Mn,Dy,Hr:Word);
        begin
         Year:=Yr; Month:=Mn; Day:=Dy; Hour:=Hr;
        end;
        Procedure TTimeLine.IncTime(Yr,Mn,Dy,Hr:Word);

         Procedure IncMn(Mn:integer);
         begin
          Month:=Month+Mn;
          if Month=13
          then begin
                Month:=1;
                Inc(Year);Day:=1;
               end;
         end;

         Procedure IncDy(Dy:integer);
         begin
          Day:=Day+Dy;
          if Day>31
          then begin
                Day:=Day-30;
                Month:=Month+1;
                If Month=13 then
                 begin
                  Month:=1;
                  Inc(Year);
                 end;
               end;
         end;
        begin
         Inc(Year,Yr);IncMn(Mn);IncDy(Dy);IncHour(Hr);
        end;
        procedure TTimeLine.IncHour(Hr:Word);
        begin
          inc(Hour,Hr);
          if Hour>24
          then begin
           Inc(Day);
           Hour:=0;
           if Day>30
           then begin
            Inc(Month);
            Day:=1;
            if Month>12 then
            begin
             Inc(Year);
             Month:=1;
            end;
           end;
          end;
        end;
        function TTimeLine.ShowTime:string;
        begin
          ShowTime:=TOStr(Day)+'.'+TOSTR(MONth)+'.'+ToStr(Year)+' , '+ToStr(Hour)+':00';
        end;
        Function TTimeLine.CorrectTime;
        begin
         CorrectTime:=((yr=0)or(yr=Year))and
                      ((mn=0)or(mn=Month))and
                      ((dy=0)or(dy=Day))and
                      ((hr=0)or(hr=Hour));
        end;
         Constructor TTimeLine.Init;
         begin
          TCollection.Init(1,3);
         end;
         Procedure TTimeLine.Put;
         begin
          Insert(P);
         end;
         Function TTimeLine.Get;
         begin
          Get:=At(Index);
         end;
         Procedure TTimeLine.Read;
          var s:string;
              p:PTImeUnit;
         begin
          Readln(f,s); FormatStr(S);
          While Not Same(s,'timeline end') do
          begin
           if Same(Argument(s,0),'GlobTime') then ReadTime(s);
           If Same(Argument(s,0),'timeevent')
           then begin
                 New(P,Init);
                 P^.Read(F);
                 Put(P);
                end;

           Readln(f,s);
           formatstr(s);
          end;
          end;
         Procedure TTimeLine.Show;
          var a:integer;
          begin
           {Writeline}putline_text('TimeLine /'+TOStr(Count));
           {Writeline}putline_text(ShowTime);
           for a:=0 to Count-1 do Get(a)^.Show;
           show_text;
          end;
         Function TTimeLine.SearchEvent;
         var a:integer;
         begin
          for a:=0 to Count-1 do
           if Same(Get(a)^.Event,cName) then
           begin
            SearchEvent:=Get(a);
            Exit;
           end;
          ErrorMSG(Str2PChar('Can`t found timeevent: '+cName));
         end;
         Function TTimeline.Current;
         begin
          Current:=((P^.Year=0)or(P^.Year=Year))and
                   ((P^.Month=0)or(P^.Month=Month))and
                   ((P^.Day=0)or(P^.Day=Day))and
                   ((P^.Hour=0)or(P^.Hour=Hour));
         end;
         Function TTimeline.CurrTimeEvent;
         var a:integer;
         begin
          for a:=0 to Count-1 do If Current(Get(a)) then
          begin
           CurrTimeEvent:=Get(a)^.Event;
           Exit;
          end;
          CurrTimeEvent:='none';
         end;
         Function TTimeLine.CheckEvent;
         begin
          CheckEvent:=Current(SearchEvent(cName));
         end;
         Procedure TTimeLine.ProcessEvents;
         var a:integer;
         begin
          for a:=0 to Count-1 do
           if Current(Get(a)) then Get(a)^.Act^.Run;
         end;
end.
