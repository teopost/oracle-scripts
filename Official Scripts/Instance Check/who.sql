/*
 ===========================================================
 Filename...: who.sql
 Author.....: Stefano Teodorani
 Release....: 1.0 - 08-may-1998
 Description: Elenca tutti gli utenti esistenti
 Notes......: none
 ===========================================================
*/ 

SET PAGESIZE 555 line 1132
--column logon format a15
column SINTASSI format a40 heading 'COPY_THIS_TO_KILL [sid,serial#]'
column APPLICATIVO format a25
column NOME_UTENTE format a20
BREAK ON SCHEMA skip 1 on NOME_UTENTE
-- on " " skip 1

select 	'>> alter system kill session '''||sid||','||serial#||''';' SINTASSI ,
 decode(audsid,  userenv( 'SESSIONID' ),  '*' ,' ') " ",
        substr(username,1,10) SCHEMA, 
	osuser NOME_UTENTE, 
	process PROCESS,
	substr(program,1,25) APPLICATIVO, 
--	sid, serial#,
--	TO_CHAR(logon_time,'DD-MM HH:MM:SS') lOGON,
	SUBSTR(status,1,1)
from 	v$session
where 	username is not null
and     status != 'KILLED'
and sid =&1 or &1 is null
--and osuser like 'sara%'
order by " ", username, osuser
/


-- select distinct sid "My SID is:" from v$mystat;

-- select userenv('SESSIONID') "My AUSID is:" from dual;

