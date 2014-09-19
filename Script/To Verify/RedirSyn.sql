/*

RedirSyn.sql
------------ 
Ultima revisione:
	r1.0 del 26/04/99

Descrizione: 
	Reindirizzamento dei sinonimi verso un'altro utente 

Parametri:
	Utente sovrasocietario verso il quale sono attualmente definiti i sinonimi
	Utente sovrasocietario verso il quale si vogliono reindirizzare i sinonimi
*/

ACCEPT utente_vecchio CHAR PROMPT 'Vecchio utente sovrasocietario verso il quale sono attualmente definiti i sinonimi: '
ACCEPT utente_nuovo   CHAR PROMPT 'Nuovo utente sovrasocietario verso il quale si vogliono reindirizzare i sinonimi : '

set echo off
set heading off
set feedback off
set space 0
set newpage 0
set pagesize 0
set verify off

spool c:\temp\~redir_syn.sql

select 'DROP SYNONYM '|| SYNONYM_NAME ||';'||CHR(10)|| 'CREATE SYNONYM '|| SYNONYM_NAME ||' FOR &utente_nuovo'||'.'|| SYNONYM_NAME ||';'
from 	USER_SYNONYMS
where 	TABLE_OWNER='&utente_vecchio'
/

spool off;

set space 1
set newpage 1
set pagesize 24  
set heading on
set feedback on
set echo on
set verify on

PAUSE PREMERE <INVIO> PER ESEGUIRE LO SCRIPT, <CTRL-C> PER TERMINARE

@c:\temp\~redir_syn.sql