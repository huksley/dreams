Unit Menu;

interface
uses tpstr;

const
     cMaxMenuItems = 32;
     cDescSize = 32;
     cNameSize = 15;
     cMenuitem = 'Menuitem';
     cAddMenu  = 30;
     cRectColor= 43;
     cUndColor  = 25;
     cMenuTitle = 'Меню паpаметpов игpока';

type itemrec = record
      Desc:String[cDescSize];
      ParName:String[cNameSize];
     end;

     itemlist = array[0..cMaxMenuItems-1] of itemrec;

     function unpack_arr(arr:PStringArr; var list:itemlist):integer;
     procedure showitems(list:itemlist; size:integer);

implementation

uses data,misc,fx_mouse,fx_pens,fx_form,tpparam,flobjects,fx_init;

{$I locrange}

     procedure unpack2rec(pack:string; var item:itemrec);
     begin
      item.desc:=argument(pack,0);
      item.ParName:=argument(pack,1);
     end;

     function unpack_arr(arr:PStringArr; var list:itemlist):integer;
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

       if Same(cmd,cMenuItem) then begin
                                    unpack2rec(pack,list[listsize]);
                                    inc(listsize);
                                   end;
      end;
      unpack_arr:=listsize;
     end;

     function item_wid(var item:itemrec):word;
      var param:PParam;
     begin
      param:=Player^.Params^.SearchRec(Item.ParName);
      if param=nil
      then item_wid:=LightFont^.lnWidth(Item.desc)
      else item_wid:=LightFont^.lnWidth(Item.desc +' '+Param^.Value);
     end;

     function list_maxwid(var list:itemlist; size:integer):word;
      var i:integer;
          Wid,TempW:Word;
     begin
      Wid:=0;
      for i:=0 to Size-1 do
      begin
       TempW:=Item_wid(list[i]);
       if TempW>Wid then Wid:=TempW;
      end;
      list_maxwid:=Wid;
     end;

     function item_value(var item:itemrec):string;
      var param:PParam;
     begin
      param:=Player^.Params^.SearchRec(Item.ParName);
      if Param=nil
      then item_value:=''
      else item_value:=Param^.Value;
     end;

     function menu_form:pform;
     begin
      menu_form:=make_form( Rnd_fr,
                            New(PConvertPen,Init(Palette^.GlassIndex)),
                            LightFont );
     end;

     procedure showitems(list:itemlist; size:integer);
      var maxwid:word;
          maxhgt:word;
          tempy,x,y:word;
          form:pform;
          fr:pframe;

          i:integer;
          value:string[cNAmeSize];
          vx,vy,vw,vh:integer;
          p:pcolorpen;
          cpen,cpen1:PConvertPen;
     begin
      form:=menu_form;
      maxwid:=list_maxwid(list,size)+cADDMenu+form^.offsetx*2;
      maxhgt:=(LightFont^.lnHeight+5)*(size+1)+form^.offsety*2+1;
      if (MaxWid<loc_width) and (MaxHgt<loc_height)
      then begin
       x:=(loc_width-MaxWid) div 2;
       y:=(loc_height-MaxHgt) div 2;
      end else begin
       x:=1;
       y:=1;
      end;
      hide_mouse;
      form^.show(Screen,X,Y,X+MaxWID-1,Y+MaxHGT-1);
      show_mouse;

       p:=New(PColorPen,Init(COLORS.PAPER));
       cpen:=New(PConvertPen,Init(Palette^.BrightIndex));
       cpen1:=New(PConvertPen,Init(Palette^.GlassIndex));
       fr:=butt_fr;
       tempy:=y+(LightFont^.lnHeight div 2)+form^.offsety;
       x:=x+form^.offsetx+1;

       hide_mouse;
       if LightFont^.lnWidth(cMenuTitle)>MaxWid
       then LightFont^.Writelen(x,tempy,MaxWid-Form^.OffsetX*2,Screen,cMenuTitle)
       else LightFont^.Writeln(x+(MaxWid-LightFont^.lnWidth(cMenuTitle)) div 2-Form^.OffsetX,tempy,Screen,cMenuTitle);
       Screen^.HLinear( x+(MaxWid-LightFont^.lnWidth(cMenuTitle)) div 2-Form^.OffsetX,
                        tempY+LightFont^.lnHeight+2,
                        LightFont^.LnWidth(cMenuTitle),P);
       show_mouse;

       tempy:=tempy+3+LightFont^.lnHeight+3;

       hide_mouse;
       for i:=0 to Size-1 do begin
        LightFont^.Writeln(x,tempy,Screen,list[i].desc);

        value:=(item_value(list[i]));
        FormatStr(Value);
        vw:=LightFont^.lnWidth(value)-1;
        vh:=LightFont^.lnHeight;
        vx:=x+MaxWid-4-vw-form^.offsetx*2;
        vy:=tempy;
        Screen^.Map(vx-1,vy-1,vx+vw,vy+vh,cpen1);
        LightFont^.Writeln(vx,vy,Screen,Value);
        if Value<>'' then begin
          Screen^.Rectangle(vx-2,vy-2,vx+vw+1,vy+vh+1,cpen);
          Screen^.Rectangle(vx-2,vy-2,vx+vw+1,vy+vh+1,cpen);
        end;
        {fr^.DrawAround(Screen,vx-1,vy-1,vx+vw,vy+vh);}
        tempy:=tempy+LightFont^.lnHeight+5;
       end;
       show_mouse;
      anyclick;

      hide_mouse;
      form^.unshow;
      Dispose(cpen1,done);
      Dispose(cpen,done);
      Dispose(p,done);
      Dispose(fr,done);
      Dispose(Form,Done);
      show_mouse;
     end;

end.


