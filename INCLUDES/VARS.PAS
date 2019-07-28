const
     cGLOBVARPRE='$';

var GlobVar:PParamColl;

procedure GlobVarReplace(Var CMD:String);
 var i:integer;
begin
 for i:=0 to GlobVar^.count-1 do
  if Pos(cGLOBVARPRE+GlobVar^.Get(i)^.Param,CMD)<>0
  then fx_strop.replace( cGLOBVARPRE+GlobVar^.Get(i)^.Param,
                GlobVar^.Get(i)^.Value,CMD );
end;

procedure done_globvars;
begin
 dispose(GlobVar,Done);
end;

procedure init_globvars;
begin
 New(GlobVar,init);
 add_exit_proc(@done_globvars);
end;

procedure control_var(s:string);
 var
     param:string;
     value:string;
     par:pparam;
begin
 param:=Argument(s,0);
 Value:=Copy(s,Pos(Param,s)+Length(Param)+1,255);
 if Same(Param,'QUERY')
 then Quered:=value;
 par:=GlobVar^.SearchRec(Param);
 if par<>nil
 then par^.Value:=Value
 else GlobVar^.Param(Param,Value);
end;

