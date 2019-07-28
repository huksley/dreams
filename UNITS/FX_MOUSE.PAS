{┌─────────────────┐}
{│} Unit FX_mouse;{│}
{└─────────────────┘}

{.$DEFINE WAITWV}

interface

 uses fx_dev,fx_shape,fx_types;

Const cMAX_CURSORS      = 32;
      cNoButton         = 00;
      cLeftbutton       = 01;
      cRightbutton      = 02;
      cBothButtons      = 03;

      MousePosX     :Word = 160;
      MousePosY     :Word = 100;
      MouseButtons  :Byte = 0;

     procedure clearinput;

     procedure stick_mouse;
     procedure unstick_mouse;
     procedure freeze_hands;
     procedure unfreeze_hands;

     function mouse_in(x,y,w,h:word):boolean;
     procedure click_it(x,y,w,h:integer; p:ppen; delay:word; screen:pdevice);

     procedure InitMouseHandler(CurrMouse:PCursor);
     procedure DoneMouseHandler;
     procedure Put_handler(Cur:PCursor; x,y,x1,y1:integer);
     function removehand(x,y,x1,y1:integer):boolean;
     procedure Remove_All;
     procedure Show_Mouse;
     procedure Hide_Mouse;

implementation

{$R-,Q-,S-,F+}

uses plmove,misc,
     core,kernel,
     objects,int33,plvgalib,play,sounds;

type cursorrec = record
      image:pointer;
      width,height:word;
      SnapX,SnapY:byte;
      Rect:TRect;
     end;

const DeviceWidth   :Word = 320;
      DeviceHeight  :Word = 200;
var   DevicePtr     :Pointer;
      Cursor        :array[0..cMAX_CURSORS-1] of Cursorrec;
      DefaultCur    :CursorRec;
      Cursors       :integer;
      Viewed        :boolean;
      Sticked       :boolean;
      Freezed       :Integer;

Var   RedrawMouseX,RedrawMouseY :Integer;
      RedrawMouseW,RedrawMouseH :Word;
      RedrawMouseNum            :Integer;
      RedrawBackground          :Pointer;
      RedrawBackSize            :Word;

function DetermineCursor:integer;
 var a:integer;
     p:Tpoint;
begin
 DetermineCursor:=-1;
 P.x:=MousePOSX;
 p.y:=MousePOSY;
 for a:=0 to Cursors-1 do
     with Cursor[a] do if Rect.contains(P)
                       then begin
                        DetermineCursor:=a;
                        Exit;
                       end;
end;

procedure ShowMouseCursor(I:Integer);
begin
 if i=-1
 then With DefaultCur do begin
  RedrawMouseX:=MousePosX-SnapX;
  RedrawMouseY:=MousePosY-SnapY;
  RedrawMouseW:=Width;
  RedrawMouseH:=Height;
  RedrawBackSize:=Width*Height;
  GetMem(RedrawBackground,RedrawBackSize);
  get_clip( RedrawMouseX,RedrawMouseY,
            RedrawMouseW,RedrawMouseH,
            DeviceWidth,DeviceHeight,
            RedrawBackGround^,DevicePtr^ );
  RedrawMouseNum:=i;

  Show_Clip( MousePOSX-SnapX,MousePOSY-SnapY,
             Width,Height,
             DeviceWidth,DeviceHeight,
             Image^,DevicePtr^ );
 end else With Cursor[i] do begin
  RedrawMouseX:=MousePosX-SnapX;
  RedrawMouseY:=MousePosY-SnapY;
  RedrawMouseW:=Width;
  RedrawMouseH:=Height;
  RedrawBackSize:=Width*Height;
  GetMem(RedrawBackground,RedrawBackSize);
  get_clip( RedrawMouseX,RedrawMouseY,
            RedrawMouseW,RedrawMouseH,
            DeviceWidth,DeviceHeight,
            RedrawBackGround^,DevicePtr^ );
  RedrawMouseNum:=i;
  Show_Clip( MousePOSX-SnapX,MousePOSY-SnapY,
             Width,Height,
             DeviceWidth,DeviceHeight,
             Image^,DevicePtr^ );
 end;
end;

procedure PutBackGround;
begin
 if RedrawBackGround=Nil then Exit;
 Full_Clip( RedrawMouseX,RedrawMouseY,
            RedrawMouseW,RedrawMouseH,
            DeviceWidth,DeviceHeight,
            RedrawBackGround^,DevicePtr^);
 Freemem(RedrawBackGround,RedrawBackSize);
 RedrawBackGround:=Nil;
end;

procedure Show_mouse;
begin
 If Viewed then Exit;
 Viewed:=True;
 asm
  cli
 end;
 ShowMouseCursor(DetermineCursor);
 asm
  sti
 end;
end;
procedure Hide_mouse;
begin
 if Not Viewed then Exit;
 PutBackGround;
 Viewed:=False;
end;

procedure RedrawMouse;
begin
 If Not Viewed then Exit;
 If Sticked then Exit;
 PutBackGround;
 ShowMouseCursor(DetermineCursor);
end;

procedure int33_handler;
assembler; asm
 mov AX,seg MousePOSX
 mov DS,AX

 shr cx,1
 mov MousePOSX   ,CX
 mov MousePOSY   ,DX
 mov MouseButtons,BL

 mov dx,$03DA
 @WaitRet:
          in al,dx
          test al,$08
          jz @Waitret

 call RedrawMouse
 retf
