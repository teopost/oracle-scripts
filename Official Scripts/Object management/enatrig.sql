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

spool ena_tr.sql
select 'spool report.lst ' from dual;
select 'alter trigger '||trigger_name ||' enable;' from user_triggers where status = 'DISABLED'
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
@ena_tr.sql
