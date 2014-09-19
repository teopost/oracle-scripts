/*
BIJU'S ORACLE PAGE 
    
triginfo.sql 
 
Purpose

Body of Trigger in parameter. Wild characters may be used (%) in the parameter list.Screen output saved at /tmp/triginfo.lst

Parameters

1. Trigger Owner (Wild character % may be used) 
2. Trigger Name (Wild character % may be used) 
Command Line

SQL> @triginfo scott %

The Script
*/
rem
rem Trigger text
rem 
rem Input : Trigger owner and name
rem
rem Biju Thomas
rem
set pages 0 feedback off lines 200 trims on echo off long 32000 verify off
spool c:\temp\triginfo.lst
select DESCRIPTION, trigger_body
from all_triggers
where owner like upper('&1')
and   trigger_name  like upper('&2')
/
spool off
set pages 24 feedback on lines 80 trims on verify on
prompt
prompt Output saved at c:\temp\triginfo.lst
prompt
Example Output
before_update_dept
before update of dname on dept for each row
begin
  if :old.dname = 'CORPORATE' and :old.deptno = 10 then
     :new.dname = 'CORPORATE';
  end if;
end;
