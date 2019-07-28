Unit Paths;

interface

Const
                    { directory }                   { extension }
      cResourcePath ='resource\';    cResExt       ='dat';
      cFlicPath     ='anim\';        cFlicExt      ='flc';
      cScriptPath   ='script\';      cScriptExt    ='dat';
      cSoundPath    ='sound\';       cSoundExt     ='dat';
      cDot          ='.';

type  tdosname =string[08];
      tdosext  =string[03];
      tdosfile =string[14];

      function form_name(name:tdosfile;ext:tdosext):string;
      function    res_fname(name:string):string;
      function   flic_fname(name:string):string;
      function script_fname(name:string):string;
      function sound_fname(name:string):string;

implementation
      function form_name;
      begin
       if pos('.',name)=0
       then form_name:=name+cDOT+ext
       else form_name:=name;
      end;
      function res_fname;
      begin
       res_fname:=cResourcePath+form_name(name,cResExt);
      end;
      function   flic_fname(name:string):string;
      begin
       flic_fname:=cFlicPath+form_name(name,cFlicExt);
      end;
      function script_fname(name:string):string;
      begin
       script_fname:=cScriptPath+form_name(name,cScriptExt);
      end;
      function  Sound_fname(name:string):string;
      begin
       Sound_fname:=cSoundPath+form_name(name,cSoundExt);
      end;

end.
