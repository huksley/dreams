const cMAINSAVE  = 'flgsave';
      cMAXSAVES  = 10;
      cSAVETITLE = 'Filename';
      cSAVE_X    = 100;
      cSAVE_Y    = 60;

function savefile(i:integer):string;
begin
 SaveFile:=cMAINSAVE+'.'+tostr(i);
end;

function SavePrompt:Integer;
 var FileNames:PStringArr;
     i:integer;
begin
 New(FileNames,Init);
 for i:=0 to cMAXSAVES-1 do FileNames^.Put(savefile(i));
 i:=Show_arr(cSAVE_X,cSAVE_Y,cSAVETITLE,FileNAmes);
 SavePrompt:=i;
 Dispose(FileNames,done);
end;

