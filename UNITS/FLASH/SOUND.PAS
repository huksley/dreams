Unit Sound;
 interface
   uses objects,audio;

 Type PStreamBlaster = ^TStreamBlaster;
      TStreamBlaster = object(SoundBlasterPro)
       SoundStream : PStream;
       Playing     : boolean;
       Rest        : Longint;
       constructor Init(Port,Irq,Dma:word; Stream:PStream);
       procedure   PlaySound(Pos,Size:Longint; Rate:Word);
       Procedure   OutBuffer (Var Buffer; Size : Word); Virtual;
       Procedure   InBuffer  (Var Buffer; Size : Word); Virtual;
       Procedure   RecordingReady; Virtual;
       Procedure   PlaybackReady; Virtual;
       procedure   WaitPlayed;
      end;

 Type PSound = ^TSound;
      TSound = object(TObject)
       Name : String[16];
        Pos : Longint;
       Size : Longint;
       Rate : word;
      end;

      PSoundList = ^TSoundList;
      TSoundList = object(TCollection)
       procedure   Put(Sound:PSound);
       function    Get(i:integer):PSound;
       constructor Load(Var S:TStream);
       procedure   Store(Var S:TStream);
       function    Find(name:string):PSOund;
       procedure   LinkSound(FileName,Identifier:string;Rate:Word; var Data:TStream);
       procedure   Play(Sound:string; Var Device:TStreamBlaster);
      end;

 implementation
   uses tpstr;

      procedure TSoundList.Play;
       var Snd:PSound;
      begin
       Snd:=Find(Sound);
       If Snd<>nil
       then begin
        Device.PlaySound(Snd^.Pos,Snd^.Size,Snd^.Rate);
       end;
      end;
      procedure TSoundList.LinkSound;
       var F:PDosStream;
           p:PSound;
      begin
       New(F,Init(Filename,StOpenRead));
       if F^.Status<>StOk
       then Writeln('Can`t link - file not found')
       else begin
        new(p,init);
        p^.Name:=Identifier;
        p^.pos:=Data.GetPos;
        p^.size:=f^.getsize;
        p^.rate:=rate;
        data.copyfrom(f^,f^.getsize);
        Put(p);
       end;
      end;
      function TSoundList.Find;
       var a:integer;
      begin
       Find:=Nil;
        for a:=0 to Count-1 do
         if Same(Name,Get(a)^.Name)
         then begin
          Find:=Get(a);
          Exit;
         end;
      end;
      procedure TSoundList.Store;
       var Size:Word;
           a: integer;
      begin
       Size:=Count;
       S.Write(Size,Sizeof(Size));
       for a:=0 to Count-1 do with get(a)^ do begin
        PutString(Name,S);
        S.Write(Pos,Sizeof(Pos));
        S.Write(Size,Sizeof(Size));
        S.Write(Rate,Sizeof(Rate));
       end;
      end;
      constructor TSoundList.Load;
       var i,a:integer;
           p:PSound;
      begin
       inherited init(1,1);
       S.Read(a,sizeof(word));
       for i:=0 to a-1 do begin
        new(p,init);
        with P^ do begin
         name:=getstring(s);
         S.read(Pos,Sizeof(Pos));
         S.read(Size,Sizeof(Size));
         S.read(Rate,Sizeof(Rate));
        end;
        put(p);
       end;
      end;
      procedure TSoundList.put;
      begin
       Insert(Sound);
      end;
      function TSoundList.get;
      begin
       get:=At(i);
      end;

procedure TStreamBlaster.WaitPlayed;
begin
 While Playing do ;
end;
procedure TStreamBlaster.Outbuffer;
begin
 Abstract;
end;
procedure TStreamBlaster.RecordingReady;
begin
 Abstract;
end;
procedure TStreamBlaster.InBuffer;
begin
 SoundStream^.Read(Buffer,Size);
end;
procedure TStreamBlaster.PlaybackReady;
begin
 SetVolume(Master,LeftAndRight,1);
 Playing:=False;
end;
constructor TStreamBlaster.Init;
begin
 inherited init(Port,Irq,Dma);
 SetVolume(MicroPhone,LeftAndRight,1);
 SoundStream:=Stream;
 Playing:=False;
end;
procedure TStreamBlaster.PlaySound;
begin
 If (Pos<SoundStream^.GetSize) and
    (Pos+Size<=SoundStream^.GetSize)
 then begin
  SoundStream^.Seek(Pos);
  Playing:=True;
  SetVolume(Master,LeftAndRight,10);
  PlaySample(Rate,Size);
 end;
end;

end.
