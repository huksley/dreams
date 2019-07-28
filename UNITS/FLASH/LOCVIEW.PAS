{$DEFINE DEBUG_RECT}
{.$DEFINE TEXT_INFO}
Unit locview;

interface

 uses core,misc,flobjects,kernel,tpstr,
      fx_init,fx_dev,
      imgstack,data,
      fx_pens,constants,fx_mouse,fx_shape;

const
     { maximal amount of objects on screen }
     cmaxobjects = 32;
     { maximal amount of dirs on screen }
     cmaxdirs    = 8;

     cDEFAULT_FIND = '';
     cDEFAULT_NAME = '';
     cDEFAULT_VIEW = '';
     cDEFAULT_CUR  = '';
     cDEFAULT_X    = 0;
     cDEFAULT_Y    = 0;
     cDEFAULT_W    = 1;
     cDEFAULT_H    = 1;

     cVAR_VIEW  = 'res';
     cVAR_CUR   = 'cur';
     cVAR_ICON  = 'icon';
     cVAR_X     = 'x';
     cVAR_Y     = 'y';
     cVAR_W     = 'w';
     cVAR_H     = 'h';

type
     tstring=string[16];
     nstring=string[32];

     tobjrec=record
      { find key }
      find:tstring;
      { representative name }
      name:nstring;

      { resource related }
      view:tstring;  { .dev file }
      cur :tstring;  { .cur file }
      x   :integer;  { horiz position on screen }
      y   :integer;  { vert  position on screen }
      w   :word;     { active area width }
      h   :word;     { active area height }
     end;

type
    plocrec=^tlocrec;
    tlocrec=record
     self:tobjrec;

     objrec:array[0..cmaxobjects-1] of tobjrec;
     objcnt:integer;

     dirrec:array[0..cmaxdirs-1] of tobjrec;
     dircnt:integer;
    end;

     function contains_objrec(x,y:integer; var objrec:tobjrec):boolean;
     procedure show_view_objrec(var objrec:tobjrec; screen:pdevice);
     procedure show_cur_objrec(var objrec:tobjrec);
     procedure show_objrec(var objrec:tobjrec; screen:pdevice);
     procedure new_objrec(var objrec:tobjrec);
     procedure unpack_str(pack:string; var objrec:tobjrec);
     procedure pack_str(objrec:tobjrec; var s:string);
     procedure class2objrec(Kind:PFlashobject; var objrec:tobjrec);
     procedure dir2objrec(dir:string; var objrec:tobjrec);

    procedure loc2locrec(loc:plocation; var locrec:tlocrec);
    function is_dir(x,y:integer; var locrec:tlocrec):boolean;
    function get_objrec(x,y:integer; var locrec:tlocrec; var objrec:tobjrec):boolean;
    function get_name(x,y:integer; var locrec:tlocrec):nstring;
    function get_find(x,y:integer; var locrec:tlocrec):tstring;
    procedure del_objrec(find:tstring; var locrec:tlocrec; var objrec:tobjrec);

    procedure hide_find(find:tstring; var locrec:tlocrec; screen:pdevice);
    procedure show_locrec(var locrec:tlocrec; screen:pdevice);

implementation

uses crt,fx_fonts,flgraph,play,sounds;

const

     fullcopy : boolean = true;
     showingloc : boolean = true;

     function contains_objrec(x,y:integer; var objrec:tobjrec):boolean;
     begin
      contains_objrec
                 := belongs(x,objrec.x,objrec.x+objrec.w-1) and
                    belongs(y,objrec.y,objrec.y+objrec.h-1);
     end;

     procedure show_view_objrec(var objrec:tobjrec; screen:pdevice);
      var view:pdevice;
     begin
      if objrec.view<>cDEFAULT_VIEW then begin
       view:=new(PDevice,Load(res^.loadres(objrec.view)^));
       if showingloc
       then view^.partdevicecopy(objrec.x+6,objrec.y+6,6,6,view^.width-12,view^.height-12,screen)
       else view^.fulldevicecopy0(objrec.x,objrec.y,screen);

