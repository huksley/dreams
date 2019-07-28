unit talks;

interface

 uses tpstr,fx_dev,locview;


const
      cNAME_FIELD = 'name';
      cRES_FIELD  = 'res';
      cRES_DEFAULT= 'nil';
      CX_FIELD    = 'x';
      cY_FIELD    = 'y';
type
    ttalkrec=record
     name   :nstring;     { name of this man }
     pic    :tstring;     { his picture }
     x,y    :integer;
     text,                { text lines }
     choices,             { choices lines }
     vars   :pstringarr;  { this values will be stored to query }
    end;

    procedure init_talkrec(pack:string; var talkrec:ttalkrec);

    procedure addtext_talkrec(text:string; var talkrec:ttalkrec);
    procedure addchoice_talkrec(choice:string; var talkrec:ttalkrec);
    procedure addvar_talkrec(value:string; var talkrec:ttalkrec);

    procedure topic2text(topic:string; var talkrec:ttalkrec);
    procedure topic2choice(topic:string; var talkrec:ttalkrec);
    procedure topic2var(topic:string; var talkrec:ttalkrec);

     function show_talk(var talkrec:ttalkrec; screen:pdevice):tstring;

    procedure done_talkrec(var talkrec:ttalkrec);

implementation

 uses tptimeline,tpday,
      constants,kernel,core,misc,fx_mouse,
      flgraph,fx_init,fx_form,fx_pens,
      flscript,textlib,flobjects;


    procedure init_talkrec(pack:string; var talkrec:ttalkrec);
    begin
     with talkrec do begin
      name:=get_var(cNAME_FIELD,pack);
      if exists_var(cRES_FIELD,pack)
         then pic:=get_var(cRES_FIELD,pack)
         else pic:=cRES_DEFAULT;
      x:=toint(get_var(cX_FIELD,pack));
      y:=toint(get_var(cY_FIELD,pack));
      new(text,init);
      new(choices,init);
      new(vars,init);
     end;
    end;
    procedure addtext_talkrec(text:string; var talkrec:ttalkrec);
    begin
     talkrec.text^.put(text);
    end;
    procedure addchoice_talkrec(choice:string; var talkrec:ttalkrec);
    begin
     talkrec.choices^.put(choice);
    end;
    procedure addvar_talkrec(value:string; var talkrec:ttalkrec);
    begin
     talkrec.vars^.put(value);
    end;
    procedure topic2text(topic:string; var talkrec:ttalkrec);
    begin
     addtopic(topic,talkrec.text^);
    end;
    procedure topic2choice(topic:string; var talkrec:ttalkrec);
    begin
     addtopic(topic,talkrec.choices^);
    end;
    procedure topic2var(topic:string; var talkrec:ttalkrec);
    begin
     addtopic(topic,talkrec.vars^);
    end;

const
    cTALK_FR1 = 100;
    cTALK_FR2 = 101;
    cTALK_FR3 = 102;
    cTALK_BACK= 103;

    function showpic_talkrec(var x,y:integer; var talkrec:ttalkrec; screen:pdevice):pform;
     var pic:pdevice;
         form:pform;
         frame:parr_frame;
    begin
     if talkrec.pic<>cRES_DEFAULT
     then begin
      new(frame,init);
      frame^.put(new(pcolorpen,init(cTALK_FR1)),yes);
      frame^.put(new(pcolorpen,init(cTALK_FR2)),yes);
      frame^.put(new(pcolorpen,init(cTALK_FR3)),yes);
      form:=make_form(frame,new(pcolorpen,init(cTALK_BACK)),lightfont);
      pic:=new(pdevice,load(res^.loadres(talkrec.pic)^));
      form^.show(screen,x,y,x+form^.offsetx*2+pic^.width-1,y+form^.offsety*2+pic^.height-1);
      pic^.fulldevicecopy(x+form^.offsetx,y+form^.offsety,screen);
      x:=x+pic^.width+form^.offsetx*2+2; y:=y+pic^.height;
      dispose(pic,done);
      showpic_talkrec:=form;
     end else showpic_talkrec:=nil;
    end;

    { returns value }
    function show_talk(var talkrec:ttalkrec; screen:pdevice):locview.tstring;
     var picform:pform;
         textwin:ptextwindow;
         x,y:integer;
    begin
     x:=talkrec.x; y:=talkrec.y;
     hide_mouse;
     picform:=showpic_talkrec(x,y,talkrec,screen);
     show_mouse;
     y:=y+10;
     hide_mouse;
     textwin:=messWinXY(x,talkrec.y,talkrec.text);
     show_mouse;
     x:=talkrec.x;
     if y<textwin^.height+talkrec.y
     then y:=textwin^.height+talkrec.y+10;
     show_talk:=talkrec.vars^.get((show_arr(x,y,'Вы',talkrec.choices)));
     dispose(textwin,done);
     dispose(picform,done);
    end;
    procedure done_talkrec(var talkrec:ttalkrec);
    begin
     dispose(talkrec.text,done);
     dispose(talkrec.choices,done);
     dispose(talkrec.vars,done);
    end;

end.