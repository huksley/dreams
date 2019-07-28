Unit Fx_menu;

interface
 uses types,fx_form;

const
      cNoItem = -1;
      cMenuItemCol = 0;
      cHighItemCol = 35;
      cActItemCol  = 138;
      cPasItemCol  = 137;

      cMinWidth = 30;

type PMenuItem = ^TMenuItem;
     TMenuItem = object(TGr_object)
      constructor Init;
      function get_id(x,y:integer):integer; virtual;
     end;

type
    TMenuRec = record
     Name:System.PChar;
     Item:PMenuItem;
    end;

    TMenuArr = array[0..255] of TMenuRec;
    PMenuArr = ^TMenuArr;

type PMenuId = ^TMenuId;
     TMenuId = object(TMenuItem)
      Id:Integer;
      constructor Init(AId:Integer);
      function get_id(x,y:integer):Integer; virtual;
     end;

type PMenuList = ^TMenuList;
     TMenuList = object(TMenuItem)
      MenuList:PMenuArr;
      MenuMax:Byte;
      MenuListSize:Byte;
      constructor Init(ListSize:Byte);
      destructor Done; Virtual;
      procedure PutItem(Name:TString; Item:PMenuItem);

      procedure Active;
      procedure Passive;

      function ItemWidth(I:Integer):Integer;
      function RecMaxWid:integer;
      function RecSumWid(Space:Integer):integer;
      function RecSumHgt(Space:Integer):integer;
     end;

type PMenuVer = ^TMenuVer;
     TMenuVer = object(TMenuList)
      procedure Repaint; virtual;
      function Width:word; virtual;
      function Height:word; virtual;
      procedure ShowItem(x,y,w:integer; Var Rec:TMenuRec);
      function Get_id(x,y:integer):Integer; virtual;
     end;

type PMenuHor = ^TMenuHor;
     TMenuHor = object(TMenuList)
      procedure Repaint; virtual;
      function Width:word; virtual;
      function Height:word; virtual;
      procedure ShowItem(x,y,w:integer; Var Rec:TMenuRec);
      function Get_id(x,y:integer):Integer; virtual;
     end;

