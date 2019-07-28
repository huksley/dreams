Unit imgstack;

interface

uses objects,streams,fx_dev;
{$I locrange.pas}
const
     cmaxsize=64;
type
    pimage_stack=^timage_stack;
    timage_stack=object(tobject)
     { offsets in stream for images }
     image:array[0..cmaxsize-1] of longint;
     images:byte;
     { work stream - there is images stored }
     stream:pworkstream;{pxmsstream;}
     constructor init;
     function store(p:pdevice):byte;
     function get(i:word):pdevice;

     procedure show(n,x,y:word;at:pdevice);
     procedure show0(n,x,y:word; at:pdevice);

     procedure center(n:word; at:pdevice);
     { show part x,y,x1,y1 of n image }
     procedure part(n:word; x,y,x1,y1:word; at:pdevice);
     destructor done; virtual;
    end;
implementation
uses kernel,misc,core;
    procedure timage_stack.part;
     var i:pdevice;
    begin
     if belongs(n,0,images) then
     begin
      stream^.seek(image[n]);
      new(i,load(stream^));
      i^.partdevicecopy(x,y,x,y,x1-x+1,y1-y+1,at);
      dispose(i,done);
     end else fatalMSG('no such image stored');
    end;
    function timage_stack.store;
    begin
     if images=cmaxsize
     then fatalMSG('can`t store more images')
     else begin
      store:=images;
      image[images]:=stream^.getpos;
      inc(images);
      p^.store(stream^);
     end;
    end;
    function timage_stack.get;
     var d:pdevice;
    begin
     if belongs(i,0,images) then
     begin
      stream^.seek(image[i]);
      new(d,load(stream^));
      get:=d;
     end else fatalMSG('no such image stored');
    end;

    procedure timage_stack.show;
     var i:pdevice;
    begin
     if belongs(n,0,images) then
     begin
      stream^.seek(image[n]);
      new(i,load(stream^));
      i^.fulldevicecopy(x,y,at);
      dispose(i,done);
     end else fatalMSG('no such image stored');
    end;
    procedure timage_stack.show0;
     var i:pdevice;
    begin
     if belongs(n,0,images) then
     begin
      stream^.seek(image[n]);
      new(i,load(stream^));
      i^.fulldevicecopy0(x,y,at);
      dispose(i,done);
     end else fatalMSG('no such image stored');
    end;
    procedure timage_stack.center;
     var i:pdevice;
         x,y:word;
    begin
     if belongs(n,0,images) then
     begin
      stream^.seek(image[n]);
      new(i,load(stream^));
{      x:=(at^.width-i^.width) div 2 ;
      y:=(at^.height-i^.height) div 2 ;}
{      if (loc_width<i^.width) or (loc_height<i^.height) then
      i^.fulldevicecopy(0,0,at) else begin}
      x:=(loc_width-i^.width) div 2 ;
      y:=(loc_height-i^.height) div 2 ;
{     x:=0; y:=0;}
      i^.fulldevicecopy(x,y,at);
{      end;}
      dispose(i,done);
     end else fatalMSG('no such image stored');
    end;
    constructor timage_stack.init;
    begin
     images:=0;
     new(stream,init(tempstream,1024,1024,forNORAM));
{     new(stream,init(1024,1024));}
    end;
    destructor timage_stack.done;
    begin
     dispose(stream,done);
     tobject.done;
    end;

end.