Unit AppDll;

 interface

  const AppLib = 'APPLETS';

  procedure CallExternal(Id:Integer);

  procedure FeatureProc1;
  procedure FeatureProc2;
  procedure FeatureProc3;
  procedure FeatureProc4;
  procedure FeatureProc5;
  procedure FeatureProc6;
  procedure FeatureProc7;
  procedure FeatureProc8;
  procedure FeatureProc9;
  procedure FeatureProc10;

 implementation

  uses flgraph,fx_mouse,status,fx_shape,fx_init,flscript,flobjects;

  procedure CallExternal(Id:Integer);
  begin
   clip;
   Done_status;
   DoneMouseHandler;
   Palette^.FadeTo(Black^,8);
   ClearGr;
   Palette^.Apply;
   case id of
    1 : FeatureProc1;
    2 : FeatureProc2;
    3 : FeatureProc3;
    4 : FeatureProc4;
    5 : FeatureProc5;
    6 : FeatureProc6;
    7 : FeatureProc7;
    8 : FeatureProc8;
    9 : FeatureProc9;
    10: FeatureProc10;
   end;
   InitMouseHandler(new(pcursor,load(res^.loadres('stCURSOR')^)));
   Black^.Apply;
   clipoff;
   dofadeloc:=false;
   updatelocation(CurrentLoc);
   dofadeloc:=true;
   Palette^.FadeFrom(Black^,8);
   Show_mouse;
  end;

   procedure FeatureProc1; external AppLib index 1;
   procedure FeatureProc2; external AppLib index 2;
   procedure FeatureProc3; external AppLib index 3;
   procedure FeatureProc4; external AppLib index 4;
   procedure FeatureProc5; external AppLib index 5;
   procedure FeatureProc6; external AppLib index 6;
   procedure FeatureProc7; external AppLib index 7;
   procedure FeatureProc8; external AppLib index 8;
   procedure FeatureProc9; external AppLib index 9;
  procedure FeatureProc10; external AppLib index 10;

end.
