Unit str;

interface
uses objects;

function allocate(size:word):pointer;
procedure dealloc(var p:pstring);
function pack_str(s:string):pstring;
function expand_str(p:pstring):string;


implementation

function allocate(size:word):pointer;
 var p:pointer;
begin
 getmem(p,size);
 allocate:=p;
end;
procedure dealloc(var p:pstring);
begin
 if p<>nil then freemem(p,length(p^)+1);
 p:=nil;
end;
function pack_str(s:string):pstring;
 var p:pstring;
begin
 p:=allocate(length(s)+1);
 move(s,p^,length(s)+1);
 pack_str:=p;
end;
function expand_str(p:pstring):string;
var p1:pstring;
begin
 expand_str:=p^;
 p1:=p;
 Freemem(p1,length(p^)+1);
end;

end.