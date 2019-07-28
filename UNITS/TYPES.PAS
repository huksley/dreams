Unit types;

interface

Uses fx_dev;

const
     cCANCEL = 02;
     cOK     = 01;

type
     viewrec=object
      x,y,w,h:integer;
      function contains(a,b:integer):boolean;
      procedure show(c:byte;dev:pdevice);
     end;

     tstring=string[16];
     nstring=string[32];

implementation

uses misc,fx_pens;

        function viewrec.contains;
        begin
         contains:= belongs(a,x,x+w-1) and
                    belongs(b,y,y+h-1);
        end;
        procedure viewrec.show;
         var p:pcolorpen;
        begin
         new(p,init(c));
         dev^.rectangle( x,y,x+w-1,y+h-1, p);
         dispose(p,done);
        end;

end.