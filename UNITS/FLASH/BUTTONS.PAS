Unit Buttons;

interface

 procedure buttons_init(var f:text);
 procedure show_buttons;
 function in_buttons(x,y:integer):boolean;
 procedure buttons_click(x,y:integer);
 function buttons_text(x,y:integer):string;

implementation

Uses button,tpstr,fx_file;

 const
      cButtonStart = 'ButtonStart';
      cButtonEnd   = 'ButtonStop';

 var buttdat:buttondat;

 procedure buttons_init;
 var txt:pStringArr;
 begin
 txt:=nil;
 buttdat.size:=0;
 While not eof(f) do
 begin
  if Same(ReadStrf(f),cButtonStart)
  then begin
   new(txt,init);
   txt^.readto(F,cButtonEnd);
   Break;
  end;
 end;
 if txt<>nil then begin
  button.unpack_arr(txt,buttdat);
  dispose(Txt,Done);
 end;
end;

 procedure buttons_click;
 begin
  button.buttons_click(x,y,buttdat);
 end;

 function buttons_text;
 begin
  buttons_text:=button.buttons_desc(x,y,buttdat);
 end;

 procedure show_buttons;
 begin
  button.show_buttons(buttdat);
 end;

 function in_buttons(x,y:integer):boolean;
 begin
  in_buttons:=button.in_buttons(x,y,buttdat);
 end;


end.