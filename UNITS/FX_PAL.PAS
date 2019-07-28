Unit Fx_Pal;
{ FX-API Palette definition }
{$R-,Q-,S-}
Interface
Uses objects,fx_types,core;

Type
    TColorTable=array[0..255] of byte;
    TTable=TColorTable;
    PTable=^TTable;

    TPaletteItem=record
     r,g,b:byte;
    end;
    TPalette=array[0..255] of TPaletteItem;

    PPaletteDevice=^TPaletteDevice;
    TPaletteDevice=object(TObject)
     Private
      procedure fadefrompaltopal(oldpal,newpal:TPalette;Cnt:byte);
      procedure getvgapal;
      procedure Setvgapal(var pal);

      function PalDest(PalItem1,PalItem2:TPaletteItem):word;
      function Closest(PalItem:TPaletteItem;Pal:TPalette):word;
     Public
      Palette:TPalette;
      GlassIndex,BrightIndex:TColorTable;
      { loads glass and bright indexes from stream }
      constructor fullload(Var S:TStream);
      procedure store(Var S:TStream);
      constructor Load(Var S:TStream;APalette:TPalette);
      { creates glass and bright indextables from palette }
      constructor Adjust(APalette:TPalette);
      { makes a palette is filled by value }
      constructor Init(FillR,FillG,FillB:byte);
      { makes it active }
      constructor GreyInit;
      procedure Apply;
      { this procedure is fade from our to parameter palette }
      procedure FadeTo(Pal:TPaletteDevice;Cnt:Byte);
      { this procedure is fade from parameter to our palette }
      procedure FadeFrom(Pal:TPaletteDevice;Cnt:Byte);
    end;

procedure fadetext;

