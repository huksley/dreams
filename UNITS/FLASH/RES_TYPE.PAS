Unit Res_type;
{$I stdefine.inc}
{$DEFINE NOPACK}
interface

uses objects;

type
    pobject_space=^tobject_space;
    tobject_space=object(TObject)
     _stream:pstream;
     constructor init(usestream:pstream);
     destructor done; virtual;
     function stream:pstream;
     constructor load(var s:tstream);
     procedure store(var s:tstream);
    end;
type
    pres_file=^tres_file;
    tres_file=object(tobject)
     resfile:presourcefile;
     space:pobject_space;
     constructor init(filename:string; fmode,lmode:word);
     destructor done; virtual;
     function loadres(resname:string):pstream;
     procedure storeres(resname:string;var stream:tstream);
     procedure put_file(filename:string; resname:string);
    end;

implementation

Uses streams,kernel,misc,core,tpdos;

const
    robject_space:tstreamrec=(
     objtype:9851;
     VMTLink:ofs(TypeOF(tobject_space)^);
     Load: @tobject_space.load;
     Store: @tobject_space.store );

    constructor tobject_space.init;
    begin
     tobject.init;
     _stream:=usestream;
{     _stream^.seek(0);
     _stream^.truncate;}
    end;
    destructor tobject_space.done;
    begin
     if _stream<>nil then dispose(_stream,done);
     tobject.done;
    end;
    function tobject_space.stream;
    begin
     stream:=_stream;
    end;
    constructor tobject_space.load;
     var asize:longint;
    begin
     {$IFDEF DPMI}
     Init(New(PRAMStream,Init(64*1024-10)));
     {$ELSE}
     Init(New(PXMSStream,Init(1024,1024)));
     {$ENDIF}
     S.Read(asize,sizeof(asize));
     _stream^.seek(0); _stream^.truncate;
     stream^.copyfrom(s,asize);
     _stream^.seek(0);
    end;
    procedure tobject_space.store;
     var asize:longint;
    begin
     asize:=_stream^.getsize;
     S.Write(asize,sizeof(asize));
     _stream^.seek(0);
     S.CopyFrom(_stream^,asize);
     _stream^.seek(0);
    end;
    procedure tres_file.storeres;
    begin
     if space<>nil then dispose(space,done);
     new(space,init(@stream));
     resfile^.put(space,resname);
     space^._stream:=nil;
     dispose(space,done);
     space:=nil;
    end;
    constructor tres_file.init;
    begin
     tobject.init;
     {$IFDEF NOPACK}
     new(resfile,init(new(pdosstream,init(filename,fmode))));
     {$ELSE}
     new(resfile,init(new(plzwfilter,init(new(pbufstream,init(filename,fmode,1024)),lmode))));
     {$ENDIF}
     space:=nil;
    end;
    destructor tres_file.done;
    begin
     dispose(resfile,done);
     if space<>nil
     then dispose(space,done);
    end;
    function tres_file.loadres;
    begin
     loadres:=nil;
     if space<>nil then dispose(space,done);
     space:=pobject_space(resfile^.get(resname));
     if space=nil
     then fatalMSG(Str2Pchar('Can`t find such res - '+resname))
     else loadres:=space^.stream;
    end;

    procedure tres_file.put_file;
     var f:pdosstream;
    begin
     if existfile(filename)
     then begin
      new(f,init(filename,stOpenRead));
      storeres(resname,f^);
      dispose(f,done);
     end else errorMSG(Str2PChar('can`t find file '+filename+' to pack in res-file'));
    end;

begin
 RegisterType(robject_space);
end.