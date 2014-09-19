select * from migrazione_log where id > 2000;


SET PAGESIZE 255 line 132
--column logon format a15
column SINTASSI format a40 heading 'COPY_THIS_TO_KILL [sid,serial#]'
column APPLICATIVO format a25
column NOME_UTENTE format a20
BREAK ON SCHEMA skip 1 on NOME_UTENTE
-- on " " skip 1

select 	decode(audsid,  userenv( 'SESSIONID' ),  '*' ,' ') " ",
        substr(username,1,10) SCHEMA, 
	osuser NOME_UTENTE, 
	substr(program,1,25) APPLICATIVO, 
--	sid, serial#,
--	TO_CHAR(logon_time,'DD-MM HH:MM:SS') lOGON,
	SUBSTR(status,1,1)
from 	v$session
where 	username is not null
and     status != 'KILLED'
and     program like 'sqlplus@mazinga%'
order by " ", username, osuser
/

