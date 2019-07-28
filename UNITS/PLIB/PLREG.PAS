Unit plreg;

interface
uses strings;

const
      cERR_REGISTRY_SIZE = 256;
      cERR_UNKNOWN       = $FFFF;
      cERR_UNKNOWN_MESS  = 'Unknown error number';
var
      err_reg_mess : array[0..cERR_REGISTRY_SIZE-1] of pchar;
      err_reg_num  : array[0..cERR_REGISTRY_SIZE-1] of word;
      err_reg_size : word;

procedure init_err_registry;
procedure done_err_registry;

function find_err_message(errnum:word):pchar;
function register_error_message(errnum:word; message:string):integer;

implementation

function pack_pchar(s:string):pchar;
 var p:pchar;
begin
 getmem(p,length(s)+1);
 pack_pchar:=StrPCopy(p,s);
end;

procedure init_err_registry;
begin
 err_reg_size:=0;
end;
procedure done_err_registry;
 var a:integer;
begin
 for a:=0 to err_reg_size-1 do StrDispose(err_reg_mess[a]);
end;

function find_err_num(num:word):integer;
 var a:integer;
begin
 find_err_num:=-1;
 for a:=0 to err_reg_size-1 do
     if err_reg_num[a]=num then begin
                             find_err_num:=a;
                             exit;
                            end;
end;
function find_err_message;
 var i:integer;
begin
 i:=find_err_num(errnum);
 if i=-1
 then find_err_message:=err_reg_mess[find_err_num(cERR_UNKNOWN)]
 else find_err_message:=err_reg_mess[i];
end;
function register_error_message(errnum:word; message:string):integer;
begin
 if err_reg_size=cERR_REGISTRY_SIZE
 then begin
  writeln('can`t register more messages:',errnum);
  register_error_message:=-1
 end else begin
  err_reg_mess[err_reg_size]:=pack_pchar(message);
  err_reg_num[err_reg_size]:=errnum;
  register_error_message:=err_reg_size;
  inc(err_reg_size);
 end;
end;

begin
 init_err_registry;

 { unknown error }
 register_error_message(cERR_UNKNOWN,cERR_UNKNOWN_MESS);
 { standart runtime messages }
 register_error_message(0  ,'Run-time error'            );
 register_error_message(1  ,'Invalid function number'   );
 register_error_message(2  ,'File not found'            );
 register_error_message(3  ,'Path not found'            );
 register_error_message(4  ,'Too many open files'       );
 register_error_message(5  ,'File access denied'        );
 register_error_message(6  ,'Invalid file handle'       );
 register_error_message(12 ,'Invalid file access code'  );
 register_error_message(15 ,'Invalid drive number'      );
 register_error_message(16 ,'Cannot remove current directory');
 register_error_message(17 ,'Cannot rename across drives'    );
 register_error_message(100,'Disk read error'                );
 register_error_message(101,'Disk write error'               );
 register_error_message(102,'File not assigned'              );
 register_error_message(103,'File not open'                  );
 register_error_message(104,'File not open for input'        );
 register_error_message(105,'File not open for output'       );
 register_error_message(106,'Invalid numeric format'         );
 register_error_message(200,'Division by zero'               );
 register_error_message(201,'Range check error'              );
 register_error_message(202,'Stack overflow error'           );
 register_error_message(203,'Heap overflow error'            );
 register_error_message(204,'Invalid pointer operation'      );
 register_error_message(205,'Floating point overflow'        );
 register_error_message(206,'Floating point underflow'       );
 register_error_message(207,'Invalid floating point operation');
 register_error_message(210,'Object not initialized'          );
 register_error_message(211,'Call to abstract method'         );
 register_error_message(212,'Stream registration error'       );
 register_error_message(213,'Collection index out of range'   );
 register_error_message(214,'Collection overflow error'       );
 register_error_message(215,'Arithmetic overflow error'       );
 register_error_message(216,'General protection fault'        );
end.
