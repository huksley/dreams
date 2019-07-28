Unit flGraph;

interface

Uses tpstr,fx_form,objects,types,fx_dev;

var
     menu_dev,about_dev,wize_dev:word;

const
        cView      :viewrec=(
         x:  0; y:  0; w:259; h:174 );

        cStatus    :viewrec=(
         x:  0; y:160; w:260; h:10  );

        cMenu      :viewrec=(
         x:260; y:  0; w: 60; h:200 );

        cDreams    :viewrec=(
         x:265; y:  5; w: 50; h: 15 );
        cWizecore  :viewrec=(
         x:264; y:183; w: 53; h: 14 );

 const
      locwinx   =0;
      locwiny   =0;
      locwidth  =259;
      locheight =174;

      sidex     =260;
      sidey     =0;
      sidewidth =60;
      sideheight=200;

      menux     =sidex+2;
      menuy     =sidey+87;
      menumaxlen=110;

      aboutx    =275;
      abouty    =5;
      aboutw    =40;
      abouth    =20;

const
     cCHOOSE_PICKTHING   = 'Вы должны выбpать пpедмет';

const
     colorx=260;
     colory=185;
     colorw=50;
     colorh=20;

     color:trect=(
      a:(x:colorx;y:colory);
      b:(x:colorx+colorw-1; y:colorx+colorh-1));

     locrect:trect=(
      a:(x:locwinx; y:locwiny);
      b:(x:locwinx+locwidth-1; y:locwiny+locheight-1));

     about:trect=(
      a:(x:aboutx; y:abouty);
      b:(x:aboutx+aboutw-1; y:abouty+abouth-1));

 function ChooseThing:nstring;
 procedure dshow_em(c:byte; dev:pdevice);
 procedure makeit_glassy(x,y,w,h:integer; delay:integer);

 procedure init_main;
 procedure done_main;
 procedure clip;
 procedure clipoff;
 procedure aboutmenu;
 procedure wizemenu;
 function MessageWindow(p:PstringArr):Boolean;
 function messWinXY(x,y:word; p:PstringArr):ptextwindow;
 function show_arr(x,y:integer; title:nstring; text:pstringarr):integer;

 procedure putline_text(s:string);
 function show_text:Boolean;
 procedure message(s:string);
 procedure writeline(s:string);
 function receive(s:string):string;
 procedure end_text;

implementation

Uses data,kernel,core,streams,things,status,
     fx_mouse,fx_pens,fx_types,flscript,flaction,
     fx_fonts,fx_pal,res_type,fx_shape,constants,
     sysinfo,time,fx_init,imgstack,flobjects,
     locview,play,sounds,fx_cons;

 procedure makeit_glassy(x,y,w,h:integer; delay:integer);
  var glass:pconvertpen;
 begin
  new(glass,init(Palette^.glassindex));
   click_it(x,y,w,h,glass,delay,screen);
  dispose(glass,done);
 end;

    function show_arr(x,y:integer; title:types.nstring; text:pstringarr):integer;
     var buttons:pbutton_line;
         visible:byte;
         tsize,size:word;
         a,pressed:integer;
    begin
     if text^.count<=5 then visible:=text^.count else visible:=5;
     size:=LightFont^.lnWidth(title);

               for a:=0 to text^.count-1 do begin
               tsize:=lightfont^.lnWidth(text^.get(a));
               if tsize>size then size:=tsize;
              end;

     size:=size+22;

     new(buttons,init(visible,size,title));
     for a:=0 to text^.count-1 do buttons^.add_butt(text^.get(a));
     hide_mouse;
     buttons^.show(x,y);
     show_mouse;
     pressed:=-1;
     while pressed=-1 do
      if mousebuttons<>0
      then pressed:=buttons^.pressed(mouseposx,mouseposy);

     show_arr:=pressed;
     hide_mouse;
     dispose(buttons,done);
     show_mouse;
    end;

function receive;
 var edit:pedit_line;
begin
 new(edit,init(s,200));
  receive:=edit^.edit;
 dispose(edit,done);
end;

procedure writeline;
begin
 putline_text(s);
end;

 var clipbuff:pointer;
     bufftext:pstringarr;

 procedure end_text;
 begin
  if bufftext<>nil then dispose(bufftext,done);
{  new(bufftext,init);}
  bufftext:=nil;
 end;

  procedure clip;
  begin
   getmem(clipbuff,320*200);
   move(Screen^.start^,clipbuff^,320*200);
  end;
  procedure clipoff;
  begin
   move(clipbuff^,screen^.start^,320*200);
   freemem(clipbuff,320*200);
  end;

  procedure init_main;
   var c:pcolorpen;
  begin
{   echo_of_dreams:=loaddev('ECHOPIC');}
   menu_dev:=loaddev('MAINMENU');
   about_dev:=loaddev('ABOUTTEXT');
   wize_dev:=loaddev('WIZETEXT');

