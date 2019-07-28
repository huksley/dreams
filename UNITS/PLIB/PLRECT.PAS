{$R-,Q-,S-,B-}
Unit plrect;

interface

type
     TPoint = object
      x,y:integer;
     end;
type
     TRect = object
      x,y,x1,y1:integer;
      procedure assign(ax,ay,bx,by:integer);
      procedure move(incx,incy:integer);
      function width:integer;
      function height:integer;

      function contain_point(ax,ay:integer):boolean;
      function ver_in(ax,ay,ay1:integer):boolean;
      function hor_in(ax,ax1,ay:integer):boolean;
      function intersect(ax,ay,bx,by:integer):boolean;
     end;

implementation

     procedure trect.assign;
     begin
      x:=ax; y:=ay; x1:=bx; y1:=by;
     end;
     procedure trect.move;
     begin
      inc(x,incx); inc(y,incy);
      inc(x1,incx); inc(y1,incy);
     end;
     function trect.width;
     begin
      width:=(x1-x+1);
     end;
     function trect.height;
     begin
      height:=(y1-y+1);
     end;
     function trect.contain_point;
     begin
      contain_point:= (ax>=x) and (ax<=x1) and
                      (ay>=y) and (ay<=y1);
     end;
     function trect.ver_in;
     begin
      ver_in:= ((ax>=x)and(ax<=x1)) and
               (( (ay>=y) and (ay<=y1) ) or
                ( (ay1>=y) and (ay1<=y1) ) or
                ( (ay<y) and (ay1>y1) ));
     end;
     function trect.hor_in;
     begin
      hor_in:= ((y<=ay)and(ay<=y1)) and
               ( ((x<=ax) and (ax<=x1)) or
                 ((x<=ax1)and(ax1<=x1)) or
                 ((ax<x) and (ax1>x1)) );


     end;
     function trect.intersect;
     begin
      intersect:= contain_point(ax,ay) or
                  contain_point(bx,by) or
                  contain_point(ax,by) or
                  contain_point(bx,ay) or
                  ver_in(ax,ay,by) or
                  ver_in(bx,ay,by) or
                  hor_in(ax,bx,ay) or
                  hor_in(ax,bx,by);
     end;

end.
