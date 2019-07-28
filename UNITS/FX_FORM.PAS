Unit fx_form;

interface

Uses
    data,objects,fx_dev,
    fx_pens,fx_types,fx_fonts,tpstr,types;

const
      no=false;
      yes=true;
      off=false;
const
     cEXT_RECT = 4;
     cHLF_RECT = 2;
     cDOALL_FORM_BACK=true;
const
     cPIX1_NAME = 'FRAME_EL1';
     cPIX2_NAME = 'FRAME_EL2';
     cPIX3_NAME = 'FRAME_EL3';

     cLine1Pen  = 170;
     cLine2Pen  = 162;
Const
     cZoomRectCol = 150;

var  pix1,pix2,pix3:pdevice;

type
    storetype=record
     device:pdevice;
     x,y:word;
     wid,hei:word;
     data:pdevice;
    end;

     Const
          cColorCells_W = 20;
          cColorCells_H = 13;
          cColorCell_W  = 6;
          cColorCell_H  = 5;

     function PickColor(x,y:integer):byte;

const cSW_TRUE  = 'SW_ON_BUTT';
      cSW_FALSE = 'SW_OFF_BUTT';

var   Switch_true,Switch_false:PDevice;

const
     storeheadsize=sizeof(storetype);

     procedure gfxstore(dev:pdevice; x,y,w,h:word; var p:pointer);
     procedure gfxfresh(var p:pointer);
     procedure gfxdone(var p:pointer);
     procedure gfxload(var p:pointer);

type
    PFrame=^TFrame;
    TFrame=object(TObject)
     function Width:word;virtual;
     procedure draw_fr(dev:pdevice;x,y,x1,y1:word); virtual;
     procedure DrawAround(dev:pdevice;x,y,x1,y1:word);
     procedure DrawIn(dev:pdevice;x,y,x1,y1:word);
    end;

type
    pbutt_fr=^tbutt_fr;
    tbutt_fr=object(tframe)
     left_up,right_down:ppen;
     frame:pframe;
     constructor init(aleftup,arightdown:ppen;around:pframe);
     destructor done; virtual;
     function Width:word;virtual;
     procedure draw_fr(dev:pdevice;x,y,x1,y1:word); virtual;
    end;

Type
     PGoodFrame=^TGoodFrame;
     TGoodFrame=object(TFrame)
      Pen:PPen;
      constructor init(APen:PPen);
      destructor done; virtual;
      function Width:Word; virtual;
      procedure draw_fr(dev:pdevice;x,y,x1,y1:word); virtual;
     end;
Type
     PPixFrame=^TPixFrame;
     TPixFrame=object(TFrame)
      Pen:PColorPen;
      Pix:PDevice;
      Len:Byte;

      constructor init(APix:PDevice);
      destructor done; virtual;
      function Width:Word; virtual;
      procedure draw_fr(dev:pdevice;x,y,x1,y1:word); virtual;
     end;

type
    pbutt2_fr=^tbutt2_fr;
    tbutt2_fr=object(tframe)
     left_up,right_down:ppen;
     frame:pframe;
     constructor init(aleftup,arightdown:ppen;around:pframe);
     destructor done; virtual;
     function Width:word;virtual;
     procedure draw_fr(dev:pdevice;x,y,x1,y1:word); virtual;
    end;

const
     cmax_fr_arr=10;
type
     parr_frame=^tarr_frame;
     tarr_frame=object(tframe)
      done_after:array[0..cmax_fr_arr-1] of boolean;
      pen:array[0..cmax_fr_arr-1] of ppen;
      pens:byte;
      constructor init;
      destructor done; virtual;
      procedure put(new_pen:ppen; destruct:boolean);
      function Width:word;virtual;
      procedure draw_fr(dev:pdevice;x,y,x1,y1:word); virtual;
     end;

 type
     pform=^tform;
     tform=object(tobject)
      ground_refresh:boolean;
      viewed:boolean;
      store:pointer;
      form_font:pfont;
      don_trest:boolean;

       constructor init(arefresh:boolean; afont:pfont);
       destructor done; virtual;
       procedure show(dev:pdevice; x,y,x1,y1:word);
       procedure move(tox,toy:word);
       procedure refresh;
       procedure unshow;
       function font:pfont;

       procedure drawform(dev:pdevice;x,y,x1,y1:word); virtual;
       function offsetx:word; virtual;
       function offsety:word; virtual;
     end;
type
     pstd_form=^tstd_form;
     tstd_form=object(tform)

      std_frame:pframe;
      ground_pen:ppen;

      constructor init(aframe:pframe; agpen:ppen; afont:pfont);
      destructor done; virtual;
      procedure drawform(dev:pdevice;x,y,x1,y1:word); virtual;
      function offsetx:word; virtual;
      function offsety:word; virtual;
     end;

  function good_fr:pframe;
  function pix1_fr:pframe;
  function pix2_fr:pframe;
  function rnd_fr:pframe;

  function std_ground:ppen;
  function press_fr:pframe;
  function butt_fr:pframe;
  function make_form(fr:pframe; grnd:ppen; font:pfont):pform;

type
     pgr_object=^tgr_object;
     tgr_object=object(tobject)
      Device:PDevice;
      Font:PFont;
      Form:PForm;
      OpenDelay:byte;

      Viewed:boolean;
      PosX,PosY,StartX,StartY,EndX,EndY:Word;

      function here(x,y:word):boolean;

      procedure focus(x,y:word);
      procedure unfocus;

      Constructor init( aform:pform;aopen:byte; adevice:pdevice );
      destructor done; virtual;

      procedure center;
      procedure show(x,y:word);
      procedure TryToshow(x,y:word);
      procedure show_act;
      procedure move(tox,toy:word);
      procedure hide;

      function width:word; virtual;
      function height:word; virtual;
      procedure repaint; virtual;
      procedure repaint_act; virtual;
     end;

type
    PProcessBar=^TProcessBar;
    TProcessBar=object(TGr_Object)
     MinVal,MaxVal,CurrVal:Longint;
     Text:string;
     Length,Top:word;
     PenFill:PPen;
     percentflag:boolean;

     constructor init(APenFill:PPen;AMin,AMax:Longint; ALen,AHGT:Word; AText:string);
     destructor done; virtual;
     function width:word; virtual;
     function height:word; virtual;
     procedure repaint; virtual;
     procedure nextval(val:longint);
     procedure reset;
    end;