end;

 procedure install_mouse_handler;
 assembler;
  asm
  mov ax,000cH
  mov cx,7fH
  push es
  mov dx,seg int33_handler
  mov es,dx
  mov dx,offset int33_handler
  mov bx,dx
  int 33h
  pop es
 end;

 procedure deinstall_mouse_handler;
 assembler; asm
  mov ax,000ch
  mov cx,0
  int 33h
 end;

procedure InitCurRec(CurrMouse:PCursor; Var DefaultCur:CursorRec);
begin
 Defaultcur.width   :=CurrMouse^.Data^.Width;
 Defaultcur.height  :=CurrMouse^.Data^.Height;
 GetMem(DefaultCur.Image,DefaultCur.Width*DefaultCur.Height);
 Move(CurrMouse^.Data^.ShapeData^,DefaultCur.Image^,DefaultCur.Width*DefaultCur.Height);
 Defaultcur.SnapX   :=CurrMouse^.SnapX;
 Defaultcur.SnapY   :=CurrMouse^.SnapY;
end;
procedure DoneCurRec(Var Cur:CursorRec);
begin
 Freemem(Cur.Image,Cur.Width*Cur.Height);
end;

procedure DoneMouseHandler;
 var a:integer;
begin
 Hide_mouse;
 DoneCurRec(DefaultCur);
 for a:=0 to Cursors-1 do DoneCurRec(Cursor[a]);
 Cursors:=0;
 deinstall_mouse_handler;
end;

Procedure InitMouseHandler(CurrMouse:PCursor);
begin
 InitCurRec(CurrMouse,DefaultCur);
 Dispose(CurrMouse,done);
 DevicePtr          :=Ptr(SegA000,0);
 reset_mouse_driver(639,199);
 Cursors:=0;
 install_mouse_handler;
end;


Procedure Put_Handler(Cur:PCursor; x,y,x1,y1:Integer);
begin
 if Cursors=cMAX_CURSORS
 then ErrorMSG('Can`t add more cursors')
 else begin
  initCurRec(Cur,Cursor[Cursors]);
  Cursor[Cursors].Rect.Assign(x,y,x1,y1);
  Inc(Cursors);
  if Freezed<>-1 then Inc(Freezed);
  if Viewed then RedrawMouse;
 end;
end;

     procedure deletehand(n:integer);
      var a:integer;
     begin
      hide_mouse; DoneCurRec(Cursor[n]);
       for a:=n+1 to Cursors-1 do Cursor[a-1]:=Cursor[a];
       dec(Cursors);
       if Freezed<>-1 then Dec(Freezed);
      show_mouse;
     end;

     function removehand(x,y,x1,y1:integer):boolean;
      var a:integer;
          r:trect;
     begin
      removehand:=false;
      r.assign(x,y,x1,y1);
      for a:=0 to Cursors-1 do
       if Cursor[a].rect.equals(r)
       then begin
        removehand:=true;
        deletehand(a);
        exit;
       end;
     end;

function mouse_in(x,y,w,h:word):boolean;
begin
 mouse_in:= belongs(mouseposx,x,x+w-1) and
            belongs(mouseposy,y,y+h-1) ;
end;

     procedure Remove_All;
      var a,r:integer;
     begin
      Hide_Mouse;
      if Freezed=-1 then r:=Cursors else r:=Freezed;
      for a:=0 to R-1 do DoneCurRec(Cursor[a]);
      Cursors:=0;
      if Freezed<>-1 then Freezed:=0;
      Show_Mouse;
     end;

procedure clearinput;
begin
 while mousebuttons<>0 do;
 clearKBD;
end;

procedure stick_mouse;
begin
 Sticked:=true;
end;
procedure unstick_mouse;
begin
 Sticked:=false;
end;
procedure freeze_hands;
begin
 if Freezed<>-1 then exit;
 freezed:=Cursors;
 hide_mouse;
 Cursors:=0;
 show_mouse;
end;
procedure unfreeze_hands;
begin
 if Freezed=-1 then exit;
 hide_mouse;
  Cursors:=freezed;
 show_mouse;
  Freezed:=-1;
end;
procedure click_it(x,y,w,h:integer; p:ppen; delay:word; screen:pdevice);
 var tempdev,safedev:pdevice;
     mousex,mousey,offsx,offsy,snx,sny:integer;
     i:integer;
begin
{ if not mouse_in(x,y,w,h) then exit else}
 begin
  PlaySound(sndClick);
  stick_mouse; i:=DetermineCursor;
  mousex:=mouseposx; mousey:=mouseposy;
  offsx:=mousex-x; offsy:=mousey-y;
  tempdev:=new(pdevice,init(w,h));
  safedev:=new(pdevice,init(w,h));
  screen^.partdevicecopy(0,0,x,y,w,h,tempdev);
  screen^.partdevicecopy(0,0,x,y,w,h,safedev);

  tempdev^.clear(p);

  if i<>-1 then with Cursor[i] do begin
   show_clip( offsx-SnapX,offsy-SnapY,Width,Height,
              TempDev^.Width,TempDev^.Height,Image^,TempDev^.Start^);
  end else with DefaultCur do begin
   show_clip( offsx-SnapX,offsy-SnapY,Width,Height,
              TempDev^.Width,TempDev^.Height,Image^,TempDev^.Start^)
  end;

  WVstart;
  tempdev^.fulldevicecopy(x,y,screen);
  dispose(tempdev,done);
  dec(delay,2);
  misc.delay(delay);
  safedev^.fulldevicecopy(x,y,screen);
  dispose(safedev,done);
  unstick_mouse;
 end;
end;

begin
 Freezed:=-1;
end.