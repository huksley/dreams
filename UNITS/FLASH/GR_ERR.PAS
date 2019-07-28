Unit gr_err;

interface

procedure set_gr_io;

implementation

uses tpstr,flgraph,fx_init,core;

procedure gr_message(message:string);
begin
 Palette^.Apply;
 FLGraph.Message(Message);
end;

 const
       cYESignore = 'Да, игноpиpовать';
       cNoIgnore  = 'Hет, выйти';
       cPRomt_X   = 100;
       cPromt_Y   = 60;
       cDOIgnore  = 'Пpоигноpиpовать ?';

function gr_yes_no(message:string):boolean;
 var text:PStringArr;
begin
 New(Text,Init);
 Text^.Put(cYESIgnore);
 Text^.Put(cNoIgnore);
 gr_yes_no:=Show_arr(cPROMT_X,cPROMT_Y,cDOIgnore,Text)=0;
 Dispose(Text,Done);
end;

procedure set_gr_io;
begin
 SetIOMethods(gr_Message,gr_yes_no);
end;

end.