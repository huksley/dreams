Unit fx_log;

interface

 function  Consoled: boolean;
 procedure Console_out(text:string);
 procedure Show_console;

implementation

 uses flaction,tpcomms,parsing,fx_console,fx_init;

 const Exit     = 'exit';
       ConsoleX = 10;
       ConsoleY = 10;
       ConsoleW = 150;
       ConsoleH = 80;

 var   Console : PConsole;

procedure Console_out;
begin
 if Console<>Nil then Console^.Output(Text);
end;

function Consoled;
begin
 Consoled:=Console<>Nil;
end;

procedure Show_console;
 var s:string;
     cmd:integer;
begin
 New(Console,Init(ConsoleW,ConsoleH,LightFont,Screen));
 Console^.Show(ConsoleX,ConsoleY);
  repeat
   s:=console^.input;
   cmd:=findcomm(Argument(S,0));
   s:=Tail(S,1);
   if cmd<>-1
   then MakeCommand(Cmd,S)
   else Console^.Output('Unknown command');
  until same(s,exit);
 Dispose(Console,Done);
 Console:=Nil;
end;

begin
end.