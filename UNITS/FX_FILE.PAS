Unit fx_file;

interface

Const
      cfREAD      =$0001;
      cfREWRITE   =$0002;

      ctxtREAD    =$0001;
      ctxtREWRITE =$0002;
      ctxtAPPEND  =$0003;

procedure fopen( var f:file; filename:string; mode:word );
procedure fopentext( var f:text; filename:string; mode:word );

function readstr(var f:text):string;

procedure formatstr(var s:string);
function readstrf(var f:text):string;
procedure toarea(var f:text; areaname:string);

Function Command(Var F:Text;S:string):String;
Function Value(Var F:Text;S:String):string;

implementation

Uses misc,core,tpstr;

procedure fopen( var f:file; filename:string; mode:word );
 var err:integer;
begin
 Assign(f,filename);
 {$I-}
 Case mode of
  cfREAD     :  reset(f,1);
  cfREWRITE  :rewrite(f,1);
 end;
 err:=IOResult;
 {$I+}
 if err<>0 then Exeption(cFATAL_ERR,str2PCHAR('File '+filename+' couldn`t be opened'));
end;

procedure fopentext( var f:text; filename:string; mode:word );
 var err:integer;
begin
 Assign(f,filename);
 {$I-}
 Case mode of
  ctxtREAD     :  reset(f);
  ctxtREWRITE  :rewrite(f);
  ctxtAPPEND   : append(f);
 end;
 err:=IOResult;
 {$I+}
 if err<>0 then Exeption(err,Str2PChar('File '+filename+' couldn`t be opened'));
end;

function readstr(var f:text):string;
 var s:string;
begin
 readln(f,s);
 readstr:=s;
end;
procedure formatstr(var s:string);
begin
 tpstr.formatstr(s);
end;
{ read it and format }
function readstrf(var f:text):string;
 var s:string;
begin
 repeat
  readln(f,s);
  formatstr(s);
 until s<>'';
 readstrf:=s;
end;

{
area header:
[<Area_name>]
}
function same_area(s:string; areaname:string):boolean;
begin
 same_area:=same(s,'['+areaname+']');
end;

procedure toarea(var f:text; areaname:string);
 var s:string;
begin
 repeat
  s:=readstrf(f);
 until eof(f) or same_area(s,areaname);
end;

Function Command(Var F:Text;S:string):String;
 Var S1:String;
begin
  s1:=ReadStrf(f);
  While (not same(s,copy(s1,1,length(s)))) do
   if Eof(f) then
    begin
     Command:='';
     Exit;
    end else S1:=ReadStr(F);
  Command:=S1;
end;

Function Value(Var F:Text;S:String):string;
begin
 Value:=Argument(Command(f,s),1);
end;

end.