Implementation
 uses tpcrt;

    constructor TPaletteDevice.GreyInit;
      var a:integer;
          tmpPal,tmpPal1:TPalette;
    begin
     TObject.Init;
     for a:=0 to 255 do
      begin
       Palette[a].r:=a;
       Palette[a].g:=a;
       Palette[a].b:=a;
      end;
     for a:=0 to 255 do
     begin
      tmpPal[a].r:=Palette[a].r shr 1;
      tmpPal[a].g:=Palette[a].g shr 1;
      tmpPal[a].b:=Palette[a].b shr 1;

      GlassIndex[a]:=Closest(tmpPal[a],Palette);

      tmpPal1[a].r:=Palette[a].r shl 1;
      tmpPal1[a].g:=Palette[a].g shl 1;
      tmpPal1[a].b:=Palette[a].b shl 1;

      BrightIndex[a]:=Closest(tmpPal1[a],Palette);
     end;
    end;
    procedure TPaletteDevice.getvgapal;
     assembler; asm
      push ds
      xor ax,ax
      mov cx,0300h
      les di,self
      lea di,ES:[DI].TPaletteDevice.Palette
      mov dx,03c7h
      out dx,al
      inc dx
      inc dx
      cld
      rep insb
      pop ds
    end;
    constructor TPaletteDevice.Init;
     var a:byte;
    begin
     TObject.Init;
     for a:=0 to 255 do with Palette[a] do
     begin
      r:=FillR; g:=FillG; b:=FillB;
     end;
     FillChar(GlassIndex,256,0);
     FillChar(BrightIndex,256,0);
    end;
    procedure TPaletteDevice.fadefrompaltopal;
    var
      dac,c:word;
      tempal:TPalette;
    begin
      for c:=Cnt downto 0 do
      begin
        for dac:=0 to 255 do
        begin
          tempal[dac].r:=((oldpal[dac].r*c)div cnt)+((newpal[dac].r*(cnt-c))div cnt);
          tempal[dac].g:=((oldpal[dac].g*c)div cnt)+((newpal[dac].g*(cnt-c))div cnt);
          tempal[dac].b:=((oldpal[dac].b*c)div cnt)+((newpal[dac].b*(cnt-c))div cnt);
        end;
        setvgapal(tempal);
      end;
    end;
    procedure TPaletteDevice.Setvgapal(var pal); assembler;
      asm
        push ds
        xor ax,ax
        mov cx,0300h/2
        lds si,pal
        mov dx,03c8h
        out dx,al
        inc dx
        mov bx,dx
        cld
        mov dx,03dah
        @vsync0:
          in al,dx
          test al,8
        jz @vsync0
        mov dx,bx
        rep outsb
        mov bx,dx
        mov dx,03dah
        @vsync1:
          in al,dx
          test al,8
        jz @vsync1
        mov dx,bx
        mov cx,0300h/2
        rep outsb
        pop ds
      end;
    function TPaletteDevice.PalDest;
    begin
     PalDest:= Sqr(PalItem1.r-PalItem2.r)+
               Sqr(PalItem1.g-PalItem2.g)+
               Sqr(PalItem1.b-PalItem2.b);
    end;
    function TPaletteDevice.Closest;
     var a,d:word;
    begin
     d:=0;
     for a:=1 to 255 do
         if PalDest(PalItem,Pal[d])>PalDest(PalItem,Pal[a])
         then d:=a;
     Closest:=d;
    end;
    constructor TPaletteDevice.Load;
    begin
      TObject.Init;
      S.Read(GlassIndex,SizeOF(GlassIndex));
      S.Read(BrightIndex,SizeOF(BrightIndex));
      Palette:=APalette;
    end;
    constructor TPaletteDevice.Adjust;
      var a:integer;
          tmpPal,tmpPal1:TPalette;
    begin
     TObject.Init;
     Palette:=APalette;
     for a:=0 to 255 do
     begin
      tmpPal[a].r:=Palette[a].r shr 1;
      tmpPal[a].g:=Palette[a].g shr 1;
      tmpPal[a].b:=Palette[a].b shr 1;

      GlassIndex[a]:=Closest(tmpPal[a],Palette);

      tmpPal1[a].r:=Palette[a].r shl 1;
      tmpPal1[a].g:=Palette[a].g shl 1;
      tmpPal1[a].b:=Palette[a].b shl 1;

      BrightIndex[a]:=Closest(tmpPal1[a],Palette);
     end;
    end;
    Procedure TPaletteDevice.Apply;
    begin
     SetVGAPal(palette);
    end;
    Procedure TPaletteDevice.FadeTo;
    begin
     FadeFromPalToPal(Palette,Pal.Palette,Cnt);
    end;
    Procedure TPaletteDevice.FadeFrom;
    begin
     FadeFromPalToPal(Pal.Palette,Palette,Cnt);
    end;
    constructor TPaletteDevice.fullload;
     var id:tfileid;
    begin
     TObject.Init;
     S.read(id,sizeof(id));
     if id<>ColMapID then Exeption(1000,'TPaletteDevice.load file format');
     S.Read(Palette,SizeOF(Palette));
     S.Read(GlassIndex,SizeOF(GlassIndex));
     S.Read(BrightIndex,SizeOF(BrightIndex));
    end;
    procedure TPaletteDevice.store;
    begin
     S.Write(ColmapID,SizeOF(ColmapID));
     S.Write(Palette,SizeOF(Palette));
     S.Write(GlassIndex,SizeOF(GlassIndex));
     S.Write(BrightIndex,SizeOF(BrightIndex));
    end;
    procedure fadetext;
type
  palrec=record
           r,g,b:byte;
         end;
  paltype=array[0..255]of palrec;
  palptr=^paltype;

 var pal:paltype;
     tempal:paltype;

procedure getvgapal(var pal:paltype); assembler;
asm
  push ds
  xor ax,ax
  mov cx,0300h
  les di,pal
  mov dx,03c7h
  out dx,al
  inc dx
  inc dx
  cld
  rep insb
  pop ds
end;
procedure setvgapal(var pal:paltype); assembler;
asm
  push ds
  xor ax,ax
  mov cx,0300h/2
  lds si,pal
  mov dx,03c8h
  out dx,al
  inc dx
  mov bx,dx
  cld
  mov dx,03dah
  @vsync0:
    in al,dx
    test al,8
  jz @vsync0
  mov dx,bx
  rep outsb
  mov bx,dx
  mov dx,03dah
  @vsync1:
    in al,dx
    test al,8
  jz @vsync1
  mov dx,bx
  mov cx,0300h/2
  rep outsb
  pop ds
end;

procedure f2black(palin:paltype);
var
  dac,i:word;
begin
  for i:=15 downto 0 do
  begin
    for dac:=0 to 255 do
    begin
      tempal[dac].r:=(palin[dac].r*i)div 32;
      tempal[dac].g:=(palin[dac].g*i)div 32;
      tempal[dac].b:=(palin[dac].b*i)div 32;
    end;
    setvgapal(tempal);
  end;
end;

begin
 getvgapal(pal);
 f2black(pal);
end;
end.