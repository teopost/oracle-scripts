/**********************************************************************
 *** RDBMS		    : Oracle
 *** Autore		    : Stefano Teodorani
 *** Versione	    : 1.0 - 10-dec-201 
 *** Descrizione	: Disable foreign-key constraints
 ******************************************************************************/
set echo off
set heading off
set feedback off
set space 0
set newpage 0
set pagesize 0
set termout off
spool dis_fk.sql
select 'spool report.lst ' from dual;
select 'alter table '||table_name ||' disable constraint '|| chr(10) || constraint_name|| ';'
from user_constraints
where constraint_type ='R'
and status = 'ENABLED'
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
@dis_fk.sql
