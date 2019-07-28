Unit Sounds;

 interface

  type TSoundName = string[16];
  var  sndOnInit,
       sndOnDone,
       sndOpenWin,
       sndCloseWin,
       sndScroll,
       sndClick :TSoundName;

   procedure LoadNames(var f:text);

 implementation
  uses fx_file;

   procedure LoadNames(var f:text);
   begin
    sndOnInit:=Value(f,'OnInit');
    sndOnDone:=Value(f,'OnDone');
    sndOpenWin:=Value(f,'OpenWin');
    sndCloseWin:=Value(f,'CloseWin');
    sndScroll:=Value(f,'Scroll');
    sndClick:=Value(f,'Click');
   end;

 end.