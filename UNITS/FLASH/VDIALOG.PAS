Unit VDialog;

interface

 uses tpstr,types;

{$I locranges}

const
     cDiaStart = 'DiaStart';
     cDiaEnd   = 'DiaEnd';
     cNoMoreDialogs = 'AllDialogs';

     cMaxChoices = 32;
     cMaxDialogs = 32;
     cChoiceWait = 100;
     cNoImage    = '';

type
     diachoice = record
      x,y,w,h:integer;
      doglass:boolean;
      result:tstring;
      run:tstring;
     end;

     pdiarec = ^diarec;
     diarec = record
      name:tstring;
      image:tstring;
      choice:array[0..cMaxChoices-1] of diachoice;
      choices:integer;
     end;

     dialist = array[0..cMaxDialogs-1] of pdiarec;

    procedure init_dialogs(var f:text);
    procedure dodialog(name:string);
    procedure donedialogs;

implementation

uses flaction,flgraph,flobjects,flashcom,
     misc,fx_pens,kernel,paths,core,
     fx_init,fx_mouse,fx_dev,
     fx_types,fx_form;

procedure unpack2chc(pack:string; var chc:diachoice);
begin
 with chc do begin
  x:=toint(get_var('x',pack));
  y:=toint(get_var('y',pack));
  w:=toint(get_var('w',pack));
  h:=toint(get_var('h',pack));
  if (get_var('glass',pack)='yes') or (get_var('glass',pack)='')
  then doglass:=true else doglass:=false;
  result:=get_var('ret',pack);
  run:=get_var('run',pack);
 end;
end;

procedure unpack_arr(arr:PStringArr; Var Dia:DiaRec);
 var size,i:integer;
begin
 size:=0;
 i:=arr^.SearchPart('image',0);
 if i=-1
 then dia.image:=''
 else dia.image:=argument(arr^.Get(i),1);
 for i:=0 to arr^.count-1 do
 begin
  if Same(Argument(arr^.get(i),0),'choice')
  then begin
   unpack2chc(Arr^.get(i),dia.choice[size]);
   inc(size);
  end;
 end;
 Dia.Choices:=Size;
end;

function in_choice(x,y,imx,imy:integer; var chc:diachoice):boolean;
begin
 in_choice:= belongs(x,imx+chc.x,imx+chc.x+chc.w-1) and
             belongs(y,imy+chc.y,imy+chc.y+chc.h-1);
end;

procedure run_choice(imx,imy:integer; var chc:diachoice);
 Var P:PCommands;
begin
 if chc.doglass
 then makeit_glassy(imx+chc.x,imy+chc.y,chc.w,chc.h,cChoiceWait);
 if chc.run<>''
 then begin
  P:=Player^.Acts^.GetName(chc.run);
  if P=nil
  then ErrorMSG(Str2Pchar('No such player function in VDIALOG:'+CHC.RUN))
  else P^.Run;
 end;
 if CHC.RESULT<>''
 then Quered:=chc.result;
end;

procedure run_dia(var dia:diarec);
 var p:pdevice;
     i,x,y,mx,my:integer;
begin
 if dia.image=cNoImage
 then exit
 else begin
  p:=New(PDevice,Load(res^.LoadRes(dia.image)^));
  x:=(loc_width - p^.width) div 2;
  y:=(loc_height - p^.height) div 2;
  Hide_mouse;
  clip;
  shrinkput(x,y,p,Screen,yes);
  show_mouse;
  while true do begin
   mx:=MousePosX;
   my:=MousePosY;
   if MouseButtons<>0 then begin
    While MouseButtons<>0 do;
    for i:=0 to dia.choices-1 do
        if in_choice(mx,my,x,y,dia.choice[i])
        then begin
              hide_mouse;
              run_choice(x,y,dia.choice[i]);
              dispose(p,done);
              clipoff;
              show_mouse;
              exit;
             end;
  end;
  end;
 end;
end;


var dialog:dialist;
    dialogs:integer;

    procedure init_dialogs(var f:text);
     var p:PStringArr;
         s:string;
    begin
     dialogs:=0;
     s:='';
     While not same(s,cNOMoreDialogs) do begin
      s:=readStr(f);
      if Same(Argument(s,0),cDiaStart)
      then begin
       new(p,init);
       p^.ReadTo(f,cDiaEnd);
       new(dialog[dialogs]);
       dialog[dialogs]^.name:=Argument(s,1);
       dialog[dialogs]^.choices:=0;
       unpack_arr(p,dialog[dialogs]^);
       dispose(p,done);
       inc(dialogs);
      end;
     end;
    end;

    procedure dodialog(name:string);
     var i:integer;
    begin
     for i:=0 to dialogs-1 do
     if same(dialog[i]^.name,name)
     then begin
      run_dia(dialog[i]^);
      exit;
     end;
     Message('Can`t found dialog '+name);
    end;

    procedure donedialogs;
     var a:integer;
    begin
     for a:=0 to dialogs-1 do Dispose(Dialog[a]);
    end;

end.