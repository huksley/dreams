{$R-,Q-,S-}
Unit Fx_Fonts;

Interface

Uses objects,
     fx_dev;
Type
     PChar=^TChar;
     TChar=object(TObject)
      chWidth,chHeight:byte;
      data:pointer;
      procedure Show(x,y:word;D:PDEVICE);
      constructor Init(W,H:Byte);
      constructor Load(var S:TStream);

      procedure SetPin(x,y:word;c:byte);
      function GetPin(x,y:word):byte;

      procedure Store(Var S:TStream);
      destructor Done;virtual;

      procedure ReplaceColor(col,tocol:byte);
     end;


Type
     PFont=^TFont;
     TFont=object(TObject)
      List:Array[0..255] of PChar;
      WidthSpace,HeightSpace:byte;

      procedure Put(Num:Byte;Ch:PChar);
      function Get(Num:Byte):PChar;

      function show_ch(x,y:word;num:byte;D:PDevice):byte;
      procedure writeln(x,y:word;D:PDevice;s:string);

      procedure WriteLen(x,y,l:word; D:PDevice; s:string);
      procedure WriteCen(x,y,w:word; D:PDevice; s:String);

      function lnWidth(s:string):word;
      function lnHeight:word;
      function cutTOLen(l:word; s:string):string;

      constructor Load(Var S:TStream);
      constructor Init(Wspace,HSpace:byte);
      procedure Store(Var S:TStream);
      destructor Done;virtual;
     end;

 function Char2Dev(Char:PChar):PDevice;
 procedure PutDev2Char(Dev:PDevice;Char:PChar);

Implementation

uses fx_pens;

 function Char2Dev(Char:PChar):PDevice;
  var p:pdevice;
      cp:PColorPen;
 begin
  new(cp,init(0));
  New(P,Init(Char^.chWidth,Char^.chHeight));
  P^.Clear(cp);
  Dispose(Cp,Done);
  Char^.Show(0,0,P);
  Char2Dev:=P;
 end;
 procedure PutDev2Char(Dev:PDevice;Char:PChar);
 begin
  Move(Dev^.Start^,Char^.Data^,Char^.chWidth*Char^.chHeight);
 end;

     function TFont.cutTOlen;
      var a,b:word;
     begin
      if s='' then
      begin
       cutTOLen:='';
       exit;
      end;
      b:=0;
      for a:=1 to Length(s) do
      begin
       if Get(ord(s[a]))<>nil then b:=b+Get(ord(s[a]))^.chWidth+WidthSpace;
       if b+Get(ord(s[a]))^.chWidth+WidthSpace>l then break;
      end;
      cutTOlen:=copy(s,1,a);
     end;
     destructor TFont.Done;
      var a:byte;
     begin
      for a:=0 to 255 do
      if Assigned(List[a]) then Dispose(List[a],Done);
      TObject.Done;
     end;
     procedure TChar.ReplaceColor(col,tocol:byte);
      var a,b:byte;
     begin
      for b:=0 to chHeight-1 do
      for a:=0 to chWidth-1 do If GetPin(a,b)=col then setPin(a,b,tocol);
     end;
     procedure TChar.SetPin;
     begin
      TByteArray(data^)[y*chWidth+x]:=c;
     end;
     function TChar.GetPin;
     begin
      GetPin:=TByteArray(data^)[y*chWidth+x];
     end;
     constructor TChar.Load;
     begin
      S.Read(chWidth,1);
      S.Read(chHeight,1);
      Init(chWidth,chHeight);
      S.Read(data^,chWidth*chHeight);
     end;
     procedure TChar.Store;
     begin
      S.Write(chWidth,1);
      S.Write(chHeight,1);
      S.Write(data^,chWidth*chHeight);
     end;
{     constructor TChar.GetGrab;
      var a,b:word;
     begin
      chWidth:=x1-x;
      chHeight:=y1-y;
      for b:=y to y1 do
          for a:=x to x1 do
                  TByteArray(data^)[b*chWidth+a]:=GetPixel(a,b);
     end;}
     constructor TChar.Init;
     begin
      TObject.Init;
      chWidth:=W;
      chHeight:=H;
      GetMem(data,w*h);
      FillChar(Data^,w*h,0);
     end;
     destructor TChar.Done;
     begin
      FreeMem(data,chWidth*chHeight);
      TObject.Done;
     end;
     procedure TChar.Show;
     begin
      D^.PutSprite(x,y,chWidth,chHeight,0,data^);
     end;

     constructor TFont.Init;
      var a:byte;
     begin
      TObject.Init;
      for a:=0 to 255 do List[a]:=nil;
      WidthSpace:=WSpace;
      HeightSpace:=HSpace;
     end;
     constructor TFont.Load;
      var a,w,h:byte;
     begin
      S.Read(W,1);
      S.Read(H,1);
      Init(W,H);
      While S.GetSize<>S.GetPos do
      begin
       S.Read(a,1);
       New(List[a],Load(S));
      end;
     end;
     procedure TFont.Store;
      var a:byte;
     begin
      S.Write(WidthSpace,1);
      S.Write(HeightSpace,1);
      for a:=0 to 255 do
       if Get(a)<>nil then
       begin
        S.Write(a,1);
        Get(a)^.Store(S);
       end;
     end;
     function TFont.lnWidth;
      var a,b:word;
     begin
      if s='' then begin
       lnWidth:=0;
       Exit;
      end;
      b:=0;
      for a:=1 to Length(s) do
       if Get(ord(s[a]))<>nil
       then b:=b+Get(ord(s[a]))^.chWidth+WidthSpace
       else b:=b+widthSpace;
      {if length(s)>1 then }lnWidth:=b{-Widthspace{ else lnWidth:=b;}
     end;
     function TFont.lnHeight;
     begin
      lnHeight:=Get(ord('A'))^.chHeight;
     end;
     procedure TFont.Put;
     begin
      List[Num]:=Ch;
     end;
     function TFont.Get;
     begin
      Get:=List[num];
     end;
     function TFont.show_ch;
     begin
      if Get(Num)<>Nil
      then begin
       Get(Num)^.Show(x,y,D);
       show_ch:=Get(Num)^.chWidth+WidthSpace;
      end
      else show_ch:=0;
     end;
     procedure TFont.writeln;
      var a,b:integer;
     begin
      b:=x;
      for a:=1 to length(s) do
       if Get(ord(s[a]))<>nil
       then b:=b+show_ch(b,y,ord(s[a]),d);
     end;
     procedure TFont.writelen;
     begin
      writeln(x,y,d,cutTOLen(l,s));
     end;
     procedure TFont.writeCen;
     begin
      if lnWidth(S)>W
      then Writeln(x,y,d,cutTOLen(w,s))
      else Writeln(x+(w-LnWidth(s)) div 2,y,D,S);
     end;

end.
