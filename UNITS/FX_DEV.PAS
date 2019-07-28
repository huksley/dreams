{$R-,Q-,S-}
Unit fx_dev;

interface

Uses memory,objects,kernel,fx_types,core,misc;

Type
     PDevice=^TDevice;
     TDevice=object(TObject)
       Start:Pointer;
       MemorySize:Word;
       XSize,YSize:Word;
       function _addrcalc(x,y:word):pointer;
      Public
       constructor InitAt(Place:Pointer;AXSize,AYSize:Word);
       constructor Init(AXSize,AYSize:Word);
       function Height:word;
       function Width:word;
       { plain screen out }
       procedure clear(pen:ppen);
       procedure plot(x,y:word;pen:ppen);
       function getplot(x,y:word):byte;
       procedure hlinear(x,y,w:word;pen:ppen);
       procedure vlinear(x,y,h:word;pen:ppen);
       procedure hline(x,x1,y:word;pen:ppen);
       procedure vline(x,y,y1:word;pen:ppen);
       { though primitives }
       procedure rectangle(x,y,x1,y1:word;pen:ppen);
       procedure map(x,y,x1,y1:word;pen:ppen);
       { line<->memory copying }
       procedure getline(x,y,w:word;var line);
       procedure putline(x,y,w:word;var line);
       procedure putline0(x,y,w:word;var line);
       { shape<->memory copying }
       function shapesize(w,h:word):word;
       procedure getshape(x,y,w,h:word;var shape);
       procedure putshape(x,y,w,h:word;var shape);
       procedure putsprite(x,y:word;w,h,c:byte;var sprite);
       { device<->device copying fx_device  }
       { copyies from himself to Device at tox,toy }
       procedure cuttofit(var x,y,x1,y1:integer);
       function fit(x,y,x1,y1:word):boolean;
       procedure FullDeviceCopy(tox,toy:word;Device:PDevice);
       procedure FullDeviceCopy0(tox,toy:word;Device:PDevice);
       procedure PartDeviceCopy0(tox,toy,fromx,fromy,copyw,copyh:word;Device:PDevice);
       procedure PartDeviceCopy(tox,toy,fromx,fromy,copyw,copyh:word;Device:PDevice);
       procedure TakeShape(tox,toy,fromx,fromy,fromx1,fromy1:word;Device:PDevice);
       { stream copying }
       procedure Store(Var S:TStream);
       constructor Load(Var S:TStream);
       destructor Done;virtual;
     end;

{ this procedure puts one device to another with full checking }
{ and shrink output device to fit in destination }
{ zero specifies is src must be zero transparent(TRUE) or not(FALSE) }
procedure shrinkput(x,y:integer; devfrom,devto:pdevice; zero:boolean);

