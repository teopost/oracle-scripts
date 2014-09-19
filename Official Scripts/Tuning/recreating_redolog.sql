select s.group#, s.sequence#, s.archived, s.status 
, substr( s.first_time, 4, 2 ) || ' ' 
|| substr( s.first_time, 10 ) first_time, f.member 
from v$log s, v$logfile f 
where s.group# = f.group# 
order by 2; 

GROUP# SEQUENCE# A STATUS FIRST_TIME MEMBER 
------ --------- - -------- ---------- -------------------- 
2 12150 Y INACTIVE 25 12:15:1 /orad/c22/log21c.dbf 
3 12151 Y INACTIVE 25 17:34:5 /orad/c21/log31c.dbf 
4 12152 Y INACTIVE 25 18:15:1 /orad/c22/log41c.dbf 
5 12153 Y INACTIVE 26 02:15:1 /orad/c21/log51c.dbf 
6 12154 Y INACTIVE 26 02:15:5 /orad/c22/log61c.dbf 
7 12155 Y INACTIVE 26 05:09:3 /orad/c05/log71c.log 
8 12156 Y INACTIVE 26 05:15:1 /orad/c04/log81c.log 
1 12157 N CURRENT 26 11:15:1 /orad/c21/log11c.dbf 

alter system switch logfile; 

goes to next group (in my example, group 1 is ACTIVE for a while, group 2 is CURRENT, others are INCATIVE) 

alter database drop logfile group 3; 

REM os: remove the file 
! rm /orad/c21/log31c.dbf 

alter database add logfile group 3 '/orad/c21/log31c.log' size 300M; 

same_select_as_before (I show you only 1 row) 

GROUP# SEQUENCE# A STATUS FIRST_TIME MEMBER 
------ --------- - ------- ---------- -------------------- 
3 0 Y UNUSED 01 00:00:0 /orad/c21/log31c.log 

REM (first_date has no meaning in the previous select for new group) 

alter system switch logfile; 

ecc..