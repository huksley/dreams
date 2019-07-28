Unit button;

interface

uses tpstr,types;

const
     cMaxButtons = 32;
     cDescSize   = 32;
     cNoIcon     = '';
     cDefWid     = 10;
     cDefHgt     = 10;
     cDefColor   = 123;
     cClickDelay = 100;
     cButtonItem = 'button';
     cNoSuchButton = 'Hет такой команды - ';
type
    buttonrec = record
     x,y,w,h:integer;
     desc:String[cDescSize];
     icon:tstring;
     run:tstring;
    end;

    buttonlist = array[0..cMaxButtons-1] of buttonrec;

    buttondat  = record
     list:buttonlist;
     size:integer;
    end;

     procedure unpack_arr(arr:PStringArr; var buttons:buttondat);
     function in_buttons(x,y:integer; var buttons:buttondat):boolean;
     procedure show_buttons(var buttons:buttondat);
     procedure buttons_click(x,y:integer; var buttons:buttondat);
     function buttons_desc(x,y:integer; var buttons:buttondat):string;

implementation


uses fx_dev,misc,fx_mouse,
     fx_pens,fx_form,tpparam,flashcom,
     flobjects,fx_init,flgraph;

    procedure unpack2rec(pack:string; var item:buttonrec);
     var dev:pdevice;
    begin
     with item do begin
      x:=toint(get_var('x',pack));
      y:=toint(get_var('y',pack));
      desc:=get_var('desc',pack);
      icon:=get_var('icon',pack);
      run:=get_var('run',pack);
      if icon<>cNoIcon then begin
       dev:=New(PDevice,Load(res^.LoadRes(icon)^));
       w:=dev^.Width;
       h:=dev^.Height;
       Dispose(Dev,Done);
      end else begin
       w:=cDefWid; h:=cDefHgt;
      end;
     end;
    end;

    procedure show_button(var button:buttonrec);
     var p:pcolorpen;
         dev:pdevice;
    begin
     with button do begin
      if icon=cNoIcon
      then begin
       New(p,init(cDefColor));
       Screen^.Rectangle(x,y,x+w-1,y+h-1,p);
       Dispose(p,done);
      end else begin
       dev:=New(PDevice,Load(res^.LoadRes(icon)^));
       dev^.fulldevicecopy(x,y,Screen);
       dispose(dev,done);
      end;
     end;
    end;

    function in_button(x,y:integer; var button:buttonrec):boolean;
    begin
     in_button:= belongs(x,button.x,button.x+button.w-1) and
                 belongs(y,button.y,button.y+button.h-1);
    end;

    procedure click_button(var button:buttonrec);
     var p:pCommands;
    begin
     with button do makeit_glassy(x,y,w,h,cClickDelay);
     p:=Player^.Acts^.GetName(button.run);
     if p<>nil
     then P^.run
     else Message(cNoSuchButton+Button.run);
    end;


    procedure unpack_arr(arr:PStringArr; var buttons:buttondat);
      var cmd:string;
          pack:string;
          i:integer;
          listsize:integer;
     begin
      listsize:=0;
      for i:=0 to arr^.count-1 do begin

       cmd:=Arr^.Get(i);
       pack:=ArgTail(cmd);
       cmd:=Argument(Cmd,0);

       if Same(cmd,cButtonItem) then begin
                                    unpack2rec(pack,buttons.list[listsize]);
                                    inc(listsize);
                                   end;
      end;
      buttons.size:=listsize;
     end;

     function in_buttons(x,y:integer; var buttons:buttondat):boolean;
      var i:integer;
     begin
      in_buttons:=false;
      for i:=0 to buttons.size-1 do
       if in_button(x,y,buttons.list[i])
       then begin
        in_buttons:=true;
        exit;
       end;
     end;

     procedure show_buttons(var buttons:buttondat);
      var i:integer;
     begin
      for i:=0 to buttons.size-1 do show_button(buttons.list[i]);
     end;

     procedure buttons_click(x,y:integer; var buttons:buttondat);
      var i:integer;
     begin
      for i:=0 to buttons.size-1 do
       if in_button(x,y,buttons.list[i])
       then begin
        click_button(buttons.list[i]);
        exit;
       end;
     end;

     function buttons_desc(x,y:integer; var buttons:buttondat):string;
      var i:integer;
     begin
      buttons_desc:='';
      for i:=0 to buttons.size-1 do
       if in_button(x,y,buttons.list[i])
       then begin
        buttons_desc:=buttons.list[i].desc;
        exit;
       end;
     end;

end.