implementation
     { private parts }
     function TDevice._addrcalc;
     assembler; asm
      les di,self
      mov bx,ES:[DI].TDevice.XSize
      mov ax,[y]
      mul bx
      add ax,[x] { ax contains bytes to pass }
      les di,ES:[DI].TDevice.Start
      add di,ax { es:di - points to (x,y) }
      mov dx,es
      mov ax,di { dx:ax - points to the same }
     end;
     { preparations }
     constructor TDevice.InitAt;
     begin
      TObject.Init;
      Start:=Place;
      XSize:=AXSize; YSize:=AYSize;
      MemorySize:=XSize*YSize;
     end;
     constructor TDevice.Init;
     begin
      TObject.Init;
      XSize:=AXSize; YSize:=AYSize;
      MemorySize:=XSize*YSize;
      GetMem(Start,MemorySize);
     end;
     function TDevice.Height;
     begin
      Height:=YSize;
     end;
     function TDevice.Width;
     begin
      Width:=XSize;
     end;
     { primitives }
     procedure TDevice.clear;
     begin
      pen^.hline(start,memorysize);
     end;
     procedure TDevice.plot;
     begin
      hlinear(x,y,1,pen);
     end;
     procedure TDevice.hlinear;
     begin
      pen^.hline(_addrcalc(x,y),w);
     end;
     procedure TDevice.vlinear;
     begin
      pen^.vline(_addrcalc(x,y),h,XSize);
     end;
     procedure TDevice.hline;
     begin
      hlinear(x,y,x1-x+1,pen);
     end;
     procedure TDevice.vline;
     begin
      vlinear(x,y,y1-y+1,pen);
     end;
     { though }
     procedure TDevice.rectangle;
     begin
      hline(x,x1,y,pen);
      vline(x1,y,y1,pen);
      hline(x,x1,y1,pen);
      vline(x,y,y1,pen);
     end;
     procedure TDevice.map;
      var a,w,h:word;
     begin
      w:=x1-x+1; h:=y1-y;
      for a:=0 to h do hlinear(x,y+a,w,pen);
     end;
     { line&memory }
     procedure TDevice.getline;
     begin
      move(_addrcalc(x,y)^,line,w);
     end;
     procedure TDevice.putline;
     begin
      move(line,_addrcalc(x,y)^,w);
     end;
     procedure TDevice.putline0;
{      var a:word;
      type
          tbytearr=array[0..65520] of byte;
     begin
      for a:=0 to w-1 do
          if tbytearr(line)[a]<>0
          then move(tbytearr(line)[a],ptr(seg(start^),ofs(start^)+x+y*width+a)^,1);}
     assembler; asm
      les di,self
      push [x]
      push [y]
      push es
      push di
      call _addrcalc
      mov cx,w
      push ds
      lds si,[line]
      @@makewrt:
        mov al,ds:[si]
        inc si
        cmp al,0
        je @@skip
        mov es:[di],al
        @@skip:
        inc di
        loop @@makewrt
      pop ds
     end;
     { shape&memory }
     function TDevice.shapesize;
     begin
      shapesize:=w*h;
     end;
     procedure TDevice.getshape;
      var a,c:word;
     begin
      c:=0;
      for a:=0 to h-1 do
      begin
       getline(x,y+a,w,tbytearray(shape)[c]);
       c:=c+w;
      end;
     end;
     procedure TDevice.putshape;
      var a,c:word;
     begin
      c:=0;
      for a:=0 to h-1 do
      begin
       putline(x,y+a,w,tbytearray(shape)[c]);
       c:=c+w;
      end;
     end;
     procedure TDevice.putsprite;
     assembler; asm
      les di,self
      mov bx,ES:[DI].TDevice.XSize
      push bx
      push [x]
      push [y]
      push es
      push di
      call _addrcalc
      pop bx
     push ds
     lds si,[sprite]
     mov al,[w]
     mov ah,0
     mov dl,[h]
     mov dh,0
     mov ch,0
     mov cl,[h]
     @lp1:
          push cx
          mov cl,[w]
          @lp2:
               mov al,ds:[si]
               inc si
               cmp al,0
               jz @pass
               mov es:[di],al
               @pass:
               inc di
               loop @lp2
          mov al,[w]
          sub di,ax
          add di,bx
          pop cx
          loop @lp1
          pop ds
     end;
     procedure TDevice.FullDeviceCopy;
      var a:word;
          buffer:tbuffer;
     begin
      for a:=0 to Height-1 do
      begin
       getline(0,a,Width,buffer);
       device^.putline(tox,toy+a,Width,buffer);
      end;
     end;
     procedure TDevice.FullDeviceCopy0;
      var a:word;
          buffer:tbuffer;
     begin
      for a:=0 to Height-1 do
      begin
       getline(0,a,Width,buffer);
       device^.putline0(tox,toy+a,Width,buffer);
      end;
     end;
     procedure TDevice.PartDeviceCopy0;
      var a:word;
          buffer:tbuffer;
     begin
      for a:=0 to copyh-1 do
      begin
       getline(fromx,fromy+a,copyw,buffer);
       device^.putline0(tox,toy+a,copyw,buffer);
      end;
     end;
     procedure TDevice.PartDeviceCopy;
      var a:word;
          buffer:tbuffer;
     begin
      for a:=0 to copyh-1 do
      begin
       getline(fromx,fromy+a,copyw,buffer);
       device^.putline(tox,toy+a,copyw,buffer);
      end;
     end;
     procedure TDevice.Store;
     begin
      S.Write(DeviceID,SizeOF(DeviceID));
      S.Write(XSize,SizeOF(XSize));
      S.Write(YSize,SizeOF(YSize));
      S.Write(Start^,Width*Height);
     end;
     constructor TDevice.Load;
      var a,w,h:word;
          id:TFileID;
     begin
      S.Read(id,SizeOF(ID));
      if (Id<>DeviceID) then ErrorMSG('TDevice.Load');
      S.Read(w,sizeof(w));
      S.Read(h,sizeof(h));
      Init(w,h);
      S.Read(Start^,Width*Height);
     end;
     procedure TDevice.CutTOFit;
     begin
      if x<0 then x:=0;
      if y<0 then y:=0;
      if x>=Width then x:=Width-1;
      if y>=Height then y:=Height-1;
      if x1>=Width then x1:=Width-1;
      if y1>=Height then y1:=Height-1;
     end;
     function TDevice.FIT;
     begin
      fit:= belongs( x,0,Width-1) and
            belongs(x1,0,Width-1) and
            belongs( y,0,Height-1) and
            belongs(y1,0,Height-1);
     end;
     destructor  TDevice.Done;
     begin
      if (Assigned(Start))and(Seg(Start^)<$A000)
      then FreeMem(Start,MemorySize);
      Tobject.done;
     end;
     procedure TDevice.TakeShape;
     begin
      Device^.PartDeviceCopy( tox,toy,
                              fromx,fromy,
                              fromx1-fromx+1,
                              fromy1-fromy+1,@Self)
     end;

{ this procedure puts one device to another with full checking }
{ and shrink output device to fit in destination }
{ zero specifies is src must be zero transparent(TRUE) or not(FALSE) }
procedure shrinkput(x,y:integer; devfrom,devto:pdevice; zero:boolean);
 var roundx1,roundy1:integer;
     roundx2,roundy2:integer;
     videorect:trect;
begin
 videorect.assign(0,0,devto^.width-1,devto^.height-1);

 roundx1:=x; roundy1:=y;
 roundx2:=x+devfrom^.width-1; roundy2:=y+devfrom^.height-1;
 if videorect.contains(roundx1,roundy1) and
    videorect.contains(roundx2,roundy2)
 then begin { no checking performed }
  if zero
  then { zero-transparent putting }
   devfrom^.fulldevicecopy0(x,y,devto)
  else { standart draw }
   devfrom^.fulldevicecopy(x,y,devto);
 end else begin { do rounding }
  devto^.cuttofit(roundx1,roundy1,roundx2,roundy2);
  if zero
  then { zero-transparent putting }
   devfrom^.partdevicecopy0( roundx1,roundy1,roundx1-x,roundy1-y,
                             roundx2-roundx1+1,roundy2-roundy1+1,devto)
  else { standart draw }
   devfrom^.partdevicecopy0( roundx1,roundy1,roundx1-x,roundy1-y,
                            roundx2-roundx1+1,roundy2-roundy1+1,devto);
 end;
end;

 function tdevice.getplot(x,y:word):byte;
  var b:byte;
 begin
  getline(x,y,1,b);
  getplot:=b;
 end;


end.