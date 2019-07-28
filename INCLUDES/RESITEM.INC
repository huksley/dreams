const
      XMSBufMinSize=1024;
      XMSBufMaxSize=XMSBufMinSize*16;
type
     PResourceItem=^TResourceItem;
     TResourceItem=object(TObject)
      BufStream:PXMSStream;
      constructor Reset;
      constructor Load(Var S:TStream);
      procedure Store(Var S:TStream);
      destructor Done; virtual;
     end;

const
     ResItemREC:TStreamREC=(
      ObjType: 1024;
      VMTLink: OFS(TYPEOF(TResourceItem)^);
      Load: @TResourceItem.Load;
      Store: @TResourceItem.Store );

     constructor TResourceItem.Reset;
     begin
      TObject.Init;
      New(BufStream,Init( XMSBufMinSize,
                          XMSBufMaxSize ));
     end;
     destructor TResourceItem.Done;
     begin
      Dispose(BufStream,Done);
      TObject.Done;
     end;
     constructor TResourceItem.Load;
      Var Size:LongInt;
     begin
      Reset;
      S.Read(Size,SIZEOF(Size));
      BufStream^.CopyFROM(S,Size);
     end;
     procedure TResourceItem.Store;
      Var Size:LongInt;
     begin
      Size:=BufStream^.GetSize;
      S.Write(Size,SIZEOF(Size));
      S.CopyFROM(BufStream^,Size);
     end;
