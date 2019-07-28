Unit Start;

 interface

  procedure offcountmsg;
  procedure oncountmsg;

 implementation

  uses core,time,kernel;

  var starttime,endtime:longint;
      domsg:boolean;

  procedure offcountmsg;
  begin
   domsg:=false;
  end;
  procedure oncountmsg;
  begin
   domsg:=true;
  end;

  procedure end_time;
  begin
   endtime:=clock;
   if domsg then writeln('Вpемя pаботы системы: ',endtime-starttime,'ms');
  end;

begin
 starttime:=clock;
 domsg:=true;
 add_exit_proc(@end_time);
end.