{$R-,Q-}
type
     piconbar=^ticonbar;
     ticonbar=object(tgr_object)
      iconw   :word;
      iconh   :word;
      iconlen :word;
      icons   :integer;
      icon:array[0..cMaxIcons] of PDevice;
      moveup,movedn:pdevice;
      current:word;

      upx,upy,dnx,dny:word;
      picx,picy:word;

      constructor init(aiconw,aiconh,aiconlen:word);
      function add_icon(devname:string):integer;
      destructor done; virtual;
      function  width:word; virtual;
      function  height:word; virtual;
      procedure redraw_arrows;
      procedure redraw_icons(start:word);
      procedure redraw_icon(num:word; x,y:word);

      procedure repaint; virtual;
      function choose(x,y:word):integer;
      function lazychoose(x,y:word):integer;

      { minus - up; plus - dn }
      procedure scroll(val:integer);
     end;
     procedure ticonbar.scroll;
      var start:word;
     begin
      if icons<=iconlen then exit;
      if viewed then begin
       if val+current<0
       then start:=0
       else if val+current+iconlen>=icons
            then start:=icons-iconlen
            else start:=val+current;
       current:=start;
       redraw_icons(current);
      end;
     end;
     function ticonbar.lazychoose;
     begin
      if icons<=0
      then begin
       lazychoose:=-1;
      end else

      if viewed then begin
               if belongs(x,startx+picx,startx+picx+iconw-1) and
                  belongs(y,starty+picy,starty+picy+(iconh+cICONSP)*iconlen-1-cICONSP)
               then begin
                y:=(y-starty-picy) div (iconh+cICONSP);
                lazychoose:=y+current;
                if y+current>icons-1 then lazychoose:=-1;
               end else lazychoose:=-1;
      end;
     end;
     function ticonbar.choose;
     begin
      if icons<=0
      then begin
       choose:=-1;
      end else

      if viewed then begin
       if belongs(x,upx+startx,startx+upx+moveup^.width-1) and
          belongs(y,upy+starty,starty+upy+moveup^.height-1)
       then begin
         PlaySound(sndClick);
         scroll(-1);
         choose:=-1;
       end else
           if belongs(x,startx+dnx,startx+dnx+movedn^.width-1) and
              belongs(y,starty+dny,starty+dny+movedn^.height-1)
           then begin
            PlaySound(sndClick);
            scroll(1);
            choose:=-1;
           end else
               if belongs(x,startx+picx,startx+picx+iconw-1) and
                  belongs(y,starty+picy,starty+picy+(iconh+cICONSP)*iconlen-1-cICONSP)
               then begin
                y:=(y-starty-picy) div (iconh+cICONSP);
                choose:=y+current;
                if y+current>icons-1 then choose:=-1;
               end else choose:=-1;
      end;
     end;
     function ticonbar.width;
     begin
      if iconw<moveup^.width
      then width:=moveup^.width+4+inherited width
      else width:=iconw+4+inherited width;
     end;
     function ticonbar.height;
     begin
      height:=moveup^.height+cICONSP+iconlen*(cICONSP+iconh)+movedn^.height+inherited height;
     end;
     procedure ticonbar.repaint;
     begin
      hide_mouse;
      redraw_arrows;
      redraw_icons(current);
      show_mouse;
     end;
     procedure ticonbar.redraw_icon;
      var p:pcolorpen;
          w,h:integer;
     begin
      if icon[num]=nil then exit;

      if viewed then begin
       if (icon[num]^.width>iconw) or (icon[num]^.height>iconh)
       then begin
        new(p,init(cFILLCOL));
        device^.map(x,y,x+iconw-1,y+iconh-1,p);
        dispose(p,done);
        if icon[num]^.width>iconw
        then w:=iconw
        else begin
         x:=x+abs(iconw-icon[num]^.height) div 2;
         w:=icon[num]^.width;
        end;
        if icon[num]^.height>iconh
        then h:=iconh
        else begin
         y:=y+abs(iconh-icon[num]^.height) div 2;
         h:=icon[num]^.height;
        end;
        icon[num]^.partdevicecopy0(x,y,0,0,w,h,device)
       end
       else begin
        new(p,init(cFILLCOL));
        device^.map(x,y,x+iconw-1,y+iconh-1,p);
        dispose(p,done);
        icon[num]^.fulldevicecopy0(x+ (iconw-icon[num]^.width ) div 2,y+ (iconh-icon[num]^.height) div 2,device );
       end;
      end;
     end;
     procedure ticonbar.redraw_arrows;
      var x,y:integer;
     begin
      if viewed then begin
       moveup^.fulldevicecopy(upx+startx,upy+starty,device);
       movedn^.fulldevicecopy(dnx+startx,dny+starty,device);
      end;
     end;
     procedure ticonbar.redraw_icons;
      var a,x,y,istart,iend:integer;
     begin
      x:=startx+picx; y:=starty+picy;
      istart:=current;
{      if current+iconlen-1<icons
      then iend:=current+iconlen-1
      else iend:=icons-1;}
      iend:=current+iconlen-1;
      WVend;
      for a:=istart to iend do
      begin
       redraw_icon(a,x,y);
       y:=y+iconh+cICONSP-1;
      end;
     end;
     constructor ticonbar.init;
      var i:integer;
     begin
      inherited init( make_form( new(parr_frame,init),new(phidepen,init),lightfont ), 1, screen );
      icons:=0; iconlen:=aiconlen;
      iconw:=aiconw; iconh:=aiconh;
      moveup:=new(pdevice,load(res^.loadres(cICONUP)^));
      movedn:=new(pdevice,load(res^.loadres(cICONDN)^));
      current:=0;

      for i:=0 to cMaxIcons-1 do Icon[i]:=nil;

      if moveup^.width>iconw
      then upx:=0
      else upx:=(iconw-moveup^.width) div 2;
      upy:=0;
      dnx:=upx;
      dny:=moveup^.height-1 + cICONSP + iconlen*(cICONSP+iconh)-1;
      if moveup^.width<iconw
      then picx:=0
      else picx:=(moveup^.width-iconw) div 2;
      picy:=moveup^.height+cICONSP;
     end;
     function ticonbar.add_icon;
     begin
      add_icon:=-1;
      if icons=cMaxIcons
      then ErrorMSG('Can`t add more icons')
      else begin
       add_icon:=icons;
       icon[icons]:=new(pdevice,load(res^.loadres(DEVNAME)^));
       inc(icons);
       redraw_icons(current);
      end;
     end;
     destructor ticonbar.done;
      var a:integer;
     begin
      for a:=0 to icons-1 do dispose(icon[a],done);
      dispose(moveup,done);
      dispose(movedn,done);
      inherited done;
     end;