implementation

 Uses strings,data,tpstr,flgraph,
      misc,fx_types,fx_mouse,
      fx_pens,fx_init,
      fx_fonts,fx_dev;

     constructor TMenuItem.Init;
      var fr:PArr_Frame;
     begin
      New(Fr,init);
      inherited init( make_form(fr, std_ground, LightFont ),
                      0, Screen );
     end;
     function TMenuItem.get_id;
     begin
      get_id:=cNoItem;
     end;

    procedure CreateMenuRec(Name:TString; Item:PMenuItem; Var Rec:TMenuRec);
    begin
     Rec.Name:=Str2PChar(Name);
     Rec.Item:=Item;
    end;

     Constructor TMenuId.Init;
     begin
      inherited Init; Id:=AId;
     end;
     function TMenuId.Get_id;
     begin
      Get_iD:=Id;
     end;

     procedure TMenuList.Active;
      var p:PColorPen;
     begin
      New(P,init(cActItemCol));
      Device^.Rectangle(PosX,PosY,PosX+Width-1,PosY+Height-1,P);
      Dispose(P,Done);
     end;
     procedure TMenuList.Passive;
      var p:PColorPen;
     begin
      New(P,init(cPasItemCol));
      Device^.Rectangle(PosX,PosY,PosX+Width-1,PosY+Height-1,P);
      Dispose(P,Done);
     end;
     constructor TMenuList.Init;
     begin
      inherited init;
      GetMem(MenuList,ListSize*Sizeof(TMenuRec));
      MenuMax:=ListSize;
      MenuListSize:=0;
     end;
     destructor TMenuList.Done;
      var i:integer;
     begin
      for i:=0 to MenuListSize-1 do begin
       if MenuList^[i].Item<>nil then Dispose(MenuList^[i].Item,Done);
       StrDispose(MenuList^[i].Name);
      end;
      FreeMem(MenuList,MenuMax*SizeOf(TMenuRec));
      inherited done;
     end;
     procedure TMenuList.PutItem;
     begin
      CreateMenuRec(Name,Item,MenuList^[MenuListSize]);
      Inc(MenuListSize);
     end;
     function TMenuList.ItemWidth;
      var temp:integer;
     begin
      temp:=Font^.lnWidth(StrPas(MenuList^[i].Name));
      if Temp<cMinWidth then Temp:=cMinWidth;
      ItemWidth:=Temp;
     end;
     function TMenuList.RecMaxWid;
      var Temp,Wid:Integer; i:integer;
     begin
      Wid:=0;
      for i:=0 to MenuListSize-1 do
      begin
       Temp:=Font^.lnWidth(StrPas(MenuList^[i].Name));
       if Temp>Wid then Wid:=Temp;
      end;
      if Wid>cMinWidth
      then RecMaxWid:=Wid
      else RecMaxWid:=cMinWidth;
     end;
     function TMenuList.RecSumHgt;
     begin
      RecSumHgt:=(Font^.lnHeight+Space)*MenuListSize;
     end;
     function TMenuList.RecSumWid;
      var Sum,i,Temp:Integer;
     begin
      Sum:=0;
      for I:=0 to MenuListSize-1 do
          Sum:=Sum + ItemWidth(i) + Space;
      RecSumWid:=Sum;
     end;

     function TMenuVer.Width;
     begin
      Width:=Inherited Width + RecMaxWid + 5;
     end;
     function TMenuVer.Height;
     begin
      Height:=Inherited Height + RecSumHgt(3) + 3 ;
     end;
     procedure TMenuVer.ShowItem;
      var p:PColorPen;
     begin
      New(P,Init(cMenuItemCol));
       Device^.Rectangle(x,y,x+w+2,y+Font^.lnHeight+3,P);
       Font^.Writeln(x+2,y+2,Device,StrPas(Rec.Name));
      Dispose(P,Done);
     end;
     procedure TMenuVer.Repaint;
      var x,y,i,w:integer;
     begin
      x:=StartX+1; y:=StartY+1; w:=RecMaxWid;
      for i:=0 to MenuListSize-1 do begin
       ShowItem(X,Y,W,MenuList^[i]);
       y:=y+Font^.lnHeight+3;
      end;
     end;
     function TMenuVer.Get_id;
      var w,i,n:integer;
          high:Integer;
          P:PColorPen;
          MustHide:boolean;

      procedure RestStat;
      begin
           P^.SetColor(cMenuItemCol);
           if Belongs(High,0,MenuListSize-1) then
           Device^.Rectangle( StartX+1,
                              StartY+1+High*(Font^.lnHeight+3),
                              StartX+1+W+2,
                              StartY+1+(High+1)*(Font^.lnHeight+3),P );
      end;
      procedure UpdateStat;
       var i:integer;
      begin
        if Belongs(x,StartX+2,StartX+W-1) and
           Belongs(y,StartY+1,StartY+RecSumHgt(4)-4)
        then begin
         i:=(y-(StartY+2)) div (Font^.lnHeight+3);
         if i<>high then begin
           Hide_mouse;
           P^.SetColor(cMenuItemCol);
           if Belongs(High,0,MenuListSize-1) then
           Device^.Rectangle( StartX+1,
                              StartY+1+High*(Font^.lnHeight+3),
                              StartX+1+W+2,
                              StartY+1+(High+1)*(Font^.lnHeight+3),P );
           P^.SetColor(cHighItemCol);
           if Belongs(i,0,MenuListSize-1) then
           Device^.Rectangle( StartX+1,
                              StartY+1+i*(Font^.lnHeight+3),
                              StartX+1+W+2,
                              StartY+1+(i+1)*(Font^.lnHeight+3),P );
           High:=I;
           Show_mouse;
         end;
        end else if Belongs(High,0,MenuListSize-1)
                 then begin
                  P^.SetColor(cMenuItemCol);
                  Hide_mouse;
                  Device^.Rectangle( StartX+1,
                                     StartY+1+High*(Font^.lnHeight+3),
                                     StartX+1+W+2,
                                     StartY+1+(High+1)*(Font^.lnHeight+3),P );
                  Show_Mouse;
                  P^.SetColor(cHighItemCol);
                  High:=-1;
                 end;
      end;

     begin
      Get_id:=cNoItem;
      MustHide:=true;

      Hide_mouse; if Viewed
                  then MustHide:=false
                  else Show(x,y);
      Active; Show_mouse;

      w:=RecMaxWid; New(P,Init(cHighItemCol)); High:=-1;
      while MouseButtons<>cRightButton do begin
       x:=MousePosX; y:=MousePosY;
       UpdateStat;
       if MouseButtons=cLeftButton then begin
        ClearInput;
        if Belongs(x,StartX+2,StartX+W-1) and
           Belongs(y,StartY+1,StartY+RecSumHgt(4)-4)
        then begin
         i:=(y-(StartY+2)) div (Font^.lnHeight+3);
         if not Belongs(i,0,MenuListSize-1)
         then Message('Index out of range')
         else if MenuList^[i].Item<>Nil
              then begin
               n:=MenuList^[i].Item^.Get_id(x,y);
               if n=-1
               then begin
                Hide_mouse;
                MenuList^[i].Item^.Hide;
                Show_mouse;
                Continue;
               end else Get_id:=n;
              end;
         RestStat;
         Hide_mouse; Passive; if MustHide then Hide; Show_mouse; Dispose(P,Done);
         Exit;
        end;
       end;
      end;
      ClearInput; RestStat;
      Hide_mouse; Show_mouse; Dispose(P,Done);
     end;

     function TMenuHor.Width;
     begin
      Width:=Inherited Width + RecSumWid(2) + 3 ;
     end;
     function TMenuHor.Height;
     begin
      Height:=Inherited Height + Font^.lnHeight + 6;
     end;
     procedure TMenuHor.ShowItem;
      var p:PColorPen;
     begin
      New(P,Init(cMenuItemCol));
       Device^.Rectangle(x,y,x+w+2,y+Font^.lnHeight+3,P);
       Font^.Writeln(x+2,y+2,Device,StrPas(Rec.Name));
      Dispose(P,Done);
     end;
     procedure TMenuHor.Repaint;
      var x,y,i,w:integer;
     begin
      x:=StartX+1; y:=StartY+1;
      for i:=0 to MenuListSize-1 do begin
       w:=ItemWidth(i); ShowItem(X,Y,W,MenuList^[i]);
       x:=x+W+2;
      end;
     end;
     function TMenuHor.Get_id;
      var W,N,K:Integer;
          P:PColorPen;
          High:Integer;
          MustHide:Boolean;

      function InMenu(x,y:integer):Boolean;
      begin
       InMenu:= Belongs(x,StartX+1,StartX+W) and
                Belongs(y,StartY+1,StartY+Font^.lnHeight+4);
      end;
      function GetNum(x:Integer):Integer;
       var a,i,w:integer;
      begin
       a:=StartX+1; GetNum:=cNoItem;
       for i:=0 to MenuListSize-1 do begin
        w:=ItemWidth(i);
        if Belongs(x,a,a+w+2) then begin
         GetNum:=i;
         exit;
        end;
        a:=a+W+2;
       end;
      end;

      procedure DrawItem(n:Integer;P:PPen);
       var a,i:integer;
      begin
       a:=StartX+1;
       for i:=0 to n-1 do begin
        a:=a+ItemWidth(i)+2;
       end;
       Hide_mouse;
       Device^.Rectangle( a,StartY+1,
                          a+ItemWidth(n)+2,StartY+Font^.lnHeight+4,P );
       Show_Mouse;
      end;

      procedure DrawRest;
      begin
        P^.SetColor(cMenuItemCol);
        If Belongs(High,0,MenuListSize-1) then DrawItem(High,P);
      end;
      procedure UpDateStat;
       var i:integer;
      begin
       if InMenu(x,y)
       then begin
        i:=GetNum(x);
        if i<>High then begin
         P^.SetColor(cMenuItemCol);
         If Belongs(High,0,MenuListSize-1) then DrawItem(High,P);

         P^.SetColor(cHighItemCol);
         If Belongs(i,0,MenuListSize-1) then DrawItem(i,P);

         High:=I;
        end;
       end else if Belongs(High,0,MenuListSize-1)
                then begin
                 P^.SetColor(cMenuItemCol);
                 DrawItem(High,P);
                 High:=-1;
                end;
      end;

     begin
      Get_id:=cNoItem;

      MustHide:=true;
      Hide_mouse; if Viewed
                  then MustHide:=false
                  else Show(x,y);
      Active; Show_Mouse;

      W:=RecSumWid(2); New(P,Init(0)); High:=-1;
      while MouseButtons<>cRightButton do begin
       x:=MousePosX; y:=MousePosY;
       UpDateStat;
       if MouseButtons=cLeftButton then begin
        ClearInput;
        if InMenu(X,y)
        then begin
         N:=GetNum(x);
         if MenuList^[N].Item<>Nil
              then begin
               K:=MenuList^[N].Item^.Get_id(x,y);
               if K=-1
               then begin
                Hide_mouse;
                MenuList^[N].Item^.Hide;
                Show_mouse;
                Continue;
               end else Get_id:=K;
              end;
         DrawRest;
         Hide_mouse; Passive; If MustHide then Hide; Show_mouse; Dispose(P,Done);
         Exit;
        end;
       end;
      end;
      ClearInput; DrawRest;
      Hide_mouse; Passive; If MustHide then Hide; Show_mouse; Dispose(P,Done);
     end;

end.