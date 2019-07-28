Unit runtime;

interface
function error_msg(num:byte):string;

implementation
uses misc;
const
     Err0to6:array[0..6] of string=(
     'Run-time error',
     'Invalid function number',
     'File not found',
     'Path not found',
     'Too many open files',
     'File access denied',
     'Invalid file handle');
     Err12='Invalid file access code';
     Err15to17:array[15..17] of string=(
     'Invalid drive number',
     'Cannot remove current directory',
     'Cannot rename across drives');
     Err100to106:array[100..106] of string=(
     'Disk read error',
     'Disk write error',
     'File not assigned',
     'File not open',
     'File not open for input',
     'File not open for output',
     'Invalid numeric format');
     Err200to207:array[200..207] of string=(
     'Division by zero',
     'Range check error',
     'Stack overflow error',
     'Heap overflow error',
     'Invalid pointer operation',
     'Floating point overflow',
     'Floating point underflow',
     'Invalid floating point operation');
     Err210to216:array[210..216] of string=(
     'Object not initialized',
     'Call to abstract method',
     'Stream registration error',
     'Collection index out of range',
     'Collection overflow error',
     'Arithmetic overflow error',
     'General protection fault');

function error_msg(num:byte):string;
 const uhead='Unknown RUN-TIME error';
       heady='RUN-TIME error(can`t ignore):';
begin
 error_msg:=uhead;
 if belongs(num,0,6)
 then error_msg:=heady+Err0to6[num]
 else if num=12
      then error_msg:=heady+Err12
      else if belongs(num,15,17)
           then error_msg:=heady+Err15to17[num]
           else if belongs(num,100,106)
                then error_msg:=heady+Err100to106[num]
                else if belongs(num,200,207)
                     then error_msg:=heady+Err200to207[num]
                     else if belongs(num,210,216)
                          then error_msg:=heady+Err210to216[num];
end;

end.
