Unit Kernel;

interface

const
      cEXIT_STACK_SIZE = 64;

procedure add_exit_proc(proc:pointer);

implementation

uses streams,core;

type  tprocedure=procedure;
      texit_stack = array[0..cEXIT_STACK_SIZE-1] of pointer;

var   exit_stack:texit_stack;
      stack_size:integer;
      Heapwas,EMSwas,XMSwas:Longint;


procedure run_exit_stack;
 var a:integer;
begin
 if stack_size>0 then for a:=stack_size-1 downto 0 do tprocedure(exit_stack[a]);
 if HeapWas<>MemAvail
 then Writeln('Heap ',HeapWas-MemAvail,' bytes unfreed');
 if EMSWas<>EMS_MemAvail
 then Writeln('EMS ',EMSWas-EMS_MemAvail,' bytes unfreed');
 if XMSWas<>XMS_MemAvail
 then Writeln('XMS ',XMSWas-XMS_MemAvail,' bytes unfreed');
end;

procedure init_exit_stack;
begin
 SetCloseHandler(@run_exit_stack);
 stack_size:=0;
end;

procedure add_exit_proc(proc:pointer);
begin
 if stack_size=cEXIT_STACK_SIZE
 then ErrorMSG('Can_t add more procedures at exit')
 else begin
  exit_stack[stack_size]:=proc;
  inc(stack_size);
 end;
end;

begin
 HeapWas:=MemAvail;
 EMSWas:=EMS_MEMAVAIl;
 XMSWas:=XMS_MemAvail;
 initiate_core;
 init_exit_stack;
end.