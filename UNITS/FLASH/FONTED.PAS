Unit FontEd;

interface

 procedure FontEdit;

implementation

 Uses data,tpstr,flgraph,misc,fx_types,fx_mouse,fx_pens,types,fx_init,fx_fonts,fx_form,fx_dev;


 const
       cFontEdX = 10;
       cFontEdY = 10;
       cFontEdW = 240;
       cFontEdH = 150;
       cCurrNum = 65;
       cFontEdMsg = 'Built-in FontEditor (C) 1996 Wizecore';
       cStatEdMsg = 'Press ALT-X to exit';

       { color choosing buttons }
       cColorSect = 'Color selection';
       cPalSelMsg = 'Color';
       cGlassMsg  = 'Darken';
       cBrightMsg = 'Brighten';
       { symbol choosing buttons }
       cCharSect  = 'Char selection';
       cNextMsg   = 'Next(+)';
       cPrevMsg   = 'Prev(-)';
       cSelMsg    = 'Select(Num)';
       { file option buttons }
       cFileSect  = 'File Selection';
       cLoadMsg   = 'Load';
       cSaveMsg   = 'Save';
       cNewMsg    = 'New';
       { miscelangelous button }
       cMiscMsg   = 'Misc...';

       cColWinL  = 11;

 Var  CurrentFont:PFont;
      CurrentChar:Char;
      filename:nstring;

 procedure FontEdit;
  var Zoom:PZoomEdit;
      ax,ay,fw,fh,bh,aw,ah,sx,sy,x,y:integer;
      ColX,ColY:Integer;
      NumX,NumY:Integer;
      LeftColor,RightColor:PPen;
      CurrentDev:PDevice;
      CurrentSym:Byte;
      Button:Byte;
      Form:PForm;
      Ch:PChar;

      { color choosing buttons }
      PalChoose,
      GlassChoose,
      BrightChoose,
      { symbol choosing buttons }
      NextChar,
      PrevChar,
      SelChar,
      { file option buttons }
      SaveFnt,
      LoadFnt,
      NewFnt,
      { miscelangelous button }
      MiscMenu:PButton;

  function StdButton(Name:String):PButton;
  begin
   StdButton:=New(PButton,Init(Name,LightFont^.LnWidth(Name)+1));
  end;

  function PickCol:PPen;
  begin
   PickCol:=New(PColorPen,Init(PickColor(x,y)));
  end;

  procedure ClearNum;
   var p:PColorPen;
  begin
   New(P,init(Colors.Paper));
   Screen^.Map(NumX,NumY,NumX+LightFont^.lnWidth(ToStr(CurrentSym)+':'+Chr(CurrentSym))-1,NumY+LightFont^.lnHeight-1,P);
   Dispose(P,Done);
  end;

 begin
  CurrentFont:=nil;
  CurrentSym:=0;
  filename:='';
  form:=make_form(Pix1_fr,Std_Ground,LightFont);
  form^.Show(Screen,cFONTEDX,cFONTEDY,cFONTEDX+cFONTEDW-1,cFONTEDY+cFONTEDH-1);
  sx:=cFONTEDX+form^.offsetx+1;
  sy:=cFONTEDY+form^.offsety+1;
  aw:=cFONTEDW-(form^.offsetx+1)*2;
  ah:=cFONTEDH-(form^.offsety+1)*2;
  LightFont^.WriteCen(sx,sy,aw,Screen,cFontEdMsg);
  LightFont^.WriteCen(sx,sy+ah-LightFont^.lnHeight-2,aw,Screen,cStatEdMsg);
  sy:=sy+LightFont^.lnHeight+2;
  ah:=ah-(LightFont^.lnHeight+2)*2;
  PalChoose       :=StdButton(cPalSelMsg);
  GlassChoose     :=StdButton(cGlassMsg);
  BrightChoose    :=StdButton(cBrightMsg);
  NextChar        :=StdButton(cNextMsg);
  PrevChar        :=StdButton(cPrevMsg);
  SelChar         :=StdButton(cSelMsg);
  NewFnt          :=StdButton(cNewMsg);
  LoadFnt         :=StdButton(cLoadMsg);
  SaveFnt         :=StdButton(cSaveMsg);
  MiscMenu        :=StdButton(cMiscMsg);

  bh:=PalChoose^.Height+1;

  ax:=sx; ay:=sy;
  LightFont^.Writeln(ax,ay+3,Screen,cColorSect);
  inc(ax,LightFont^.lnWidth(cColorSect));
  PalChoose^.Show(ax,aY); Inc(ax,PalChoose^.Width+1);
  GlassChoose^.Show(ax,ay); Inc(ax,GlassChoose^.Width+1);
  BrightChoose^.Show(ax,aY); Inc(Ax,BrightChoose^.Width+1);
  ColX:=ax; ColY:=ay;

  ax:=sx; ay:=sy+bh;
  LightFont^.Writeln(ax,ay+3,Screen,cCharSect);
  inc(ax,LightFont^.lnWidth(cCharSect));
  PrevChar^.Show(ax,ay); Inc(ax,PrevChar^.Width+1);
  SelChar^.Show(ax,ay); Inc(ax,SelChar^.Width+1);
  NextChar^.Show(ax,ay); Inc(ax,NextChar^.Width+1);
  NumX:=ax+2; NumY:=ay+3;

  ax:=sx; ay:=sy+bh*2;
  LightFont^.Writeln(ax,ay+3,Screen,cFileSect);
  inc(ax,LightFont^.lnWidth(cFileSect));
  NewFnt^.Show(ax,ay); Inc(ax,NewFnt^.Width+1);
  LoadFnt^.Show(ax,ay); Inc(ax,LoadFnt^.Width+1);
  SaveFnt^.Show(ax,ay); Inc(ax,SaveFnt^.Width+1);
  MiscMenu^.Show(ax,ay);
  sy:=sy+bh*3;
  CurrentDev:=nil;
  RightColor:=nil;
  LeftColor:=New(PColorPen,Init(0));
  Screen^.Map(ColX,ColY,ColX+cCOLWINL-1,COLY+cCOLWINL-1,LeftColor);
  Screen^.Map(ColX+cCOLWINL,ColY,ColX+cCOLWINL*2-1,COLY+cCOLWINL-1,LeftColor);
  LightFont^.Writeln(ColX+2,Coly+3,Screen,'X');
  LightFont^.Writeln(ColX+2+cCOLWINL,ColY+3,Screen,'X');
  Dispose(LeftColor,Done); LeftColor:=Nil;
  LightFont^.Writeln(NumX,NumY,Screen,TOStr(CurrentSym)+':'+Chr(CurrentSym));
  While Not ALTX_PRESSED do begin
   x:=MousePosX; y:=MousePosY;
   if MouseButtons<>0 then begin
    Button:=MouseButtons;
    if NextChar^.Here(x,y) then begin
      Hide_mouse;
      NextChar^.Repaint_act;
      Show_mouse;
      ClearNum;
      if Button=cLeftButton
      then Inc(CurrentSym)
      else Inc(CurrentSym,10);
      LightFont^.Writeln(NumX,NumY,Screen,TOStr(CurrentSym)+':'+Chr(CurrentSym));
    end;
    if PrevChar^.Here(x,y) then begin
      Hide_mouse;
      PrevChar^.Repaint_act;
      Show_mouse;
      ClearNum;
      if Button=cLeftButton
      then Dec(CurrentSym)
      else Dec(CurrentSym,10);
      LightFont^.Writeln(NumX,NumY,Screen,TOStr(CurrentSym)+':'+Chr(CurrentSym));
    end;
    if (CurrentDev<>Nil) and Zoom^.Here(x,y) and Zoom^.InZoom(x,y)
    then case Button of
     cLeftButton  :  if LeftColor<>Nil
                     then Zoom^.ZoomClick(x,y,LeftColor)
                     else Message('Pen have no color');
     cRightButton :  if RightColor<>Nil
                     then Zoom^.ZoomClick(x,y,RightColor)
                     else Message('Pen have no color');
    end;
    if PalChoose^.Here(x,y)
    then begin
     Hide_mouse;
     PalChoose^.Repaint_act;
     Show_mouse;
     case Button of
      cLeftButton : begin
                     if LeftColor<>Nil then Dispose(LeftColor,Done);
                     LeftColor:=PickCol;
                     Screen^.Map(ColX,ColY,ColX+cCOLWINL-1,COLY+cCOLWINL-1,LeftColor);
                    end;
      cRightButton: begin
                     if RightColor<>Nil then Dispose(RightColor,Done);
                     RightColor:=PickCol;
                     Screen^.Map(ColX+cCOLWINL,ColY,ColX+cCOLWINL*2-1,COLY+cCOLWINL-1,RightColor);
                    end;
     end;
    end;
    if GlassChoose^.Here(x,y)
    then begin
     Hide_mouse; GlassChoose^.Repaint_act; Show_mouse;
     case Button of
      cLeftButton : begin
                     if LeftColor<>Nil then Dispose(LeftColor,Done);

                     LeftColor:=New(PColorPen,Init(0));
                     Screen^.Map(ColX,ColY,ColX+cCOLWINL-1,COLY+cCOLWINL-1,LeftColor);
                     LightFont^.Writeln(ColX+2,Coly+3,Screen,'G');
                     Dispose(LeftColor,Done);

                     LeftColor:=New(PConvertPen,Init(Palette^.GlassIndex));
                    end;
      cRightButton: begin
                     if RightColor<>Nil then Dispose(RightColor,Done);

                     LeftColor:=New(PColorPen,Init(0));
                     Screen^.Map(ColX+cCOLWINL,ColY,ColX+cCOLWINL*2-1,COLY+cCOLWINL-1,LeftColor);
                     LightFont^.Writeln(ColX+2+cCOLWINL,ColY+3,Screen,'G');
                     Dispose(LeftColor,Done);

                     RightColor:=New(PConvertPen,Init(Palette^.GlassIndex));
                    end;
     end;
    end;
    if BrightChoose^.Here(x,y)
    then begin
     Hide_mouse; BrightChoose^.Repaint_act; Show_mouse;
     case Button of
      cLeftButton : begin
                     if LeftColor<>Nil then Dispose(LeftColor,Done);

                     LeftColor:=New(PColorPen,Init(0));
                     Screen^.Map(ColX,ColY,ColX+cCOLWINL-1,COLY+cCOLWINL-1,LeftColor);
                     LightFont^.Writeln(ColX+2,Coly+3,Screen,'B');
                     Dispose(LeftColor,Done);

                     LeftColor:=New(PConvertPen,Init(Palette^.BrightIndex));
                    end;
      cRightButton: begin
                     if RightColor<>Nil then Dispose(RightColor,Done);

                     LeftColor:=New(PColorPen,Init(0));
                     Screen^.Map(ColX+cCOLWINL,ColY,ColX+cCOLWINL*2-1,COLY+cCOLWINL-1,LeftColor);
                     LightFont^.Writeln(ColX+2+cCOLWINL,ColY+3,Screen,'B');
                     Dispose(LeftColor,Done);

                     RightColor:=New(PConvertPen,Init(Palette^.BrightIndex));
                    end;
     end;
    end;
   end;
   While MouseButtons<>0 do;
  end;
  Hide_Mouse;
  Dispose(PalChoose,Done);
  Dispose(GlassChoose,Done);
  Dispose(BrightChoose,Done);
  Dispose(NextChar,Done);
  Dispose(PrevChar,Done);
  Dispose(SelChar,Done);
  Dispose(NewFnt,Done);
  Dispose(LoadFnt,Done);
  Dispose(SaveFnt,Done);
  Dispose(MiscMenu,Done);
  form^.unshow;
  Dispose(Form,Done);
  if CurrentFont<>nil then Dispose(CurrentFont,Done);
  if LeftColor<>nil then Dispose(LeftColor,Done);
  if RightColor<>nil then Dispose(RightColor,Done);
  Show_Mouse;
 end;

end.