Unit WordPRO;

interface

type
    tcharfunc=function(ch:char):boolean;

Function DeleteString(sub:string;s:string):string;
Function Extract(FirstS,EndS,InS:string):string;
procedure Replace(subf,subto:String;Var S:String);
procedure Upcase(var s:string);

function equal(s,s1:string):boolean;
function pos(SubStr:string;S:String):byte;
function left_bracket(ch:char):boolean;
function right_bracket(ch:char):boolean;
function space_char(ch:char):boolean;
function next_lbracket(s:string;startpos:byte):byte;
function next_rbracket(s:string;startpos:byte):byte;
function next_notspace(s:string;startpos:byte):byte;
function next_space(s:string;startpos:byte):byte;
function words(s:string):byte;
function word1(s:string; num:byte):string;
function word_pos(s:string;num:byte):byte;
function word_num(s,aword:string):integer;
function check_brackets(s:string):boolean;
function func_present(s:string):boolean;
function func_name(s:string):string;
function func_args(s:string):integer;
function func_arg(s:string;num:byte):string;
function next_check(s:string;startpos:byte;func:tcharfunc):byte;

implementation
Procedure Replace(subf,subto:String;Var S:String);
var s1:string;
begin
 While Pos(subf,s)<>0 do
 begin
  s1:=Copy(s,1,Pos(Subf,s)-1)+subto+Copy(s,Pos(Subf,s)+Length(Subf),length(s));
  s:=s1;
 end;
end;
procedure Upcase(var s:string);
 var
     a:byte;
 function UpCaseCh ( ch : char ) : char ;
  begin
    if (ch>='a') and (ch<='z') then
      ch:=chr (ord ('A')+ord (ch)-ord ('a'))
    else
      if (ch>='а') and (ch<='п') then
        ch:=chr (ord ('А')+ord (ch)-ord ('а'))
      else
        if (ord (ch)>=224) and (ch<='я') then
          ch:=chr(ord ('Р')+ord (ch)-224) ;
    UpCaseCh:=ch ;
  end ;
begin
 for a:=1 to length(s) do s[a]:=upcasech(s[a]);
end;

function equal(s,s1:string):boolean;
begin
 Upcase(s);
 Upcase(s1);
 equal:=(s=s1);
end;

function pos(SubStr:string;S:String):byte;
 var a:byte;
begin
 pos:=0;
 for a:=1 to length(S) do
  if equal(copy(S,a,length(SubStr)),SubStr)
  then begin
   pos:=a; Exit;
  end;
end;

function left_bracket(ch:char):boolean;
begin
 left_bracket:= ( (ch='(') or (ch='[') or (ch='{') );
end;
function right_bracket(ch:char):boolean;
begin
 right_bracket:= ( (ch=')') or (ch=']') or (ch='}') );
end;
function space_char(ch:char):boolean;
begin
 space_char:= ( (ch=' ') or (ch=',') or (ch=':') or (ch=';')
                or (ch='=')
                or left_bracket(ch) or right_bracket(ch) );
end;

function next_lbracket(s:string;startpos:byte):byte;
 var a:byte;
begin
 next_lbracket:=0;
 for a:=startpos+1 to length(s) do
  if left_bracket(s[a])
  then begin
   next_lbracket:=a;
   exit;
  end;
end;

function next_rbracket(s:string;startpos:byte):byte;
 var a:byte;
begin
 next_rbracket:=0;
 for a:=startpos+1 to length(s) do
  if right_bracket(s[a])
  then begin
   next_rbracket:=a;
   exit;
  end;
end;

function next_notspace(s:string;startpos:byte):byte;
 var a:byte;
begin
 next_notspace:=0;
 for a:=startpos+1 to length(s) do
  if not space_char(s[a])
  then begin
   next_notspace:=a;
   exit;
  end;
end;

function next_space(s:string;startpos:byte):byte;
 var a,b:byte;
