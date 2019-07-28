Unit FontEdit;

interface

procedure FontEditor;

implementation

 Uses objects,tpdos,tpcrt,strings,data,tpstr,flgraph,
      misc,fx_types,fx_mouse,
      fx_pens,types,fx_init,
      fx_fonts,fx_form,fx_dev,fx_menu;

Const cNew_id      =  01;
      cLoad_id     =  02;
      cSave_id     =  03;
      cExit_id     =  04;

      cColorCh_id  =  11;
      cGlass_id    =  12;
      cBright_id   =  13;

      cPrev_id     =  21;
      cNext_id     =  22;
      cSelect_id   =  23;

 function InitMenu:PMenuList;
  var Main:PMenuHor;
      FileMenu,
      ColorMenu,
      CharMenu:PMenuVer;
 begin
  New(Main,Init(3));
   New(FileMenu,Init(4));
   FileMenu^.PutItem('New',New(PMenuId,Init(cNew_id)));
   FileMenu^.PutItem('Load',New(PMenuId,Init(cLoad_id)));
   FileMenu^.PutItem('Save',New(PMenuId,Init(cSave_id)));
   FileMenu^.PutItem('Exit',New(PMenuId,Init(cExit_id)));
   Main^.PutItem('File',FileMenu);
   New(ColorMenu,Init(3));
   ColorMenu^.PutItem('Color...',New(PMenuId,Init(cColorCh_id)));
   ColorMenu^.PutItem('Glass',New(PMenuId,Init(cGlass_id)));
   ColorMenu^.PutItem('Bright',New(PMenuId,Init(cBright_id)));
   Main^.PutItem('Pen',ColorMenu);
   New(CharMenu,init(3));
   CharMenu^.PutItem('Previous',New(PMenuId,Init(cPrev_id)));
   CharMenu^.PutItem('Next',New(PMenuId,Init(cNext_id)));
   CharMenu^.PutItem('Select',New(PMenuId,Init(cSelect_id)));
   Main^.PutItem('Char',CharMenu);
   InitMenu:=Main;
 end;

 var Key:Word;

 function ReadKeyWord:Word;
  var key:word;
 begin
  key:=0;
  key:=Ord(ReadKey);
  if key=0 then key:=ord(Readkey)*256;
  ReadKeyWord:=key;
 end;

function CheckKey(AKey:word):boolean;
begin
 CheckKey:=Key=AKey;
