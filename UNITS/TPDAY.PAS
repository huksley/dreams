Unit TPDay;
interface
const WeekStr:array[0..6] of string[12]=
      ('Воскpесенье',
       'Понедельник',
       'Вторник',
       'Среда',
       'Четверг',
       'Пятница',
       'Суббота');
      MonthStr:array[1..12] of string[8]=
      ('Января',
       'Февраля',
       'Марта',
       'Апреля',
       'Мая',
       'Июня',
       'Июля',
       'Августа',
       'Сентября',
       'Октября',
       'Ноября',
       'Декабря');
function fulldate:string;
function date:string;
function time:string;
function systime:string;

implementation
Uses dos;

function tostr(a:longint):string;
var s:string;
begin
 str(a,s);
 tostr:=s;
end;


function fulldate:string;
 var yr,mn,dy,dw:word;
begin
 getdate(yr,mn,dy,dw);
 fulldate:=WeekStr[dw]+', '+tostr(dy)+' '+MonthStr[mn]+' '+tostr(yr);
end;

function date:string;
 var yr,mn,dy,dw:word;
begin
 getdate(yr,mn,dy,dw);
 date:=tostr(dy)+'-'+tostr(mn)+'-'+tostr(yr);
end;

function time:string;
 var hr,min,sec:word;
begin
 gettime(hr,min,sec,sec);
 time:=tostr(hr)+':'+tostr(min);
end;

function systime:string;
begin
 systime:=time+', '+{full}date;
end;
end.