{   press_snd.load(res^.loadres('PRESS_SND')^);
   scroll_snd.load(res^.loadres('PRESS_SND')^);
   open_snd.load(res^.loadres('OPEN_SND')^);
   close_snd.load(res^.loadres('CLOSE_SND')^);}

  end;
  procedure done_main;
  begin
  end;

  procedure aboutmenu;
  begin
   PlaySound(sndOpenWin);
   hide_mouse;
   clip;
   images^.center(about_dev,screen);
   show_mouse;
   anyclick;
   hide_mouse;
   clipoff;
   show_mouse;
   PlaySound(sndCloseWin);
  end;

  procedure wizemenu;
  begin
   PlaySound(sndOpenWin);
   hide_mouse;
   clip;
   images^.center(wize_dev,screen);
   show_mouse;
   anyclick;
   hide_mouse;
   clipoff;
   show_mouse;
   PlaySound(sndCloseWin);
  end;


  function MessageWindow(p:PstringArr):boolean;
   var twin:ptextwindow;
       a:integer;
       s:string;
       fr:{parr_frame}pframe;
       size,tsize:word;
  begin
   if (not assigned(p)) or (p^.count=0) then exit;
   s:=p^.get(p^.maxlennum);
   size:=0; for a:=0 to p^.count-1 do begin
             tsize:=lightfont^.lnWidth(p^.get(a));
             if tsize>size then size:=tsize;
            end; size:=size+3;
{   fr:=new(parr_frame,init);
   for a:=0 to cmenufr_size-1 do fr^.put(new(pcolorpen,init(cmenuc[a])),yes);
}
   fr:=rnd_fr;
   new(twin,
            init( p^.count,size,
                  make_form(
                            fr,
                            new(pconvertpen,init(Palette^.GlassIndex)),
                            lightfont),screen));

   for a:=0 to p^.count-1 do twin^.put(p^.get(a));
   PlaySound(sndOpenWIn);
   hide_mouse;
   twin^.center;
   show_mouse;
   MessageWindow:=anyclick;
   PlaySound(sndCloseWin);
   hide_mouse;
   dispose(twin,done);
   show_mouse;
  end;

  function messWinXY(x,y:word; p:PstringArr):ptextwindow;
   var twin:ptextwindow;
       a:integer;
       s:string;
       fr:{parr_frame}pframe;
       size,tsize:word;
  begin
   if (not assigned(p)) or (p^.count=0) then exit;
   size:=0; for a:=0 to p^.count-1 do begin
             tsize:=lightfont^.lnWidth(p^.get(a));
             if tsize>size then size:=tsize;
            end; size:=size+3;
{   fr:=new(parr_frame,init);
   for a:=0 to cmenufr_size-1 do fr^.put(new(pcolorpen,init(cmenuc[a])),yes);}
   fr:=Good_fr;
   new(twin,
            init( p^.count,size,
                  make_form(
                            fr,
                            new(pcolorpen,init(cmenuground)),
                            lightfont),screen));

   for a:=0 to p^.count-1 do twin^.put(p^.get(a));
   PlaySound(sndOpenWin);
   hide_mouse;
   twin^.show(x,y);
   show_mouse;
   messWinXY:=twin;
  end;

  procedure putline_text(s:string);
  begin
   if bufftext=nil then new(bufftext,init);
   bufftext^.put(s);
  end;
  function show_text;
  begin
   if bufftext=nil then exit;
   Show_Text:=MessageWindow(bufftext);
   dispose(bufftext,done);
   bufftext:=nil;
  end;
  procedure message(s:string);
  begin
   putline_text(s);
   show_text;
  end;

function ChooseThing:types.nstring;
 var
     Choosed:Boolean;
     x,y:integer;
     s,s1:nstring;
     Kind:pFlashObject;
     pnt:TPoint;
   {$IFNDEF DELPHI}
    Var Result:NString;
   {$ENDIF}
begin
 Choosed:=false;
 While not choosed do begin

  if (mouseposx<>x) or (mouseposy<>y)
  then begin
   x:=mouseposx; y:=mouseposy;
   pnt.x:=x; pnt.y:=y;
   if locrect.contains(pnt)
   then begin
    s:=get_name(x,y,loc_id);
    s1:=get_find(x,y,loc_id);
    if FindIn(s1)^.Kind<>nThing then s:=cCHOOSE_INFO;
   end else if in_thingbar(x,y)
            then begin
             s1:=name_thingbar(x,y);
             Kind:=findin(s1);
             if Kind=nil
             then s:=cCHOOSE_INFO
             else s:=Kind^.PlayName;
            end else s:=cCHOOSE_INFO;

   if (s=CURRENTLOC^.PlayNAME) or (s='') then s:=cCHOOSE_INFO;

   if s=cCHOOSE_INFO
   then string2status(s)
   else string2status(cCHOOSE_INFO+' - '+s);
  end;

  if (mousebuttons<>0)
  then begin

   if MouseButtons=02 then begin
    Result:='';
    Break;
   end;

   Kind:=FindIn(s1);
   if (Kind<>nil) and (Kind^.Kind<>nLoc)
   then begin
    Result:=s1;
    Choosed:=true
   end else begin
    ClearInput;
    Message(cCHOOSE_PICKTHING);
   end;

  end;

 end;
 clearinput;
 ChooseThing:=Result;
end;

procedure dshow_em(c:byte; dev:pdevice);
begin
     cview.show(c,dev);
   cstatus.show(c,dev);
     cmenu.show(c,dev);
   cdreams.show(c,dev);
 cwizecore.show(c,dev);
end;

end.