end;

 const
       cZOOMPOSX   = 10;
       cZOOMPOSY   = 10;

       cGLASSCODE1   =$0067;
       cGLASSCODE2   =$2200;
       cBRIGHTCODE1  =$0062;
       cBRIGHTCODE2  =$3000;
       cCOLORCODE1   =$0063;
       cCOLORCODE2   =$2E00;
       cHELPCODE     =$3B00;
       cSTATCODE     =$3C00;
       cZOOMCODE     =Ord('z');
 var LeftCol, RightCol:byte;

 procedure EditChar(Char:PChar; Var ZoomLev:byte);
  var Dev:PDevice;
      Zoom:PZoomEdit;
      Left,Right:PPen;
      x,y:integer;
      butt:Byte;
      c:byte;

   procedure HelpScreen;
   begin
    Writeline('Press "C" to color select');
    Writeline('Press "G" to glass');
    Writeline('Press "B" to bright');
    Writeline('Press "Z" to change zoom');
    Writeline('- all for left pen, for right - same key + ALT');
    SHow_text;
   end;

 begin
  Dev:=Char2Dev(Char);
  New(Zoom,Init(ZoomLev,Dev,False));
  Hide_mouse; Zoom^.Show(cZOOMPOSX,cZOOMPOSY); Show_mouse;
  Left:=New(PColorPen,init(LeftCol)); Right:=New(PColorPen,init(RightCol));
  While true do begin
   x:=MousePosX; y:=MousePosY;
   if MouseButtons<>0 then begin
    butt:=MouseButtons; ClearInput;
    if Zoom^.InZoom(x,y) then case Butt of
     cLeftButton : if Assigned(Left)
                   then begin
                    Hide_mouse;
                    Zoom^.ZoomClick(x,y,Left);
                    Show_mouse;
                   end else Message('No pen assigned to left button');
     cRightButton : if Assigned(Right)
                   then begin
                    Hide_mouse;
                    Zoom^.ZoomClick(x,y,Right);
                    Show_mouse;
                   end else Message('No pen assigned to right button');
    end;
   end;
   if Keypressed then Key:=ReadKeyWord else Key:=0;
   if CheckKey(cHELPCODE) then HelpScreen;
   if CheckKey(cCOLORCODE1) then begin
                             if Left<>nil then Dispose(Left,Done);
                             c:=PickColor(x,y); LeftCol:=c;
                             Left:=New(PCOlorPen,Init(c));
                            end;
   if CheckKey(cCOLORCODE2) then begin
                             if Right<>nil then Dispose(Right,Done);
                             c:=PickColor(x,y); RightCol:=c;
                             Right:=New(PCOlorPen,Init(c));
                            end;
   if CheckKey(cGLASSCODE1) then begin
                             if Left<>nil then Dispose(Left,Done);
                             Left:=New(PConvertPen,Init(Palette^.GlassIndex));
                            end;
   if CheckKey(cGLASSCODE2) then begin
                             if Right<>nil then Dispose(Right,Done);
                             Right:=New(PConvertPen,Init(Palette^.GlassIndex));
                            end;
   if CheckKey(cBrightCODE1) then begin
                             if Left<>nil then Dispose(Left,Done);
                             Left:=New(PConvertPen,Init(Palette^.BrightIndex));
                            end;
   if CheckKey(cBrightCODE2) then begin
                             if Right<>nil then Dispose(Right,Done);
                             Right:=New(PConvertPen,Init(Palette^.BrightIndex));
                            end;
   if CheckKey($001b) then Break;
   if CheckKey(cZOOMCODE) then begin
                           ZoomLev:=TOByte(Receive('ZOOM?(4-20)'));
                           if not belongs(ZoomLev,4,20) then ZoomLev:=4;
                           Hide_mouse; Dispose(Zoom,Done); Show_mouse;
                           New(Zoom,Init(ZoomLev,Dev,False));
                           Hide_mouse; Zoom^.Show(cZOOMPOSX,cZOOMPOSY); Show_mouse;
                          end;
  if checkkey(ord('f')) then begin
                         Dev^.Clear(Left);
                          Hide_mouse; Zoom^.Hide; Show_mouse;
                          Hide_mouse; Zoom^.Show(cZOOMPOSX,cZOOMPOSY); Show_mouse;
                        end;

  end;
  if Left<>nil then Dispose(Left,Done);
  if Right<>nil then Dispose(Right,Done);
  Hide_mouse; Dispose(Zoom,Done); Show_mouse;
  PutDev2Char(Dev,Char);
  Dispose(Dev,Done);
 end;

procedure FontEditor;
 var Zoom:Byte;
     Font:PFont;
     Data:PDosStream;
     FileName:String;
     Symbol:Byte;
     Wid,Hgt:Byte;
     Win:PTextWindow;
     Char:PChar;
     a,b:integer;

   procedure StatusScreen;
   begin
    Writeline('Current fonteditor status');
    Writeline('Left pen color: '+tostr(LeftCol));
    Writeline('Right pen color: '+tostr(RightCol));
    Writeline('Font filename: '+filename);
    Writeline('Current Symbol #'+TOStr(Symbol)+' Char:'+System.Chr(Symbol));
    Writeline('Font height: '+ToStr(Hgt));
    Show_text;
   end;

