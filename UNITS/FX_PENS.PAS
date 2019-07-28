Unit fx_pens;

interface
Uses kernel,objects,fx_pal,fx_types,fx_dev;


Type
     PHidePen=^THidePen;
     THidePen=object(TPen)
      procedure HLine(p:pointer;len:word);virtual;
      procedure VLine(p:pointer;len,wid:word);virtual;
     end;

Type
    PColorPen=^TColorPen;
    TColorPen=object(TPen)
     Private
      Color:byte;
     Public
     constructor Init(c:byte);

     function GetColor:byte;
     procedure SetColor(c:byte);

     procedure HLine(p:pointer;len:word);virtual;
     procedure VLine(p:pointer;len,wid:word);virtual;
    end;

Type
    PInversePen=^TInversePen;
    TInversePen=object(TPen)
     procedure HLine(p:pointer;len:word);virtual;
     procedure VLine(p:pointer;len,wid:word);virtual;
    end;

type
    PConvertPen=^TConvertPen;
    TConvertPen=object(TPen)
     Private
      Table:TTable;
     Public
      constructor Init(ATable:TTable);

      procedure GetTable(ATable:TTable);
      procedure SetTable(ATable:TTable);

      procedure HLine(p:pointer;len:word);virtual;
      procedure VLine(p:pointer;len,wid:word);virtual;
     end;
type
    { this structure doesn`t destruct Start - you must do it your self }
    PTexturePen=^TTexturePen;
    TTexturePen=object(TPen)
     Start:Pointer;
     TWidth:Word;
     constructor Init(ATexture:Pointer;AWidth:Word);
     procedure HLine(p:pointer;len:word);virtual;
     procedure VLine(p:pointer;len,wid:word);virtual;
    end;

type
    PRandomPen=^TRandomPen;
    TRandomPen=object(TPen)
      function rnd:byte;
      constructor Init;

      procedure HLine(p:pointer;len:word);virtual;
      procedure VLine(p:pointer;len,wid:word);virtual;
    end;
implementation

     procedure THidePen.HLine;
     begin end;
     procedure THidePen.VLine;
     begin end;

    function TColorPen.GetColor;
    begin
     GetColor:=Color;
    end;
    procedure TColorPen.SetColor;
    begin
     Color:=c;
    end;
    constructor TColorPen.Init;
    begin
     TPen.Init; Color:=c;
    end;
    procedure TColorPen.HLine;
    assembler; asm
     cld
     les di,self
     mov al,ES:[DI].TColorPen.Color
     les di,p
     mov cx,len
     rep stosb
    end;
    procedure TColorPen.VLine;
    assembler; asm
     cld
     les di,self
     mov al,ES:[DI].TColorPen.Color
     les di,p
     mov cx,len
     mov dx,wid
     dec dx
     @VColorFill:
      stosb
      add di,dx
     loop @VColorFill
    end;

    procedure TInversePen.HLine;
    assembler; asm
     cld
     les di,p
     mov cx,len
     @InvHPut:
       mov al,ES:[DI]
       not al
       stosb
     loop @InvHPut
    end;
    procedure TInversePen.VLine;
    assembler; asm
     cld
     les di,p
     mov cx,len
     mov dx,wid
     dec dx
     @InvVPut:
      mov al,ES:[DI]
      not al
      stosb
      add di,dx
     loop @InvVPut
    end;


      constructor TConvertPen.Init;
      begin
       TPen.Init; SetTable(ATable);
      end;
      procedure TConvertPen.GetTable;
      begin
       ATable:=Table;
      end;
      procedure TConvertPen.SetTable;
      begin
       Table:=ATable;
      end;
      procedure TConvertPen.HLine;assembler;
      asm
       cld
       mov cx,len
       push ds
        lds si,SELF
        lea bx,ds:[si].TConvertPen.Table
        les di,p
        @LineGlass:
         mov al,es:[di]
         xlat
         stosb
        loop @LineGlass
       pop ds
      end;
      procedure TConvertPen.VLine;
      assembler; asm
       cld
       push ds
       lds si,self
       lea bx,ds:[sI].TConvertPen.Table
       les di,p
       mov cx,len
       mov dx,wid
       dec dx
       @ConvVPut:
        mov al,es:[di]
        xlat
        mov es:[di],al
        add di,dx
        inc di
       loop @ConvVPut
       pop ds
      end;

    function TRandomPen.rnd;
    begin
     rnd:=byte(Random(byte(255)));
    end;
    constructor TRandomPen.init;
    begin
     TPen.Init; Randomize;
    end;
    procedure TRandomPen.Hline;
    assembler; asm
     push ds
     cld
     les di,p
     mov dx,0
     mov ds,dx
     mov cx,len
     @InvHPut:
       mov al,ds:[di]
       add al,5
       stosb
     loop @InvHPut
     pop ds
    end;
    procedure TRandomPen.Vline;
    assembler; asm
     cld
     push ds
     les di,p
     mov cx,len
     mov dx,wid
     dec dx
     mov bx,0
     mov ds,bx
     @InvVPut:
      mov al,ds:[di]
      stosb
      add di,dx
     loop @InvVPut
     pop ds
    end;

    constructor TTexturePen.init;
    begin
     TPen.Init;
     Start:=ATexture;
     TWidth:=AWidth;
    end;
    procedure TTexturePen.HLine;
    assembler;asm
     les di,self
     push ds
     lds si,ES:[DI].Start
     les di,p
     mov si,di
     mov cx,[len]
     rep movsb
     pop ds
    end;
    procedure TTexturePen.VLine;
    assembler; asm
     les di,self
     push ds
     lds si,ES:[DI].TTexturePen.Start
     mov bx,ES:[DI].TTexturePen.TWidth
     les di,p
     mov si,di
     mov dx,[wid]
     mov cx,[len]
     @WriteTEXT:
                mov al,DS:[SI]
                mov ES:[DI],al
                add si,bx
                add di,dx
                loop @WriteTEXT
     pop ds
    end;
end.