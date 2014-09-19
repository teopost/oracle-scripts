REM
REM DBAToolZ NOTE:
REM	This script was obtained from DBAToolZ.com
REM	It's configured to work with SQL Directory (SQLDIR).
REM	SQLDIR is a utility that allows easy organization and
REM	execution of SQL*Plus scripts using user-friendly menu.
REM	Visit DBAToolZ.com for more details and free SQL scripts.
REM
REM 
REM File:
REM 	u_tab_sqlldr_ctl.sql
REM
REM <SQLDIR_GRP>TAB UTIL</SQLDIR_GRP>
REM 
REM Author:
REM 	Vitaliy Mogilevskiy 
REM	VMOGILEV
REM	(vit100gain@earthlink.net)
REM 
REM Purpose:
REM	<SQLDIR_TXT>
REM	builds SQL*Loader control file for a table
REM	</SQLDIR_TXT>
REM	
REM Usage:
REM	u_tab_sqlldr_ctl.sql
REM 
REM Example:
REM	u_tab_sqlldr_ctl.sql
REM
REM
REM History:
REM	08-01-1998	VMOGILEV	Created
REM
REM

set feedback off
set verify off

drop table select_text;

create table select_text (
text    varchar2(2000)
);

accept 1 prompt "Enter Table Name:"
accept 2 prompt "Enter Table Owner:"

declare
 cursor cur IS
   select    owner
   ,         table_name
   ,         column_name
   ,         decode(data_type,
                 'NUMBER','decimal external',
                 'DATE'  ,'date (11)'
                         ,'char ('||DATA_LENGTH||')') data_type
   ,         column_id
   from      dba_tab_columns
   where     table_name = upper('&&1')
   and       owner      = upper('&&2')
   order by  column_id;

   l_curr_line       VARCHAR2(2000);
   l_owner           sys.dba_tables.owner%TYPE;
   l_table_name      sys.dba_tables.table_name%TYPE;
begin
   l_curr_line := '
LOAD DATA
REPLACE
INTO TABLE ';
   select   owner, table_name
   into     l_owner, l_table_name
   from     dba_tables
   where    table_name = upper('&&1')
   and      owner      = upper('&&2');
   l_curr_line := l_curr_line||l_owner||'.'||l_table_name||'   
FIELDS TERMINATED BY '||''''||','||''''||'
OPTIONALLY ENCLOSED BY '||''''||'"'||''''||'
TRAILING NULLCOLS
 (';
   for rec in cur loop
    if rec.column_id = 1 then
      l_curr_line := l_curr_line||'
      '||rpad(rec.column_name,35)||rec.data_type;
    else
      l_curr_line := l_curr_line||'
,     '||rpad(rec.column_name,35)||rec.data_type;
    end if;
   end loop;
  l_curr_line := l_curr_line||')';
  insert into select_text values(l_curr_line);
  commit;
end;
/

set pages 900
set lines 80
col text format a80
set head off
set term off
set trimspool on

spool select.tmp

select * from select_text;

spool off
set term on

ed select.tmp
