/*
BIJU'S ORACLE PAGE 
    
cr_trig.sql 
 
Purpose

Trigger creation script generated based on the trigger name passed in as paramter. Wild characters may be used (%) in the parameter list. Screen output saved at /tmp/crtrig.sql

Parameters

1. Trigger Owner (Wild character % may be used) 
2. Trigger Name (Wild character % may be used) 
Command Line

SQL> @cr_trig triggerowner triggername

The Script
*/
rem
rem Generate Trigger Creation DDL
rem 
rem Input : Trigger owner and Trigger name
rem
rem Biju Thomas
rem
set pages 0 feedback off lines 200 trims on echo off long 32000 verify off
spool c:\temp\crtrig.sql
column nl newline
select 'CREATE OR REPLACE TRIGGER', DESCRIPTION, trigger_body, '/' nl
from all_triggers
where owner like upper('&1')
and   trigger_name  like upper('&2')
/
spool off
set pages 24 feedback on lines 80 verify on
prompt
prompt Output saved at c:\temp\crtrig.sql
prompt
 