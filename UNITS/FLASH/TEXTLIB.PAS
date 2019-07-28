Unit TextLib;

interface
uses tpstr;

const
     cMaxTopics=100;
     cNameMax=24;
     cArraySize=(cNameMax+1)*100;

type
    topicrec=record
     name:String[cNameMax];
     pos:word;
    end;

var lib:text;
    topicpos:array[0..cMaxTopics-1] of topicrec;
    topics:integer;

    procedure formtopics(topicfile:string);
    procedure printtopic(topic:string);
    procedure addtopic(topic:string; var text:tstringarr);
    procedure endtopics;
    procedure list_topics;

implementation

Uses fx_cons,flgraph,core,misc,flaction,kernel,tpcomms;

    procedure list_topics;
     var i:integer;
    begin
     for i:=0 to topics-1 do
      console_out(topicpos[i].name);
    end;

    procedure formtopics(topicfile:string);
     var a:longint;
         s:string;
    begin
     assign(lib,topicfile);
     reset(lib);
     topics:=0;
     a:=0;
     while not eof(lib) do
     begin
      readln(lib,s);
      inc(a);
      if same(argument(s,0),'#topic') then begin
       topicpos[topics].name:=argument(s,1);
       topicpos[topics].pos:=a-1;
       inc(topics);
      end;
     end;
    end;
    procedure endtopics;
    begin
     close(lib);
    end;

    function findtopic(topic:string):integer;
     var a:integer;
    begin
     for a:=0 to topics-1 do
      if same(topicpos[a].name,topic)
      then begin
       findtopic:=topicpos[a].pos;
       exit;
      end;
      findtopic:=-1;
    end;


    procedure seektext(var f:text; l:longint);
     var s:string;
         a:longint;
    begin
     reset(f);
     for a:=0 to l-1 do Readln(f,s);
    end;

    procedure addtopic(topic:string; var text:tstringarr);
     var t:integer;
         s,c:string;
    begin
     t:=findtopic(topic);
     if t=-1
     then ErrorMSG(Str2PChar('Can`t find topic '+topic))
     else begin
      seektext(lib,t);
      Readln(lib,s);
      if not same(argument(s,0),'#topic') then Exeption(2,Str2PChar('Seek of topic not correct:'+s));
      Readln(lib,s);
      repeat
       c:=argument(s,0);
       if (not same(c,'#pause')) and (not same(c,'#flash'))
       then text.put(s);
       Readln(lib,s);
      until same(argument(s,0),'#end')
     end;
    end;

    procedure printtopic(topic:string);
     var t:integer;
         s,c:string;
         ch:char;
    begin
     t:=findtopic(topic);
     if t=-1
     then Exeption(1,Str2PChar('Can`t find topic '+topic))
     else begin
      seektext(lib,t);
      Readln(lib,s);
      if not same(argument(s,0),'#topic') then Exeption(2,Str2PChar('Seek of topic not correct:'+s));
      Readln(lib,s);
      repeat
       c:=argument(s,0);
       if same(c,'#pause')
       then begin
        if not show_text then Exit;
       end
       else if same(c,'#flash')
            then makecommand(FindComm(Argument(s,1)),RestString(copy(s,pos(c,s)+length(c)+1,256)))
            else writeline(s);
       Readln(lib,s);
      until same(argument(s,0),'#end');
      show_text;
     end;
    end;
end.
