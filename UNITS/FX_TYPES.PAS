Unit fx_types;

interface

Uses objects;

Type
     TByteArray=array[0..65535-$8] of byte;
     TFileID=array[0..7] of char;
Const
     DeviceID:TFileID='FXDevice';
     BitMapID:TFileID='FXBitmap';
     ColMapID:TFileID='FXPalMap';
     CursorID:TFileID='FXCursor';

     cMaxWidth=360;
     cMaxHeight=240;

Type
    Tbuffer=array[0..cMaxWidth] of byte;

type
     PPen=^TPen;
     TPen=object(TObject)
      constructor Init;
      {
        p - pointer to start
        len - length of horisontal line
      }
      procedure HLine(p:pointer;len:word);virtual;
      {
       Width of pen - default is 1
      }
      function Width:word;virtual;
      {
        p - pointer to start
        len - length of vertical line
        width - width of screen
      }
      procedure VLine(p:pointer;len,wid:word);virtual;
      { set alone point }
      procedure Point(p:pointer);
     end;

implementation

     procedure TPen.Point;
     begin HLine(p,1); end;
     constructor TPen.Init;
     begin TObject.Init;end;
     procedure TPen.VLine;
     begin abstract; end;
     procedure TPen.HLine;
     begin abstract; end;
     function TPen.Width;
     begin width:=1; end;

end.