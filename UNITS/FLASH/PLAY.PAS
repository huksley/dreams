Unit Play;

interface

  procedure PlaySound(Name:string);
  procedure WaitSound;
  procedure SoundInit;
  procedure SoundDone;

implementation

 Uses Core,Objects,SWSet,Sound,Audio;

  Var Device :PStreamBlaster;
      Data   :PDosStream;
      List   :PSoundList;
      WasEnabled:boolean;
  procedure PlaySound(Name:string);
  begin
   if SoundEnabled and (not Device^.Playing) then List^.Play(Name,Device^);
  end;
  procedure WaitSound;
  begin
   if SoundEnabled
   then While Device^.Playing do ;
  end;

  procedure SoundInit;
   var idx:PDosStream;
  begin
   if SoundEnabled then begin
    New(Data,init(SoundFile,stOpenRead));
    If Data^.Status<>stOk then FatalMSG('Error opening sound file');
    New(Idx,Init(IndexFile,stOpenRead));
    If Idx^.Status<>stOk then FatalMSG('Error opening index file');
    New(List,Load(Idx^));
    Dispose(Idx,done);
    New(Device,init(SB_Port,SB_Irq,SB_DMA,Data));
    WasEnabled:=True;
   end else WasEnabled:=False;
  end;
  procedure SoundDone;
  begin
   if WasEnabled then begin
    Device^.WaitPlayed;
    Dispose(List,Done);
    Dispose(Data,Done);
    Dispose(Device,Done);
   end;
  end;

 begin
 end.