{       begin
        if fullcopy
        then view^.fulldevicecopy(objrec.x,objrec.y,screen)
        else        end else }
       dispose(view,done);
      end;
     end;

     procedure hide_view_objrec(locx,locy:integer; locview:tstring; var objrec:tobjrec; screen:pdevice);
      var view:pdevice;
          P:PColorPen;
     begin
      if locview<>cDEFAULT_VIEW then begin
       view:=new(PDevice,Load(res^.loadres(locview)^));
       hide_mouse; PlaySOund(sndClick);
       view^.partdevicecopy( objrec.x,objrec.y,
                             objrec.x-locx,objrec.y-locy,
                             objrec.w,objrec.h,
                             screen);
       show_mouse;
       dispose(view,done);
      end else begin
       New(P,init(0));
        Screen^.Map( objrec.x,objrec.y,
                     objrec.x+objrec.w-1,objrec.y+objrec.h-1
                     ,p);
       Dispose(P,Done);
      end;

     end;

     procedure show_cur_objrec(var objrec:tobjrec);
      var cur:pcursor;
     begin
      if objrec.cur<>cDEFAULT_CUR then begin
       cur:=new(PCursor,Load(res^.loadres(objrec.cur)^));
       put_handler(cur,objrec.x,objrec.y,objrec.x+objrec.w-1,objrec.y+objrec.h-1);
       dispose(cur,done);
      end;
     end;
     procedure hide_cur_objrec(var objrec:tobjrec);
     begin
      removehand(objrec.x,objrec.y,objrec.x+objrec.w-1,objrec.y+objrec.h-1);
     end;

     procedure hide_objrec(var locrec:tlocrec; var objrec:tobjrec; screen:pdevice);
     begin
      hide_cur_objrec(objrec);
      hide_view_objrec(locrec.self.x,locrec.self.y,locrec.self.view,objrec,screen);
     end;

     { next func makes a string to view as debugging }
     function view_objrec(font:pfont; objrec:tobjrec):string;
      var ax,ay:integer;
     begin
      with objrec do begin
       ax:=x; ay:=y;
       font^.writeln(ax,ay,screen,'find:' + find);
       ay:=ay+font^.lnHeight;
       font^.writeln(ax,ay,screen,'name:' + name);
       ay:=ay+font^.lnHeight;
       font^.writeln(ax,ay,screen,'view:' + view);
       ay:=ay+font^.lnHeight;
       font^.writeln(ax,ay,screen,'cur_:' + cur );
       ay:=ay+font^.lnHeight;
       font^.writeln(ax,ay,screen, 'x:'+tostr(x)+
                                  ' y:'+tostr(y)+
                                  ' w:'+tostr(w)+
                                  ' h:'+tostr(h));
      end;
     end;

     procedure show_objrec(var objrec:tobjrec; screen:pdevice);
      var p:pcolorpen;
     begin
      show_view_objrec(objrec,screen);
      show_cur_objrec(objrec);

      {$IFDEF TEXT_INFO}
      view_objrec(lightfont,objrec);
      {$ENDIF}

      {$IFDEF DEBUG_RECT}
      new(p,init(111));
       with objrec do screen^.rectangle(x,y,x+w-1,y+h-1,p);
      dispose(p,done);
      {$ENDIF}
     end;

     { next proc forms default/not active objrec }
     procedure new_objrec(var objrec:tobjrec);
     begin
      with objrec do begin
       find := cDEFAULT_FIND;
       name := cDEFAULT_NAME;
       view := cDEFAULT_VIEW;
       cur  := cDEFAULT_CUR;
       x    := cDEFAULT_X;
       y    := cDEFAULT_Y;
       w    := cDEFAULT_W;
       h    := cDEFAULT_H;
      end;
     end;

     {
       next proc unpacks string to objrec in following order :
       pack:='[cVAR_VIEW:<value>] [cVAR_CUR:<value>] [cVAR_X:<value>] ...';
       order of field is not valuable
       such string will be unpacked in appropriate field of objrec
       or defaults will be used.
      }
     procedure unpack_str(pack:string; var objrec:tobjrec);
      var p:pdevice;
     begin
      with objrec do begin
       w:=1; h:=1; view:='';
       if exists_var(cVAR_VIEW,pack) then view :=      get_var(cVAR_VIEW,pack);
       if exists_var(cVAR_CUR ,pack) then cur  :=      get_var(cVAR_CUR ,pack);
       if exists_var(cVAR_X   ,pack) then x    :=toint(get_var(cVAR_X   ,pack));
       if exists_var(cVAR_Y   ,pack) then y    :=toint(get_var(cVAR_Y   ,pack));
       if exists_var(cVAR_W   ,pack) then w    :=toint(get_var(cVAR_W   ,pack));
       if exists_var(cVAR_H   ,pack) then h    :=toint(get_var(cVAR_H   ,pack));
       UpCaseStr(View); UpCaseStr(Cur);
       if (w=1) and (h=1) and (view<>'')
       then begin
        if View='' then PlaySOund(sndClick);
        p:=New(PDevice,Load(Res^.LoadRes(View)^));
        w:=p^.Width;
        h:=p^.Height;
        Dispose(P,done);
       end;
      end;
     end;
     { next proc packs objrec to string,
       doing back operation to prev proc }
     procedure pack_str(objrec:tobjrec; var s:string);
     begin
      with objrec do begin
       add_var(cVAR_VIEW,view    ,s);
       add_var(cVAR_CUR ,cur     ,s);
       add_var(cVAR_X   ,tostr(x),s);
       add_var(cVAR_Y   ,tostr(y),s);
       add_var(cVAR_W   ,tostr(w),s);
       add_var(cVAR_H   ,tostr(h),s);
      end;
     end;


     { object class relation procedures and functions }

     { next proc extracts from class to objrec }
     procedure class2objrec(Kind:pFlashObject; var objrec:tobjrec);
     begin
      new_objrec(objrec);
      unpack_str(Kind^.reskey,objrec);
      objrec.find:=Kind^.name;
      objrec.name:=Kind^.playname;
     end;
     {
       next proc extracts from dir(way_out) desc to objrec
       dir='<name> <act> '+pack
       pack - is packed objrec
     }
     procedure dir2objrec(dir:string; var objrec:tobjrec);
     begin
      new_objrec(objrec);
      unpack_str(dir,objrec);
      objrec.find:=argument(dir,1);
      objrec.name:=argument(dir,0);
     end;


    { next proc packs information from all objects in location in
      one tlocrec }
    procedure loc2locrec(loc:plocation; var locrec:tlocrec);
     var a:integer;
    begin
     with locrec do begin
      class2objrec(loc,self);
      objcnt:=0;
      for a:=0 to loc^.things^.count-1 do begin
       if objcnt=cmaxobjects then begin
                errorMSG(Str2PChar('In location '+loc^.name+' too many objects'));
                exit;
             end;
             class2objrec(thinglist^.find(loc^.things^.get(a)),objrec[objcnt]);
             inc(objcnt);
      end;
      for a:=0 to humanlist^.count-1 do if same(phuman(HUMANLIST^.get(a))^.place,LOC^.name)          then begin
       if objcnt=cmaxobjects then begin
          errorMSG(Str2PChar('In location '+loc^.name+' too many objects'));
          exit;
       end;
       class2objrec(humanlist^.get(a),objrec[objcnt]);
       inc(objcnt);
      end;
      dircnt:=0;
      for a:=0 to loc^.directions^.count-1 do begin
       if objcnt=cmaxobjects then begin
          errorMSG(Str2PCHar('In location '+loc^.name+' too many dirs'));
          exit;
       end;
       dir2objrec(loc^.directions^.get(a),dirrec[dircnt]);
       inc(dircnt);
      end;
     end;
    end;

    function is_dir(x,y:integer; var locrec:tlocrec):boolean;
     var a:integer;
    begin
     for a:=0 to locrec.dircnt-1 do
      if contains_objrec(x,y,locrec.dirrec[a])
      then begin
       is_dir:=true;
       exit;
      end;
      is_dir:=false;
    end;

    function get_name(x,y:integer; var locrec:tlocrec):nstring;
     var a:integer;
    begin
     get_name:=locrec.self.name;
     for a:=0 to locrec.objcnt-1 do
      if contains_objrec(x,y,locrec.objrec[a])
      then begin
       get_name:=locrec.objrec[a].name;
       exit;
      end;
     for a:=0 to locrec.dircnt-1 do
      if contains_objrec(x,y,locrec.dirrec[a])
      then begin
       get_name:=locrec.dirrec[a].name;
       exit;
      end;
    end;

    function get_find(x,y:integer; var locrec:tlocrec):tstring;
     var a:integer;
    begin
     get_find:=locrec.self.find;
     for a:=0 to locrec.objcnt-1 do
      if contains_objrec(x,y,locrec.objrec[a])
      then begin
       get_find:=locrec.objrec[a].find;
       exit;
      end;
     for a:=0 to locrec.dircnt-1 do
      if contains_objrec(x,y,locrec.dirrec[a])
      then begin
       get_find:=locrec.dirrec[a].find;
       exit;
      end;
    end;

    function get_objrec(x,y:integer; var locrec:tlocrec; var objrec:tobjrec):boolean;
     var a:integer;
    begin
     get_objrec:=false; new_objrec(objrec);
     for a:=0 to locrec.objcnt-1 do
      if contains_objrec(x,y,locrec.objrec[a])
      then begin
       objrec:=locrec.objrec[a];
       get_objrec:=true;
       exit;
      end;
     for a:=0 to locrec.dircnt-1 do
      if contains_objrec(x,y,locrec.dirrec[a])
      then begin
       objrec:=locrec.dirrec[a];
       get_objrec:=true;
       exit;
      end;
    end;


    procedure show_locrec(var locrec:tlocrec; screen:pdevice);
     var a:integer;
    begin
     showingloc:=true;
     show_objrec(locrec.self,screen);
     showingloc:=false;
     for a:=0 to locrec.objcnt-1 do show_objrec(locrec.objrec[a],screen);
     for a:=0 to locrec.dircnt-1 do show_objrec(locrec.dirrec[a],screen);
    end;

    procedure hide_find(find:tstring; var locrec:tlocrec; screen:pdevice);
     var objrec:tobjrec;
    begin
     del_objrec(find,locrec,objrec);
     hide_mouse;
     hide_objrec(locrec,objrec,screen);
     show_mouse;
    end;

    procedure del_objrec(find:tstring; var locrec:tlocrec; var objrec:tobjrec);
     var a,b:integer;
    begin
     for a:=0 to locrec.objcnt-1 do
      if same(locrec.objrec[a].find,find)
      then begin
       objrec:=locrec.objrec[a];
       for b:=a+1 to locrec.objcnt-1 do
           locrec.objrec[b-1]:=locrec.objrec[b];
       exit;
      end;
     for a:=0 to locrec.dircnt-1 do
      if same(locrec.dirrec[a].find,find)
      then begin
       objrec:=locrec.dirrec[a];
       for b:=a+1 to locrec.dircnt-1 do
           locrec.dirrec[b-1]:=locrec.dirrec[b];
       exit;
      end;
    end;


end.