Type PColorPicker = ^TColorPicker;
     TColorPicker = object(TGr_Object)
      CellWidth,CellHeight,
      CellsW,CellsH:Integer;
      DefNum:Byte;

      constructor Init(ACellW,ACellH,ACellsW,ACellsH:Integer);
      function Width:Word; virtual;
      function Height:Word; virtual;
      procedure repaint; virtual;
      function Choose:Byte;

      procedure UpDateStat(Num:Byte);
      function GetColor(x,y:integer):byte;
      function InColorCells(x,y:integer):boolean;
     end;

 Type PZoomEdit = ^TZoomEdit;
      TZoomEdit = object(tgr_object)
       Zoom     :byte;
       Dev      :PDevice;
       MustDone :Boolean;
       constructor Init(AZoom:Byte; ADev:PDevice; ADestructAfter:boolean);
       destructor Done; Virtual;
       function Width:word; virtual;
       function Height:word; virtual;
       procedure Repaint; virtual;
       procedure RedrawZoom;
       procedure ZoomClick(x,y:integer; Pen:PPen);
       function InZoom(x,y:integer):Boolean;
       function ZoomColor(x,y:integer):byte;
      end;

type
     PTextWindow=^TTextWindow;
     TTextWindow=object(TGr_Object)
      Text:PStringArr;
      Lines:Byte;
      Length:Word;
      function put(s:string):boolean;
      constructor Init(Text_Lines:byte; Wid:Word; AForm:PForm; ADevice:PDevice);
      destructor Done; virtual;
      function width:word; virtual;
      function height:word; virtual;
      procedure repaint; virtual;
     end;

const
     cbuttline=64;

type
    pbutton=^tbutton;
    tbutton=object(tgr_object)
     name:string[64];
     awidth:integer;
     constructor init(aname:string; wid:word);
     function width:word; virtual;
     function height:word; virtual;
     procedure repaint; virtual;
     procedure repaint_act; virtual;
    end;
type
    pbutton_line=^tbutton_line;
    tbutton_line=object(tgr_object)
     line:array[0..cbuttline-1] of pbutton;
     buttons:word;
     wid:word;
     visible:byte;
     currstart:byte;
     title:string[32];
     function pressed(x,y:word):integer;
     constructor init(vis,w:word; atitle:string);
     destructor done; virtual;
     procedure add_butt(s:string);
     function width:word; virtual;
     function height:word; virtual;
     procedure showpage(start,len,yplus:byte);
     procedure repaint; virtual;
    end;
type
    pedit_line=^tedit_line;
    tedit_line=object(tgr_object)
     title:string;
     length:word;
     constructor init(atitle:string;alen:word);
     function edit:string;
     function width:word; virtual;
     function height:word; virtual;
     procedure repaint; virtual;
    end;

var {simple_form,}
    button,
    button_pressed:pstd_form;
{    window:pstd_form;}

 procedure done_forms;
 procedure init_forms;

Type
     PSwitch = ^TSwitch;
     TSwitch = object(tgr_object)
      Title:NString;
      Value:Boolean;
      ValuePtr:Pointer;
      constructor init(ATitle:string; Default:Boolean; AValuePtr:Pointer);
      function width:word; virtual;
      function height:word; virtual;
      procedure repaint; virtual;
      procedure repaint_act; virtual;
      procedure setValue(NewValue:boolean);
     end;

const
     cSwitchBoardSize  = 64;
     cSwitchBoardExit  = 'Выйти из меню';
     cSwitchSpace      = 2;
     cSwitchSpaceW     = 4;

 type
     PSwitchBoard = ^TSwitchBoard;
     TSwitchBoard = object(TGr_Object)
      Switch:array[0..cSwitchBoardSize-1] of PSwitch;
      Switches:integer;
      Title:NString;
      ExitButton:PButton;
      TempWid,TempHgt:Integer;
      function MaxWid:integer;
      function MaxHgt:integer;

      constructor init(ATitle:NString);
      destructor done; virtual;
      function AddSwitch(SwValue:Boolean; SwTitle:NString; ValuePtr:Pointer):integer;
      function SwitchValue(I:Integer):Pointer;
      function width:word; virtual;
      function height:word; virtual;
      procedure repaint; virtual;
      procedure run;
      procedure repaint_act; virtual;
     end;

implementation
Uses kernel,misc,core,fx_pal,fx_init,fx_mouse,flgraph,play,sounds;
{$I locranges.pas}

      procedure init_switch;
      begin
       New(Switch_true,Load(Res^.LoadRes(cSW_TRUE)^));
       New(Switch_false,Load(Res^.LoadRes(cSW_FALSE)^));
      end;

      procedure done_switch;
      begin
       Dispose(Switch_true,Done);
       Dispose(Switch_false,Done);
      end;

procedure open_rect(x,y,x1,y1:word;d:byte; dev:pdevice);
var xpen:pinversepen;
    a:integer;
    b:real;
    xc,yc:word;
