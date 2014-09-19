/*
BIJU'S ORACLE PAGE 
    
cr_view.sql 
 
Purpose

View creation script generated based on the view name passed in as paramter. Wild characters may be used (%) in the parameter list. Screen output saved at /tmp/crview.sql

Parameters

1. View Owner (Wild character % may be used) 
2. View Name (Wild character % may be used) 
Command Line

SQL> @cr_view viewowner viewname

The Script
*/
rem
rem Generate view creation script
rem
rem Biju Thomas
rem 
rem Pass owner name and view name as parameters
rem
set heading off verify off feedback off arraysize 1 long 1000000 termout off 
set pages 0 lines 78 trims on
column vtext format a78 wrap
spool c:\temp\crview.sql 
select 'create view '||owner||'.'||view_name||' as ',text,';'  vtext
from   all_views 
where  owner like upper('&1')
and    view_name like upper('&2') 
/ 
spool off 
set termout on feedback on verify on heading on
prompt
prompt Output saved at c:\temp\crview.sql
prompt

 