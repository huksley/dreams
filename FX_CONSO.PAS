Unit fx_console;

interface

uses fx_form,fx_fonts,fx_dev;

type PConsole = ^TConsole;
     TConsole = object(TGr_Object)
      Line : string;
      Wid,Hgt : Word;
      constructor init(AWid,AHgt:Word; afont:pfont; adevice:pdevice);
      destructor  done;         virtual;
      function    width:word;   virtual;
      function    height:word;  virtual;
      procedure   repaint;      virtual;

      procedure  output(s:string);
      function   input:string;
      procedure  cls;
     end;

implementation

 uses misc,data,fx_pens,core;

procedure MoveArea(dev:pdevice; x,y,w,h:word;x1,y1:word);
 var d:pdevice;
begin
 new(d,init(w,h));
  dev^.partdevicecopy(0,0,x,y,w,h,d);
  d^.fulldevicecopy(x1,y1,dev);
 dispose(d,done);
end;

     procedure TConsole.cls;
     begin
      if viewed then repaint;
     end;
     function    TConsole.input;
      var ch:char;
     procedure clearpos;
      var x :integer;
          c:pcolorpen;
     begin
      x:=Font^.lnWIDTH('*');
      new(c,init(cMENUGROUND));
      device^.map(  startx + Font^.LnWidth(Line),
                    starty + Hgt - Font^.LnHeight ,
                    startx + Font^.LnWidth(Line) + x,
                    starty + Hgt ,c );
      dispose(c,done);
     end;
     procedure backdel;
      var ch:char;
          x :integer;
          c:pcolorpen;
     begin
      ch:=Line[Length(Line)];
      Line:=Copy(Line,1,Length(Line)-1);
      x:=Font^.lnWIDTH(ch+'*');
      new(c,init(cMENUGROUND));
      device^.map(  startx + Font^.LnWidth(Line),
                    starty + Hgt - Font^.LnHeight ,
                    startx + Font^.LnWidth(Line) + x,
                    starty + Hgt ,c );
           Font^.Writelen( StartX+1,
                           StartY+Hgt-Font^.lnHeight+1,
                           Wid-2,Device,Line+'*');
      dispose(c,done);
     end;
     begin
      if not viewed then ErrorMSG('Can`t input from console in INVISIBLE state !');
      output('');
      line:='>';
      Font^.Writelen(StartX+1, StartY+Hgt-Font^.lnHeight+1, Wid-2,Device,Line+'-');
      repeat
       ch:=readkey;
       if ch=#13 then begin
        line:=copy(line,2,256);
        input:=line;
        line:=line+'*';
        clearpos;
        exit;
       end else if ch=#8
                then begin
                      if line<>'>' then backdel
                     end
                else begin
                      if Font^.lnWidth(line+'*')>wid-6 then continue;
                      clearpos;
                      Line:=line + ch;
                      Font^.Writelen( StartX+1,
                                           StartY+Hgt-Font^.lnHeight+1,
                                           Wid-2,Device,Line+'*');
                     end;
      until ch=#13;
     end;
     procedure   TConsole.output;
      var c:pcolorpen;
     begin
      if not viewed then exit;
      MoveArea( Device,StartX+1,StartY+Font^.lnHeight + 2,
                Wid,Hgt-Font^.lnHeight - 1,
                StartX+1,StartY+1);
      new(c,init(cMENUGROUND));
       device^.map( StartX,StartY+Hgt-Font^.lnHeight,
                    StartX+Wid-1,StartY+Hgt,c);
      dispose(c,done);
      Font^.Writelen(StartX+1, StartY+Hgt-Font^.lnHeight+1, Wid-2,Device,s);
      Line := S;
     end;
     procedure   TConsole.repaint;
     begin
     end;
     constructor TConsole.init;
     begin
      inherited init( make_form(butt_fr,new(pcolorpen,init(cMENUGROUND)),afont),
                      3, adevice);
      Wid:=AWid;
      Hgt:=AHgt;
     end;
     destructor TConsole.Done;
     begin
      inherited done;
     end;
     function TConsole.width;
     begin
      width := inherited width + Wid + 2;
     end;
     function TConsole.Height;
     begin
      height := inherited height + Hgt + 2;
     end;

end.