begin
(*
 b:=(y1-y+1)/(x1-x+1);
 xc:=((x1-x+1) div 2) + x;
 yc:=((y1-y+1) div 2) + y;
 new(xpen,init);
 for a:=0 to (x1-x+1) div 2-1 do
 begin
  dev^.rectangle(xc-a,round(yc-a*b),xc+a,round(yc+a*b),xpen);
  delay({(xc-x-a) div 20}d);
  dev^.rectangle(xc-a,round(yc-a*b),xc+a,round(yc+a*b),xpen);
 end;
 dispose(xpen,done);
*)
end;

     procedure tgr_object.center;
      var x,y:integer;
     begin
{      x:=integer(Device^.width)-integer(width);
      x:=abs(x div 2);
      y:=integer(Device^.height)-integer(height);
      y:=abs(y div 2);}
      x:=integer(loc_width)-integer(width);
      x:=abs(x div 2);
      y:=integer(loc_height)-integer(height);
      y:=abs(y div 2);
      show(x,y);
     end;

     procedure gfxstore(dev:pdevice; x,y,w,h:word; var p:pointer);
      var sdev:pdevice;
     begin
      getmem(p,storeheadsize);
      storetype(p^).device:=dev;
      storetype(p^).x:=x;
      storetype(p^).y:=y;
      storetype(p^).wid:=w;
      storetype(p^).hei:=h;
      new(sdev,init(w,h));
      dev^.partdevicecopy(0,0,x,y,w,h,sdev);
      storetype(p^).data:=sdev;
     end;
     procedure gfxfresh(var p:pointer);
     begin
      storetype(p^).data^.fulldevicecopy(
                                         storetype(p^).x,
                                         storetype(p^).y,
                                         storetype(p^).device
                                         );
     end;
     procedure gfxdone(var p:pointer);
     begin
      dispose(storetype(p^).data,done);
      freemem(p,storeheadsize);
      p:=nil;
     end;
     procedure gfxload(var p:pointer);
     begin
      storetype(p^).data^.fulldevicecopy(
                                         storetype(p^).x,
                                         storetype(p^).y,
                                         storetype(p^).device
                                         );
      dispose(storetype(p^).data,done);
      freemem(p,storeheadsize);
      p:=nil;
     end;

    function TFrame.Width;
    begin
     Width:=0;
    end;
    procedure tframe.draw_fr;
    begin
     abstract;
    end;
    procedure TFrame.DrawAround;
    begin
     draw_fr(dev,x-width,y-width,x1+width,y1+width);
    end;
    procedure TFrame.DrawIn;
    begin
     draw_fr(dev,x,y,x1,y1);
    end;

    destructor tbutt_fr.done;
    begin
     dispose(left_up,done);
     dispose(right_down,done);
     dispose(frame,done);
     tframe.done;
    end;
    constructor tbutt_fr.init;
    begin
     tframe.init;
     left_up:=aleftup;
     right_down:=arightdown;
     frame:=around;
    end;
    function tbutt_fr.width;
    begin
     width:=left_up^.width+frame^.width;
    end;
    procedure tbutt_fr.draw_fr;
     var w:word;
    begin
     w:=frame^.width;
     frame^.drawin(dev,x,y,x1,y1);
     inc(x,w); inc(y,w); dec(x1,w); dec(y1,w);
     dev^.hline(x,x1,y,left_up);
     dev^.vline(x,y,y1,left_up);
     dev^.hline(x+1,x1,y1,right_down);
     dev^.vline(x1,y+1,y1,right_down);
{     dev^.plot(x1,y,borderpen);
     dev^.plot(x,y1,borderpen);}
    end;

    destructor tbutt2_fr.done;
    begin
     dispose(left_up,done);
     dispose(right_down,done);
     dispose(frame,done);
     tframe.done;
    end;
    constructor tbutt2_fr.init;
    begin
     tframe.init;
     left_up:=aleftup;
     right_down:=arightdown;
     frame:=around;
    end;
    function tbutt2_fr.width;
    begin
     width:=left_up^.width*2+frame^.width;
    end;
    procedure tbutt2_fr.draw_fr;
     var w,w1:word;
    begin
     w:=frame^.width;
     frame^.drawin(dev,x,y,x1,y1);
     inc(x,w); inc(y,w); dec(x1,w); dec(y1,w);
     dev^.hline(x,x1,y,left_up);
     dev^.vline(x,y,y1,left_up);
     dev^.hline(x+1,x1,y1,right_down);
     dev^.vline(x1,y+1,y1,right_down);
     w:=left_up^.width;
     inc(x,w); inc(y,w); dec(x1,w); dec(y1,w);
     dev^.hline(x,x1,y,left_up);
     dev^.vline(x,y,y1,left_up);
     dev^.hline(x+1,x1,y1,right_down);
     dev^.vline(x1,y+1,y1,right_down);

     w:=left_up^.width;
     dec(x,w); dec(y,w); inc(x1,w); inc(y1,w);
{     dev^.plot(x,y1,borderpen);
     dev^.plot(x1,y,borderpen);
     dev^.plot(x+1,y1-1,borderpen);
     dev^.plot(x1-1,y+1,borderpen);}
    end;

     destructor tarr_frame.done;
      var a:integer;
     begin
      for a:=0 to pens-1 do
          if done_after[a] then dispose(pen[a],done);
      tframe.done;
     end;
     constructor tarr_frame.init;
     begin
      TObject.Init;
      pens:=0;
     end;
     procedure tarr_frame.put;
     begin
      if pens=cmax_fr_arr then exit;
      inc(pens);
      pen[pens-1]:=new_pen;
      done_after[pens-1]:=destruct;
     end;
     function tarr_frame.width;
      var a,b:integer;
     begin
      b:=0;
      for a:=0 to pens-1 do
       b:=b+pen[a]^.width;
      width:=b;
     end;
     procedure tarr_frame.draw_fr;
      var a,b:integer;
     begin
      b:=0;
      for a:=0 to pens-1 do
      begin
       dev^.rectangle(x+b,y+b,x1-b,y1-b,pen[a]);
       b:=b+pen[a]^.width;
      end;
     end;


     procedure tform.move;
      var w,h:word;
          dev:pdevice;
     begin
      if not viewed then exit;
      w:=storetype(store^).wid;
      h:=storetype(store^).hei;
      dev:=storetype(store^).device;
      unshow;
      show(dev,tox,toy,tox+w-1,toy+h-1);
     end;
     destructor tform.done;
     begin
      if viewed then unshow;
      Tobject.Done;
     end;
     function tform.offsetx;
     begin
      offsetx:=0;
     end;
     function tform.offsety;
     begin
      offsety:=0;
     end;
     constructor tform.init;
     begin
      tobject.init;
      ground_refresh:=arefresh;
      viewed:=no;
      store:=nil;
      form_font:=afont;
      don_trest:=off;
     end;
     function tform.font;
     begin
      font:=form_font;
     end;
     procedure tform.show;
     begin
      if not viewed then
      begin
       viewed:=true;
       gfxstore(dev,x,y,x1-x+1,y1-y+1,store);
       drawform(dev,x,y,x1,y1);
      end;
     end;
     procedure tform.refresh;
     begin
      if not viewed
      then exit
      else begin
       if ground_refresh then gfxfresh(store);
       drawform( storetype(store^).device,
                 storetype(store^).x,storetype(store^).y,
                 storetype(store^).x+storetype(store^).wid-1,storetype(store^).y+storetype(store^).hei-1 );
      end;
     end;
     procedure tform.unshow;
     begin
      if viewed
      then begin
       if don_trest then gfxdone(store) else gfxload(store);
       viewed:=no;
      end;
     end;
     procedure tform.drawform;
     begin
      abstract;
     end;

     destructor tstd_form.done;
     begin
      dispose(std_frame,done);
      dispose(ground_pen,done);
      tform.done;
     end;
     function tstd_form.offsetx;
     begin
      offsetx:=std_frame^.width;
     end;
     function tstd_form.offsety;
     begin
      offsety:=std_frame^.width;
     end;
     constructor tstd_form.init;
     begin
      tform.init( false, { don`t even refresh under }
                  afont );
      std_frame:=aframe;
      ground_pen:=agpen;
     end;
     procedure tstd_form.drawform;
      var w:word;
     begin
      w:=std_frame^.width;
      if cDOALL_FORM_BACK
      then dev^.map(x,y,x1,y1,ground_pen)
      else dev^.map(x+w,y+w,x1-w,y1-w,ground_pen);
      std_frame^.drawin(dev,x,y,x1,y1);
     end;

        procedure tgr_object.focus;
        begin
         Viewed:=true;
         PosX:=X; PosY:=Y;
         StartX:=x+form^.offsetx;
         StartY:=y+form^.offsety;
         EndX:=x +Width-1 -form^.offsetx;
         EndY:=y +Height-1 -form^.offsety;
        end;
        procedure tgr_object.unfocus;
        begin
         Viewed:=false;
         Posx:=0;
         PosY:=0;
         StartX:=0;
         StartY:=0;
         EndX:=0;
         EndY:=0;
        end;
     constructor tgr_object.init;
     begin
      TObject.Init;
      Device:=ADevice; Form:=AForm;
      Font:=Form^.Font;
      OpenDelay:=AOpen;
      unfocus;
     end;
     destructor tgr_object.done;
     begin
      if viewed then hide;
      Dispose(form,done);
      TObject.Done;
     end;
     procedure tgr_object.show;
     begin
      focus(x,y);
      open_rect(x,y,x+width,y+height,OpenDelay,device);
      form^.show(Device,x,y,x+Width-1,y+Height-1);
      repaint;
     end;
     procedure tgr_object.show_act;
     begin
      if not Viewed then exit;
      focus(Posx,Posy);
      form^.refresh;
      repaint_act;
     end;
     procedure tgr_object.move;
     begin
      if not Viewed then exit;
      Hide;
      Show(tox,toy);
     end;
     procedure tgr_object.hide;
     begin
      if not viewed then exit;
      form^.unshow;
      unfocus;
     end;
     function tgr_object.width;
     begin
      width:=form^.offsetx*2;
     end;
     function tgr_object.height;
     begin
      height:=form^.offsety*2;
     end;
     procedure tgr_object.repaint;
     begin
     end;
     procedure tgr_object.repaint_act;
     begin
     end;

     function TTextWindow.put;
     begin
      put:=false;
      if Text^.count=Lines
      then begin
       Text^.ATFree(0);
       if Viewed then Form^.refresh;
       put:=true;
      end;
      Text^.put(Font^.cutTOlen(Length,S));
     end;
     constructor TTextWindow.Init;
     begin
      TGr_Object.Init(AForm,2,ADevice);
      New(Text,Init);
      Lines:=Text_Lines;
      Length:=Wid;
     end;
     destructor TTExtWIndow.done;
     begin
      Dispose(Text,done);
      TGr_object.done;
     end;
     function TTextWindow.width;
     begin
      Width:=Length+TGr_object.width;
     end;
     function TTExtWindow.height;
     begin
      Height:=TGr_object.Height+(Font^.lnHeight+Font^.HeightSpace)*(Lines)+1;
     end;
     procedure TTextWIndow.repaint;
      var a,b:integer;
          y:word;
     begin
      TGr_object.repaint;
      if Text^.count<Lines
         then b:=Text^.count
         else b:=Lines;
      y:=StartY+1;
      for a:=0 to b-1 do
      begin
       font^.writeln(StartX+2,y,Device,Text^.get(a));
       y:=y+Font^.lnHeight+Font^.HeightSpace;
      end;
     end;


 procedure done_forms;
 begin
{  dispose(simple_form,done);}

  dispose(pix1,done);
  dispose(pix2,done);
  dispose(pix3,done);
  done_switch;
  dispose(button,done);
  dispose(button_pressed,done);
{  dispose(window,done);}
 end;

 procedure init_forms;
  var p:byte;
      fr:parr_frame;
      bframe:pbutt_fr;
      tpen:PTexturePen;
 begin
  new(button,init(butt_fr,std_ground,lightfont));
  new(button_pressed,init(press_fr,std_ground,lightfont));
  new(pix1,Load(Res^.LoadRes(cPIX1_NAME)^));
  new(pix2,Load(res^.loadRes(cPIX2_NAME)^));
  new(pix3,Load(res^.loadRes(cPIX3_NAME)^));
  init_switch;
{  p:=colors.paper;
  new(fr,init);
  fr^.put(new(pcolorpen,init(colors.border)),yes);
  new(simple_form,init(fr,new(pcolorpen,init(p)),lightfont));
  fr:=nil;

  new(fr,init);
  fr^.put(new(pcolorpen,init(butt_cfg.border)),yes);
  new(bframe,init(new(pcolorpen,init(butt_cfg.leftupper)),new(pcolorpen,init(butt_cfg.rightlower)),fr));
  fr:=nil;
  new(button,init(bframe,new(pcolorpen,init(p)),lightfont));
  bframe:=nil;

  new(fr,init);
  fr^.put(new(pcolorpen,init(butt_cfg.border)),yes);
  new(bframe,init(new(pcolorpen,init(butt_cfg.rightlower)),new(pcolorpen,init(p)),fr));
  fr:=nil;
  new(button_pressed,init(bframe,new(pcolorpen,init(p)),lightfont));
  bframe:=nil;

{  new(fr,init);
  fr^.put(new(pcolorpen,init(20)),yes);
  fr^.put(new(pcolorpen,init(60)),yes);
  fr^.put(new(pcolorpen,init(80)),yes);
  fr^.put(new(pcolorpen,init(40)),yes);
  fr^.put(new(pcolorpen,init(0)),yes);
  new(window,init(fr,new(pcolorpen,init(p)),lightfont));}
  add_exit_proc(@done_forms);
 end;

    constructor tbutton.init;
    begin
     tgr_object.init(make_form(new(parr_frame,init),std_ground,lightfont),2,screen);
     name:=aname;
     if wid=0 then awidth:=font^.lnwidth(name) else awidth:=wid;
    end;
    function tbutton.width;
    begin
     width:=tgr_object.width+awidth+8;
    end;
    function tbutton.height;
    begin
     height:=tgr_object.height+font^.lnHeight+6;
    end;
    procedure tbutton.repaint;
     var i:integer;
    begin
     tgr_object.repaint;
     button^.drawform(screen,startx,starty,endx,endy);

     i:=integer(awidth-font^.lnwidth(name)) div 2;
     font^.writelen(startx+4+i,starty+3,awidth+2,screen,name);
    end;
    procedure tbutton.repaint_act;
     var i:integer;
    begin
     tgr_object.repaint_act;
     button_pressed^.drawform(screen,startx,starty,endx,endy);
     i:=(awidth-font^.lnwidth(name)) div 2;
     font^.writelen(startx+5+i,starty+4,awidth+2,screen,name);
     while mousebuttons<>0 do;
{     delay(butt_cfg.delay);}
     repaint;
    end;
{
    destructor tbutton_line.done;
     var a:word;
    begin
     for a:=0 to buttons-1 do dispose(line[a],done);
     tgr_object.done;
    end;
    procedure tbutton_line.repaint;
     var cy,a:word;
    begin
     cy:=starty;
     for a:=0 to buttons-1 do
     begin
      line[a]^.show(startx,cy);
      cy:=cy+line[a]^.height-3;
     end;
    end;
    function tbutton_line.width;
    begin
     width:=tgr_object.width+wid+1;
    end;
    function tbutton_line.height;
    begin
     height:=tgr_object.height+buttons*(line[0]^.height-3)+3;
    end;
    constructor tbutton_line.init;
    begin
     tgr_object.init(simple_form,screen);
     buttons:=0;
     wid:=w;
    end;
    procedure tbutton_line.add_butt;
     var x,y:word;
    begin
     if buttons<cbuttline
     then begin
      new(line[buttons],init(s,wid-form^.offsetx-8));
      inc(buttons);
      if viewed
      then begin
       x:=posx; y:=posy;
       hide;
       show(x,y);
      end;
     end else errorMSG('can`t create more buttons');
    end;
    function tbutton_line.pressed;
     var p:integer;
    begin
     pressed:=-1;
     if not viewed then exit;
     if belongs(x,line[0]^.startx,line[0]^.endx) and
        belongs(y,line[0]^.starty,line[buttons-1]^.endy-2)
     then begin
      p:=(y-line[0]^.starty+1) div (line[0]^.height-3);
      hide_mouse;
      line[p]^.repaint_act;
      show_mouse;
      pressed:=p;
     end;
    end;}
    procedure tbutton_line.showpage;
     var cy,a:word;
    begin
     cy:=starty+yplus;
     for a:=start to start+len-1 do
     begin
      line[a]^.show(startx,cy);
      cy:=cy+line[a]^.height-1;
      if a=buttons-1 then break;
     end;
    end;
    destructor tbutton_line.done;
     var a:integer;
    begin
     if buttons>0 then for a:=0 to buttons-1 do dispose(line[a],done);
     tgr_object.done;
    end;
    procedure tbutton_line.repaint;
     var i:integer;
    begin
     Font^.writeln(startx+1,starty+1,device,'<');
     if CurrStart>0
     then Font^.Writeln(startx+2+font^.lnwidth('<'),starty+1,device,'<')
     else DarkFont^.Writeln(startx+2+font^.lnwidth('<'),starty+1,device,'<');

     Font^.writeln(endx-font^.lnwidth('>')+1,starty+1,device,'>');
     if integer(buttons)-integer(currstart+visible)>0
     then Font^.Writeln(endx-2*font^.lnwidth('>'),starty+1,device,'>')
     else DarkFont^.Writeln(endx-2*font^.lnwidth('>'),starty+1,device,'>');

     i:=abs(integer(width)-2-integer(font^.lnwidth(title))) div 2;
     Font^.writeln(startx+i,starty+1,device,title);
     showpage(currstart,visible,font^.lnheight+2);
    end;
    function tbutton_line.width;
    begin
     width:=tgr_object.width+wid-1;
    end;
    function tbutton_line.height;
    begin
     height:=tgr_object.height+(visible+1)*(line[0]^.height-1)-2;
    end;
    constructor tbutton_line.init;
     var fr:parr_frame;
    begin
     new(fr,init);
     fr^.put(new(pcolorpen,init(colors.border)),yes);
     tgr_object.init(make_form(fr,std_ground,lightfont),1,screen);
     buttons:=0;
     wid:=w;
     visible:=vis;
     currstart:=0;
     title:=atitle;
    end;
    procedure tbutton_line.add_butt;
     var x,y:word;
    begin
     if buttons<cbuttline
     then begin
      new(line[buttons],init(s,wid-form^.offsetx-8));
      inc(buttons);
      if viewed
      then begin
       x:=posx; y:=posy;
       hide;
       show(x,y);
      end;
     end else errorMSG('can`t create more buttons');
    end;
    function tbutton_line.pressed;
     var p:integer; v:word;
    begin
     pressed:=-1;
     if visible+currstart>buttons then v:=buttons else v:=visible;

     if not viewed then exit;
     if belongs(x,line[0]^.startx,line[0]^.endx) and
        belongs(y,line[0]^.starty,line[v-1]^.endy-2)
     then begin
      p:=(y-line[0]^.starty) div (line[0]^.height-1)+currstart;
      hide_mouse;
      line[p]^.repaint_act;
      show_mouse;
      pressed:=p;
     end;
     if belongs(x,startx,startx+font^.lnwidth('<<')) and
        belongs(y,starty,starty+font^.lnheight) and (currstart>0)
     then begin
      playSound(sndScroll);
      currstart:=currstart-visible;
      hide_mouse;
      form^.refresh;
      repaint;
      show_mouse;
     end;
     if belongs(x,endx-font^.lnwidth('<<'),endx) and
        belongs(y,starty,starty+font^.lnheight) and (integer(buttons)-(integer(currstart)+integer(visible))>0)
     then begin
      PlaySound(sndScroll);
      currstart:=currstart+visible;
      hide_mouse;
      form^.refresh;
      repaint;
      show_mouse;
     end;
    end;

 function tgr_object.here;
 begin
  here:=belongs(x,startx,endx) and belongs(y,starty,endy);
 end;

  function std_ground:ppen;
  begin
   std_ground:=new(pcolorpen,init(colors.paper));
  end;
  function butt_fr:pframe;
   var fr:parr_frame;
  begin
   new(fr,init);
   fr^.put(new(pcolorpen,init(0)),yes);

   butt_fr:=new(pbutt_fr,init(
                               new(pcolorpen,init(butt_cfg.leftupper)),
                               new(pcolorpen,init(butt_cfg.rightlower)),
                               fr
                              )
               );
  end;
  function press_fr:pframe;
   var fr:parr_frame;
  begin
   new(fr,init);
   fr^.put(new(pcolorpen,init(0)),yes);

   press_fr:=new(pbutt_fr,init(
                               new(pcolorpen,init(butt_cfg.rightlower)),
                               new(pcolorpen,init(colors.paper)),
                               fr
                              )
               );
  end;

  function make_form(fr:pframe; grnd:ppen; font:pfont):pform;
   var p:pstd_form;
  begin
   new(p,init(fr,grnd,font));
   make_form:=p;
  end;
    procedure tedit_line.repaint;
    begin
     inherited repaint;
     font^.writeln(startx+1,starty+1,device,title);
    end;
    function tedit_line.width;
    begin
     width:=length+inherited width;
    end;
    function tedit_line.height;
    begin
     height:=font^.lnheight+inherited height +2 ;
    end;
    constructor tedit_line.init;
     var fr:parr_frame;
    begin
     new(fr,init);
     fr^.put(new(pcolorpen,init(colors.border)),yes);
     fr^.put(new(pcolorpen,init(0)),yes);
     inherited init(make_form(fr,std_ground,lightfont),1,screen);
     title:=atitle; length:=alen;
    end;
    function tedit_line.edit;
     var s:string;
         ch:char;
    begin
     hide_mouse;
     center;
     show_mouse;
     s:=''; ch:=' ';
     while true do begin
      ch:=readkey;
      case ch of
       #27: begin
             edit:='';
             hide_mouse; hide; show_mouse;
             exit;
            end;
       #13: begin
             edit:=s;
             hide_mouse; hide; show_mouse;
             exit;
            end;
       else if font^.lnwidth(s+ch)<(width-font^.lnwidth(title)-10) then
        begin
         s:=s+ch;
         hide_mouse;
         font^.writeln(startx+1+font^.lnWidth(title),starty+1,device,s);
         show_mouse;
        end;
      end;
     end;
    end;
    procedure tprocessbar.reset;
    begin
     CurrVal:=MinVal;
     if not viewed then exit;
     form^.refresh;
     repaint;
    end;
    destructor tprocessbar.done;
    begin
     dispose(penfill,done);
     inherited done;
    end;
    constructor tprocessbar.init;
     var fr:parr_frame;
    begin
     fr:=new(parr_frame,init);
     fr^.put(new(pcolorpen,init(0)),yes);
     fr^.put(new(pcolorpen,init(20)),yes);
     fr^.put(new(pcolorpen,init(60)),yes);
     inherited init(make_form(fr,std_ground,lightfont),2,screen);
     MinVal:=AMin; MaxVal:=AMax; CurrVal:=MinVal;
     Length:=ALen;
     Text:=AText;
     Top:=AHGT;
     PenFill:=APenFill;
     if text='' then percentflag:=true else percentflag:=false;
    end;
    function tprocessbar.width;
    begin
     width:=inherited width + Length;
    end;
    function tprocessbar.height;
    begin
     height:=inherited height + Top ;
    end;
    procedure tprocessbar.repaint;
     var percent:real;
         pixels,offs,ceny:integer;
    begin
     inherited repaint;
     wvend;
     if percentflag then form^.refresh;
     percent:=abs( (CurrVal-MinVal) / (MaxVal-MinVal) );
     pixels:=round(percent*Length)-1;
     device^.map(startx,starty,startx+pixels,starty+Top-1,penfill);
     if percentflag then begin
                      str(round(100*percent),text);
                      text:=text+'%';
                     end;
     offs:=(length-font^.lnWidth(text)) div 2;
     ceny:=(top-font^.lnHeight) div 2;
     if ceny<0 then ceny:=0;
     if offs<0
     then Font^.writelen(StartX,StartY+ceny,Length,Device,Text)
     else Font^.writeln(StartX+offs,StartY+ceny,Device,Text);
    end;
    procedure tprocessbar.nextval(val:longint);
    begin
     if (currval<>val) and belongs(val,minval,maxval) then
     begin
      currval:=val;
      if viewed then repaint;
     end;
    end;
     constructor TGoodFrame.init;
     begin
      Inherited Init;
      Pen:=APen;
     end;
     destructor TGoodFrame.done;
     begin
      Dispose(Pen,Done);
      inherited Done;
     end;
     function TGoodFrame.Width;
     begin
      Width:=cEXT_RECT;
     end;
     procedure TGoodFrame.draw_fr;
     begin
      if ((x1-x)<(cEXT_RECT*2)) or ((y1-y)<(cEXT_RECT*2))
      then exit;
      Dev^.Rectangle(x,y,x1,y1,Pen);
      Dev^.Rectangle(x,y,x+cEXT_RECT,y+cEXT_RECT,Pen);
      Dev^.Rectangle(x1-cEXT_RECT,y,x1,y+cEXT_RECT,Pen);
      Dev^.Rectangle(x,y1-cEXT_RECT,x+cEXT_RECT,y1,Pen);
      Dev^.Rectangle(x1-cEXT_RECT,y1-cEXT_RECT,x1,y1,Pen);

      Dev^.HLine(x+cEXT_RECT,x1-cEXT_RECT,y+cHLF_RECT,Pen);
      Dev^.HLine(x+cEXT_RECT,x1-cEXT_RECT,y1-cHLF_RECT,Pen);

      Dev^.VLine(x+cHLF_RECT,y+cEXT_RECT,y1-cEXT_RECT,Pen);
      Dev^.VLine(x1-cHLF_RECT,y+cEXT_RECT,y1-cEXT_RECT,Pen);
     end;
     constructor TpixFrame.init;
     begin
      Inherited Init;
      Pen:=New(PColorPen,Init(0));
      Pix:=APix;
      Len:=Pix^.Width;
     end;
     destructor TpixFrame.done;
     begin
      Dispose(Pen,Done);
      inherited Done;
     end;
     function TpixFrame.Width;
     begin
      Width:=Len;
     end;
     procedure TpixFrame.draw_fr;
      var hlf:byte;
     begin
      Pix^.FullDeviceCopy(x,y,Dev);
      Pix^.FullDeviceCopy(x,y1-Len+1,Dev);
      Pix^.FullDeviceCopy(x1-Len+1,y,Dev);
      Pix^.FullDeviceCopy(x1-Len+1,y1-Len+1,Dev);
      hlf:=Len div 2;
      Pen^.SetColor(cLine1Pen);
      Dev^.HLine(x+Len,x1-Len,y+hlf,Pen);
      Dev^.HLine(x+Len,x1-Len,y1-hlf,Pen);
      Dev^.VLine(x+hlf,y+Len,y1-Len,Pen);
      Dev^.VLine(x1-hlf,y+Len,y1-Len,Pen);

      Pen^.SetColor(cLine2Pen);
      Dev^.HLine(x+Len,x1-Len,y+hlf-1,Pen);
      Dev^.HLine(x+Len,x1-Len,y1-hlf+1,Pen);
      Dev^.VLine(x+hlf-1,y+Len,y1-Len,Pen);
      Dev^.VLine(x1-hlf+1,y+Len,y1-Len,Pen);
     end;
  function good_fr:pframe;
  begin
   Good_fr:=New(PGoodFrame,Init(New(PColorPen,Init(cGOODCOLOR))));
  end;
  function pix1_fr:pframe;
  begin
   pix1_fr:=New(PPixFrame,Init(Pix1));
  end;

  function pix2_fr:pframe;
  begin
   pix2_fr:=New(PPixFrame,Init(Pix2));
  end;

  function pix3_fr:pframe;
  begin
   pix3_fr:=New(PPixFrame,Init(Pix3));
  end;

  function rnd_fr:pframe;
  begin
   case Random(4) of
    0: rnd_fr:=good_fr;
    1: rnd_fr:=pix1_fr;
    2: rnd_fr:=pix2_fr;
    3: rnd_fr:=pix3_fr;
   end;
  end;

      Procedure Show_Switch(x,y:integer; Device:PDevice; Status:Boolean);
      begin
       If Status
       then Switch_true^.FullDeviceCopy(x,y,Device)
       else Switch_false^.FullDeviceCopy(x,y,Device)
      end;
      function Switch(Status:boolean):PDevice;
      begin
       if Status
       then Switch:=Switch_true
       else Switch:=Switch_false;
      end;

     constructor TSwitch.init;
      var Frame:PArr_frame;
     begin
      New(Frame,Init);
      Frame^.Put(New(PHidePen,init),True);
      inherited init(make_form(Frame,New(PHidePen,Init),LightFont),0,Screen);
      Title:=ATitle; Value:=Default; ValuePtr:=AValuePtr;
      if ValuePtr<>nil then Boolean(ValuePtr^):=Value;
     end;
     function TSwitch.Width;
     begin
      Width:= inherited width +
              Switch(Value)^.Width + 2 +
              Font^.LnWidth(Title);
     end;
     function TSwitch.Height;
     begin
      Height:=inherited height + Switch(Value)^.Height;
     end;
     procedure TSwitch.repaint;
     begin
       Show_Switch(StartX,StartY,Device,Value);
       Font^.Writeln(StartX+Switch(Value)^.Width+2,StartY+2,Device,Title);
     end;
     procedure TSwitch.repaint_act;
     begin
      Value:=not Value;
      if ValuePtr<>nil then Boolean(ValuePtr^):=Value;
      repaint;
     end;
     procedure TSwitch.SetValue(NewValue:boolean);
     begin
      Value:=NewValue;
      if ValuePtr<>nil then Boolean(ValuePtr^):=Value;
      if Viewed then Repaint;
     end;

     procedure TSwitchBoard.run;
      var mx,my,i:integer;
     begin
      if Viewed then hide; Center;
      While true do begin
       mx:=MousePOsX; my:=MousePosY;
       if MouseButtons<>0
       then begin
        for i:=0 to Switches-1 do
            if Switch[i]^.here(mx,my)
            then begin
             Hide_mouse;
             Switch[i]^.repaint_act;
             show_mouse;
             while MouseButtons<>0 do ;
            end;
        if ExitButton^.here(mx,my) then begin
         Hide_mouse;
         ExitButton^.repaint_act;
         while MouseButtons<>0 do ;
         For i:=0 to Switches-1 do Switch[i]^.Hide;
         ExitButton^.Hide;
         Hide;
         Show_mouse;
         Exit;
        end;
       end;
      end;
     end;
     procedure TSwitchBoard.repaint;
      var tx,ty,x,y,i:integer;
     begin
      x:=cSwitchSpaceW + StartX;
      y:=cSwitchSpace + StartY;
      tx:=x + (MaxWid-Font^.lnWidth(Title)) div 2;
      ty:=y;
      Font^.Writeln(tx,ty,Device,Title);
      y:=y+ cSwitchSpace + Font^.lnHeight;
      for i:=0 to Switches-1 do begin
       Switch[i]^.Show(x,y);
       y:=y+Switch[i]^.Height + cSwitchSpace div 2;
      end;
      tx:=x+(MaxWid-ExitButton^.Width) div 2;
      ty:=y;
      ExitButton^.Show(tx,ty);
     end;
     procedure TSwitchBoard.repaint_act;
     begin
     end;
     function TSwitchBoard.MaxWid;
      var tw,mw,i:integer;
     begin
      mw:=0;
      for i:=0 to Switches-1 do begin
       tw:=Switch[i]^.Width;
       if tw>mw then mw:=tw;
      end;
      MaxWid:=mw+cSwitchSpaceW;
     end;
     function TSwitchBoard.MaxHgt;
      var sm,i:integer;
     begin
      sm:=cSwitchSpace;
      for i:=0 to Switches-1 do sm:=Switch[i]^.Height + cSwitchSpace*6;
      MaxHgt:=sm;
     end;
     function TSwitchBoard.Width;
     begin
      Width:= Inherited Width + TempWid;
     end;
     function TSwitchBoard.Height;
     begin
      Height:= Inherited Height + (Switch[0]^.Height+cSwitchSpace)*Switches +
               Font^.LnHeight + cSwitchSpace + ExitButton^.Height ;
     end;
     function TSwitchBoard.AddSwitch;
     begin
      New(Switch[Switches],Init(SwTitle,SwValue,ValuePtr));
      AddSwitch:=Switches;
      Inc(Switches);
      TempWid:=MaxWid; TempHgt:=MaxHgt;
     end;
     function TSwitchBoard.SwitchValue;
     begin
      SwitchValue:=Switch[i]^.ValuePtr;
     end;
     constructor TSwitchBoard.Init;
     begin
      inherited Init( Make_Form(Good_fr,New(PConvertPen,Init(Palette^.GlassIndex)),LightFont),
                      0, Screen );
      Title:=ATitle;
      ExitButton:=New(PButton,Init( cSwitchBoardExit,
                                    Font^.lnWidth(cSwitchBoardExit) ));
      Switches:=0; TempWid:=0; TempHgt:=0;
     end;
     destructor TSwitchBoard.Done;
      var i:integer;
     begin
      for i:=0 to Switches-1 do Dispose(Switch[i],Done);
      Dispose(ExitButton,Done);
      inherited Done;
     end;

     constructor TColorPicker.Init;
     begin
      inherited init( make_form(Pix1_fr,Std_ground,LightFont),
                      0, Screen );
      CellWidth:=ACellW;
      CellHeight:=ACellH;
      CellsW:=ACellsW;
      CellsH:=ACellsH;
     end;
     function TColorPicker.Width;
     begin
      Width:=Inherited Width + CellWidth*CellsW;
     end;
     function TColorPicker.Height;
     begin
      Height:=Inherited Height + 1 + CellHeight*CellsH + Font^.LnHeight;
     end;
     procedure TColorPicker.Repaint;
      var a,b,c,x,y:integer;
          col:byte;
          p:PColorPen;
     begin
      New(P,Init(0));
      for b:=0 to CellsH-1 do
          for a:=0 to CellsW-1 do begin
           c:=b*CellsW+a; col:=lo(c);
           P^.SetColor(col);
           x:=StartX + a*CellWidth; y:=StartY + b*CellHeight;
           Device^.Map(x,y,x+CellWidth-1,y+CellHeight-1,p);
          end;
      Dispose(P,Done);
     end;
     function TColorPicker.InColorCells(x,y:integer):boolean;
     begin
      InColorCells:= Belongs(x,StartX,StartX+CellWidth*CellsW-1) and
                     Belongs(y,StartY,StartY+CellHeight*CellsH-1);
     end;
     function TColorPicker.GetColor(x,y:integer):byte;
      var col:integer;
     begin
      x:=x-StartX;
      y:=y-StartY;
      x:=x div CellWidth;
      y:=y div CellHeight;
      Col:=y*CellsW+x; GetColor:=lo(Col);
     end;
     procedure TColorPicker.UpDateStat(Num:Byte);
      var p:PColorPen;
     begin
      if DefNum=Num then Exit;
      New(P,Init(Data.Colors.Paper));
      Device^.Map( StartX,StartY+CellsH*CellHeight+1,
                   StartX+Width-Form^.OffsetX*2-2,StartY+CellsH*CellHeight+1+Font^.lnHeight,P);
      Font^.WriteCen(PosX,StartY+CellsH*CellHeight+1,Width,Device,TOStr(Num));
      Dispose(P,Done);
      DefNum:=Num;
     end;
     function TColorPicker.Choose;
      var x,y:integer;
     begin
      Choose:=0;
      if not Viewed then Exit;
      While True do begin
       x:=MousePOSX; y:=MousePosY;
       if InColorCells(x,y) then UpDateStat(GetColor(x,y));
       if MouseButtons<>0 then begin
        ClearInput;
        if InColorCells(x,y)
        then begin
         Choose:=GetColor(x,y);
         Exit;
        end;
       end;
      end;
     end;

      destructor TZoomEdit.Done;
      begin
       if MustDone then Dispose(Dev,Done);
       inherited Done;
      end;
      constructor TZoomEdit.Init;
      begin
       inherited init(make_form(Butt_fr,Std_ground,LightFont),0,Screen);
       Zoom    :=AZoom;
       Dev     :=ADev;
       MustDone:=ADestructAfter;
      end;
      function TZoomEdit.Width;
      begin
       Width:=Inherited Width + Dev^.Width*Zoom + 8 + Dev^.Width;
      end;
      function TZoomEdit.Height;
      begin
       Height:=Inherited Height + Dev^.Height*Zoom + 5;
      end;
      procedure TZoomEdit.RedrawZoom;
       var a,b:integer;
           col:pcolorpen;
           w,h:word;
           x,y:integer;
      begin
       col:=New(PColorPen,Init(0));
       x:=StartX; y:=StartY;
       w:=Dev^.Width*Zoom+2;
       h:=Dev^.Height*Zoom+2;
       col^.SetColor(cZoomRectCol);
       Device^.Rectangle(x,y,x+w-1,y+h-1,Col);
       inc(x); inc(y); dec(w,2); dec(h,2);
       for b:=0 to Dev^.Height-1 do
        for a:=0 to Dev^.Width-1 do
        begin
         Col^.SetColor(Dev^.GetPlot(a,b));
         Device^.Map(x+a*Zoom,y+b*Zoom,x+(a+1)*Zoom-1,y+(b+1)*Zoom-1,Col);
        end;
       Dispose(Col,done);
      end;
      function TZoomEdit.InZoom(x,y:integer):Boolean;
      begin
       InZoom:= Belongs(X,StartX+1,StartX+Dev^.Width*Zoom) and
                Belongs(Y,StartY+1,StartY+Dev^.Height*Zoom);
      end;
      function TZoomEdit.ZoomColor(x,y:integer):byte;
      begin
       x:=x-(StartX+1); y:=y-(StartY+1);
       x:=x div Zoom; y:=y div Zoom;
       ZoomColor:=Dev^.GetPlot(x,y);
      end;
      procedure TZoomEdit.ZoomClick(x,y:integer; Pen:PPen);
       var Col:PColorPen;
      begin
       if Belongs(X,StartX+1,StartX+Dev^.Width*Zoom) and
          Belongs(Y,StartY+1,StartY+Dev^.Height*Zoom) then
       begin
        x:=x-(StartX+1); y:=y-(StartY+1);
        x:=x div Zoom; y:=y div Zoom;
        Dev^.Plot(x,y,Pen);
        New(Col,Init(Dev^.GetPlot(x,y)));
        Device^.Map( StartX+1+X*Zoom,StartY+1+Y*Zoom,
                     StartX+(X+1)*Zoom,StartY+(Y+1)*Zoom,Col );
        Dev^.FullDeviceCopy( StartX+5+Dev^.Width*Zoom,StartY+2,Device);
        Dispose(Col,Done);
       end;
      end;
      procedure TZoomEdit.Repaint;
       var col:PColorPen;
      begin
       RedrawZoom;
       New(Col,init(cZoomRectCol));
       Device^.Rectangle( StartX+4+Dev^.Width*Zoom,StartY+1,
                          StartX+5+Dev^.Width*(Zoom+1),StartY+2+Dev^.Height,Col );
       Dev^.FullDeviceCopy( StartX+5+Dev^.Width*Zoom,StartY+2,Device);
       Dispose(Col);
      end;

     function PickColor(x,y:integer):byte;
      var P:PColorPicker;
     begin
      New(P,Init(cColorCell_W,cColorCell_H,cColorCells_W,cColorCells_H));
      Hide_mouse;
      P^.TryToShow(x,y);
      Show_mouse;
      PickColor:=P^.Choose;
      Hide_mouse;
      Dispose(P,Done);
      Show_mouse;

     end;

     procedure TGr_object.TryToShow;
     begin
      if X<10 then X:=10; if Y<10 then Y:=10;
      if X+Width+10>=Device^.Width then X:=Device^.Width-Width-10;
      if Y+Height+10>=Device^.Height then Y:=Device^.Height-Height-10;
      Show(x,y);
     end;
end.