begin
 Zoom:=10; Font:=Nil; Symbol:=0; LeftCol:=80; RightCol:=0;
 While true do begin
  if Keypressed then Key:=ReadKeyWord else Key:=0;
  case Key of
   cHelpcode : begin
                Writeline('n,l,s - new,save,load font');
                Writeline('c - set symbol as char');
                writeline('d - set symbol as code');
                Writeline('h - change default height of symbols');
                writeline('v - preview');
                writeline('q - quit');
                writeline('e - edit current symbol');
                writeline('r - shrink or expand width of current symbol');
                writeline('",","." - scrolls through symbols');
                show_text;
               end;
   cSTATCODE : StatusScreen;
   ord('l') : begin
               Filename:=Receive('Load?');
               if Filename='' then continue else begin
                If Pos('.',Filename)=0 then Filename:=Filename+'.fnt';
                if ExistFile(Filename) then begin
                 New(Data,init(FIlename,stOPENREAD));
                 New(Font,Load(Data^));
                 Dispose(Data,Done);
                 Symbol:=65;
                 Hgt:=Font^.lnHeight;
                end else Message('Can`t find such file');
               end;
              end;
   ord('s') : begin
              if Font=Nil then begin
               Message('No font currently edited');
               Continue;
              end;
              Filename:=Receive('Save?');
              if Filename='' then continue else begin
                If Pos('.',Filename)=0 then Filename:=Filename+'.fnt';
                New(Data,init(Filename,stCreate));
                Font^.Store(Data^);
                Dispose(Data,Done);
              end;
             end;
    ord('n') : begin
                if Font<>Nil then Dispose(FOnt,Done);
                Hgt:=ToByte(Receive('Font height?'));
                New(Font,Init(1,1));
               end;
    ord('c') : begin
                Filename:=Receive('Char?');
                Symbol:=Ord(Filename[1]);
                Filename:='';
               end;
    ord('d') : begin
                Symbol:=TOByte(Receive('Code?'));
               end;
    ord('h') : Hgt:=ToByte(Receive('Font height?'));
    ord('e') : begin
                if Font=nil
                then Message('No font available')
                else begin
                 if Font^.Get(Symbol) = nil
                 then begin
                  Wid:=TOByte(Receive('Char width?'));
                  if Wid=0 then Continue;
                  Font^.Put(Symbol,New(PChar,Init(Wid,Hgt)));
                  EditChar(Font^.Get(Symbol),Zoom);
                 end else EditChar(Font^.Get(Symbol),Zoom);
                end;
               end;
    ord('q') : Break;
    ord('r') : begin
                if Font=nil then begin
                 Message('No font loaded');
                 continue;
                end;
                Wid:=ToByte(Receive('New width?'));
                if Font^.List[Symbol]=nil then New(Font^.List[Symbol],Init(Wid,Hgt));
                if Wid<>0 then begin
                 New(Char,Init(Wid,Hgt));
                 if Wid>Font^.Get(Symbol)^.chWidth
                 then Wid:=Font^.Get(Symbol)^.chWidth;
                 for b:=0 to Hgt-1 do
                   for a:=0 to Wid-1 do Char^.SetPin(a,b,Font^.Get(Symbol)^.GetPin(a,b));
                 Dispose(Font^.List[Symbol],Done);
                 Font^.List[Symbol]:=Char;
                end;
               end;
    ord('v') : begin
                if Font=nil then begin
                 Message('No font loaded');
                 continue;
                end;
                Filename:=Receive('Enter chars');
                New(Win,Init( 1,Font^.lnWidth(Filename)+5,
                              make_form(pix1_fr, std_ground, Font),
                              Screen ));
                Win^.put(Filename);
                Win^.Center;
                anyclick;
                Dispose(Win,done);
               end;
     ord('.') : if Symbol=255 then Symbol:=0 else inc(Symbol);
     ord(',') : if Symbol=0 then Symbol:=255 else Dec(Symbol);

  end;
 end;
 if Font<>nil then Dispose(Font,Done);
end;

end.