begin
 next_space:=length(s)+1;
 a:=0;
  for a:=startpos+1 to length(s) do
   if s[a-1]='"'
   then begin
    for b:=a+1 to length(s) do if s[b]='"' then break;
    next_space:=next_space(s,b+1);
    exit;
   end
   else
   if space_char(s[a])
   then begin
    next_space:=a;
    exit;
   end;
end;

function words(s:string):byte;
 var a,p:byte;
begin
 a:=0;
 p:=next_notspace(s,0);
 if p=0 then begin
  words:=0;
  exit;
 end;
 while p<length(s) do
 begin
  p:=next_space(s,p);
  if next_notspace(s,p)<>0
  then begin
   inc(a);
   p:=next_notspace(s,p);
  end;
 end;
 words:=a+1;
end;

function word1(s:string; num:byte):string;
 var an:byte;
     p:byte;
begin
 an:=0;
 p:=next_notspace(s,0);
 while (an<>num) do
 begin
  p:=next_space(s,p);
  if next_notspace(s,p)<>0
  then begin
   inc(an);
   p:=next_notspace(s,p);
  end;
 end;
 word1:=copy(s,p,next_space(s,p)-p);
end;

function word_pos(s:string;num:byte):byte;
 var an:byte;
     p:byte;
begin
 an:=0;
 p:=next_notspace(s,0);
 while (an<>num) do
 begin
  p:=next_space(s,p);
  if next_notspace(s,p)<>0
  then begin
   inc(an);
   p:=next_notspace(s,p);
  end;
 end;
 word_pos:=p;
end;

function word_num(s,aword:string):integer;
 var a:byte;
begin
 word_num:=-1;
 for a:=0 to words(s)-1 do
 begin
  if equal(word1(s,a),aword) then
  begin
   word_num:=a;
   exit;
  end;
 end;
end;

function check_brackets(s:string):boolean;
 var br:shortint;
     a:byte;
begin
 br:=0;
 for a:=1 to length(s) do
 begin
  if left_bracket(s[a]) then dec(br);
  if right_bracket(s[a]) then inc(br);
 end;
 check_brackets:= (br=0);
end;

function func_present(s:string):boolean;
begin
 func_present:=(check_brackets(s) and (next_lbracket(s,0)<>0) );
end;
function func_name(s:string):string;
 var a,b:byte;
     c:integer;
begin
 func_name:='';
 a:=next_lbracket(s,0);
 for c:=0 to words(s)-1 do
 if pos(word1(s,c),s)+length(word1(s,c))=a
 then func_name:=word1(s,c);
end;

function func_args(s:string):integer;
 var a,f:integer;
     s1:string;
begin
 f:=word_num(s,func_name(s));
 func_args:=0;
 if words(s)=0 then exit;
 for a:=f+1 to words(s)-1 do
 begin
  s1:=word1(s,a);
  if check_brackets(copy(s,word_pos(s,a),255))
  then begin
   dec(a);
   break;
  end;
 end;
 func_args:=a-f;
end;

function func_arg(s:string;num:byte):string;
begin
 func_arg:=word1(s,word_num(s,func_name(s))+num+1);
end;

function next_check(s:string;startpos:byte;func:tcharfunc):byte;
 var a:byte;
begin
 next_check:=0;
 for a:=startpos+1 to length(s) do
  if func(s[a])
  then begin
   next_check:=a;
   exit;
  end;
 next_check:=length(s)+1;
end;
Function Extract(FirstS,EndS,InS:string):string;
var StartPos,EndPos:integer;
begin
 StartPos:=Pos(FirstS,InS);
 if StartPos=0 then StartPos:=1;
 EndPos:=Pos(EndS,InS);
 if EndPos=0 then EndPos:=Length(InS)+1;
 Extract:=Copy(InS,StartPos+Length(FirstS),EndPos-StartPos-Length(EndS+FirstS)+1);
end;
Function DeleteString(sub:string;s:string):string;
begin
 Delete(s,pos(sub,s),length(sub));
 DeleteString:=s;
end;

end.
