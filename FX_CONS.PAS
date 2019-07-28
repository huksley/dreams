Unit fx_cons;

interface

 Uses TPStr;

 function  Consoled: boolean;
 procedure Console_out(text:string);
 procedure Console_outtext(TextArr:PStringArr);
 procedure Show_console;

implementation

 uses flaction,tpcomms,parsing,fx_console,fx_init,fx_mouse;

 const Exit     = 'stop';
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

procedure Console_Outtext;
 var i:integer;
begin
 if Consoled then
 for i:=0 to TextArr^.Count-1 do Console_out(TextArr^.Get(i));
end;

procedure Show_console;
 var s:string;
     cmd:integer;
begin
 if Console<>nil then Console^.output('Consol already displayed')
 else begin
 Hide_mouse;
 New(Console,Init(ConsoleW,ConsoleH,LightFont,Screen));
 Console^.Show(ConsoleX,ConsoleY);
 Show_mouse;
 Console^.output('FLASH Language console.');
 Console^.output('Press "stop" to exit');
  repeat
   s:=console^.input;
   if (s='') or (s=' ') then continue;
   if same(s,exit) then break;
   cmd:=findcomm(Argument(S,0));
   s:=Tail(S,1);
   if cmd<>-1
   then MakeCommand(Cmd,S)
   else Console^.Output('Unknown command');
  until same(s,exit);
 Hide_mouse;
 Dispose(Console,Done);
 Console:=Nil;
 Show_mouse;
 end;
end;

begin
end.
