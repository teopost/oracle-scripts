/**********************************************************************
                
 **********************************************************************
 *** Modulo		: ------
 *** RDBMS		: Oracle
 *** Autore		: 
 *** Versione	: 
 *** Descrizione	: Script per la riabilitazione dei constraints 
 ******************************************************************************/
set echo off
set heading off
set feedback off
set termout off
set space 0
set newpage 0
set pagesize 0
set verify off

spool ena_fk.sql
select 'spool report.lst ' from dual;
select 'alter table '||table_name ||' enable constraint '|| chr(10) || constraint_name|| ';'
from user_constraints
where constraint_type ='R'
and status = 'DISABLED'
/
select 'spool off ;' from dual;
spool off
set space 1
set newpage 1
set pagesize 24  
set heading on
set feedback on
set echo on
set termout on
set verify on
@ena_fk.sql
