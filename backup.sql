rem -----------------------------------------------------------------------
rem Filename:   backup.sql
rem Purpose:    Generate script to do a simple on-line database backup.
rem Notes:      Adjust the copy_cmnd and copy_dest variables and run from 
rem             sqlplus. Uncomment last few lines to do the actual backup.
rem Author:     Frank Naude, Oracle FAQ
rem -----------------------------------------------------------------------

set serveroutput on
set trimspool on
set line 500
set head off
set feed off

spool backup.cmd

declare
  copy_cmnd constant varchar2(30) := 'cp';       -- Use "ocopy" for NT
  copy_dest constant varchar2(30) := '/backup/'; -- C:\BACKUP\ for NT

  dbname  varchar2(30);
  logmode varchar2(30);
begin
  select name, log_mode
  into   dbname, logmode
  from   sys.v_$database;

  if logmode <> 'ARCHIVELOG' then
     raise_application_error(-20000, 
                     'ERROR: Database must be in ARCHIVELOG mode!!!');
     return;
  end if;

  dbms_output.put_line('spool backup.'||dbname||'.'||
                       to_char(sysdate, 'ddMonyy')||'.log');

  -- Loop through tablespaces
  for c1 in (select tablespace_name ts
             from   sys.dba_tablespaces)
  loop
    dbms_output.put_line('alter tablespace '||c1.ts||' begin backup;');
    -- Loop through tablespaces' data files
    for c2 in (select file_name fil
               from   sys.dba_data_files
               where  tablespace_name = c1.ts)
    loop
      dbms_output.put_line('!'||copy_cmnd||' '||c2.fil||' '||copy_dest);
    end loop;

    dbms_output.put_line('alter tablespace '||c1.ts||' end backup;');
  end loop;

  -- Backup controlfile and switch logfiles
  dbms_output.put_line('alter database backup controlfile to trace;');
  dbms_output.put_line('alter database backup controlfile to '||''''||
                       copy_dest||'control.'||dbname||'.'||
                       to_char(sysdate,'DDMonYYHH24MI')||''''||';');
  dbms_output.put_line('alter system switch logfile;');
  dbms_output.put_line('spool off');
end;
/

spool off

set head on
set feed on
set serveroutput off

-- Unremark/uncomment the following line to run the backup script
-- @backup.cmd
-- exit

