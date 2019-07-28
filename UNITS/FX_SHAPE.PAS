Unit fx_shape;

interface

Uses objects,kernel,memory,fx_dev,fx_types,core;

type
    PBitMap=^TBitMap;
    TBitMap=object(TObject)
      XSize,YSize:Word;
      ShapeData:Pointer;
      { allocates space }
      constructor Init(W,H:Word);
      constructor Load(Var S:TStream);
      destructor Done;virtual;
      function Width:word;
      function Height:word;
      procedure Show(device:pdevice;x,y:word);
      procedure Put0(device:pdevice;x,y,exeptcolor:word);
      procedure  Put(device:pdevice;x,y:word);
      procedure  Get(device:pdevice;x,y:word);
      function MemSize:word;
      procedure getdata(var DATA);
      procedure store(var s:tstream);
    end;

type
    PCursor=^TCursor;
    TCursor=object(TObject)
     snapx,snapy:byte;
     data,safe:pbitmap;
     safex,safey:word;
     constructor Init(w,h,sx,sy:byte);
     constructor Load(Var S:TStream);
     destructor Done;virtual;

     procedure Store(Var S:TStream);

     procedure show(dev:pdevice;x,y:word);
     procedure hide(dev:pdevice);

     Private
     procedure _save(dev:pdevice;x,y:word);
     procedure _load(dev:pdevice);
    end;

{ converts bitmap to device }
function bitmap2dev(bitmap:pbitmap):pdevice;
procedure cur2dev(cur:pcursor; var P:TPoint; var Device:PDevice);

implementation
    destructor TBitmap.done;
    begin
     FreeMem(ShapeData,XSize*YSize);
     TObject.Done;
    end;
    constructor TBitMap.Load;
     var id:tfileid;
    begin
     TObject.Init;
     S.Read(id,sizeof(tfileid));
     if (ID<>BitMapID) then ErrorMSG('TBitMap.Load, file format error');
     S.Read(XSize,SizeOF(XSize));
     S.Read(YSize,SizeOF(YSize));
     ShapeData:=MemAlloc(XSize*YSize);
     S.Read(ShapeData^,XSize*YSize);
    end;
    constructor TBitMap.Init;
    begin
     TObject.Init;
     XSize:=W; YSize:=H;
     ShapeData:=MemAlloc(XSize*YSize);
    end;
    function TBitmap.Width;
    begin
     Width:=XSize;
    end;
    function TBitmap.Height;
    begin
     Height:=YSize;
    end;
    procedure TBitMap.Show;
     var bx,by,bx1,by1:word;
    begin
     bx:=x; by:=y; bx1:=x+Width-1; by1:=y+Height-1;
{     device^.cuttofit(bx,by,bx1,by1);}
     if (assigned(ShapeData))
     then Device^.putShape(bx,by,bx1-bx+1,by1-by+1,ShapeData^);
    end;
    procedure TBitMap.Put0;
     var bx,by,bx1,by1:word;
    begin
     bx:=x; by:=y; bx1:=x+Width-1; by1:=y+Height-1;
{     device^.cuttofit(bx,by,bx1,by1);}
     if assigned(ShapeData)
     then Device^.putSprite(bx,by,bx1-bx+1,by1-by+1,exeptcolor,ShapeData^);
    end;
    procedure TBitMap.Put;
    begin
     Show(Device,x,y);
    end;
    procedure TBitMap.Get;
     var bx,by,bx1,by1:word;
    begin
     bx:=x; by:=y; bx1:=x+Width-1; by1:=y+Height-1;
{     device^.cuttofit(bx,by,bx1,by1);}
     if assigned(ShapeData)
     then Device^.GetShape(bx,by,bx1-bx+1,by1-by+1,ShapeData^);
    end;
   procedure  TBitMap.store;
   begin
    S.Write(BitMapID,SizeOF(BitMapID));
    S.Write(XSize,SizeOF(XSIZE));
    S.Write(YSize,SizeOF(YSize));
    S.Write(ShapeData^,Width*Height);
   end;
   function TBitMap.MemSize;
   begin
    MemSize:=Width*Height;
   end;
   procedure TBitMap.getdata;
   begin
    move(Data,ShapeData^,MemSize);
   end;
    procedure  TCursor.Show;
    begin
     _Save(dev,x,y);
     Data^.put0(dev,x-snapx,y-snapy,0);
    end;
    procedure TCursor.Hide;
    begin
     _Load(dev);
    end;
    procedure TCursor._Save;
    begin
     safeX:=x; safeY:=y;
     safe^.get(dev,x-snapX,y-snapY);
    end;
    procedure TCursor._load;
    begin
     safe^.put(dev,safex-snapx,safey-snapy);
    end;
    destructor TCursor.Done;
    begin
     Dispose(Data,Done);
     Dispose(Safe,Done);
     TObject.Done;
    end;
    constructor TCursor.Init;
    begin
     TObject.Init;
     snapX:=sx; snapY:=sy;
     New(Data,init(w,h));
     New(Safe,init(w,h));
    end;
    constructor TCursor.Load;
     var id:tfileid;
    begin
     TObject.Init;
     S.Read(id,sizeof(id));
     if (id<>CursorID) then ErrorMSG('TCursor.Load, file format error');
     S.Read(SnapX,SizeOF(SnapX));
     S.Read(SnapY,SizeOF(SnapY));
     New(Data,Load(S));
     New(Safe,init(Data^.Width,Data^.Height));
    end;
    procedure TCursor.Store;
    begin
     S.Write(CursorID,SizeOF(CursorID));
     S.Write(SnapX,SizeOF(SnapX));
     S.Write(SnapY,SizeOF(SnapY));
     Data^.Store(S);
    end;

{ converts bitmap to device }
function bitmap2dev(bitmap:pbitmap):pdevice;
 var dev:pdevice;
begin
 new(dev,init(bitmap^.width,bitmap^.height));
  bitmap^.show(dev,0,0);
 bitmap2dev:=dev;
end;

procedure cur2dev(cur:pcursor; var P:TPoint; var Device:PDevice);
begin
 Device:=bitmap2dev(cur^.data);
 P.x:=cur^.snapx; P.y:=cur^.snapy;
end;

end.
