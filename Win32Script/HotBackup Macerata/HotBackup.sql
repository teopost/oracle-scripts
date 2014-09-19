column dummy noprint 

DEFINE backup_dir = 'c:\temp' 

set trimspool on
set linesize 500
set termout off
set echo off
set pagesize 0
set heading off
set verify off
set feedback off

whenever SQLERROR exit 1


spool backup_script.sql

select 'set echo on' from dual;

select 'spool backup_script.log' from dual;

select 'connect internal@orcl' from dual;

select ts# dummy,
       0 dummy,
       'host echo *** Inizio Backup Tablespace :' || name 
from sys.ts$
where online$ != 3
union
select ts# dummy,
       1 dummy,
       'alter tablespace ' || name || ' begin backup;'
from sys.ts$
where online$ != 3
union
select	f.ts#,
	2,
       'host ocopy '||d.name||' &&backup_dir'
from sys.file$ f,
     v$datafile d
where f.file# = d.file#
union
select ts#,
       3,
       'alter tablespace ' || name || ' end backup;'
FROM sys.ts$
where online$ != 3
union
select ts#,
       4,
       '--'
FROM sys.ts$
where online$ != 3
order by 1, 2
/


select 'prompt *** Inizio Backup Control file' from dual;
SELECT 'alter database backup controlfile to ''&&backup_dir\control.ctl'' reuse;' FROM dual;
SELECT 'alter database backup controlfile to trace;' FROM dual;
SELECT 'alter system switch logfile;' FROM dual;
SELECT 'alter system archive log stop;' FROM dual;

select 'host copy '|| member || '  &&backup_dir' from v$logfile;


select 'host copy ' || trim(replace( replace(pd.value, 'location', ' '), '=', ' ')) || '\*.arc &&backup_dir'
from v$parameter pd
where pd.name = 'log_archive_dest_1';

select 'host del ' || trim(replace( replace(pd.value, 'location', ' '), '=', ' ')) || '\*.arc '
from v$parameter pd
where pd.name = 'log_archive_dest_1';

SELECT 'alter system archive log start;' FROM dual;

select 'spool off' from dual;

select 'exit' FROM dual;


spool off

exit