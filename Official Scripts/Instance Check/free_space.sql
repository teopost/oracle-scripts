/*
 ===========================================================
 Filename...: user_space.sql
 Author.....: Stefano Teodorani
 Release....: 1.0 - 08-may-1998
 Description: Mostra lo spazio occupato e disponibile per utente
 Notes......: none
 ===========================================================
*/ 

set heading on linesize 500 pagesize 1000 termout on echo off feedback off verify off trims on

col Username format a20 heading 'UTENTE'
col BYTES_A format 999,999,999,999 HEADING 'SPAZIO|OCCUPATO'
col TOT_TABLESPACE format 999,999,999,999 HEADING 'TOTALE|SPAZIO' noprint
col TOTALE_TABLESPACE format 999,999,999,999 HEADING 'TOTALE|SPAZIO'
col PCT format 99.99 HEADING 'PCT'
col GRAPH format a30 HEADING 'GRAPH'
col Created format a11 HEADING 'DATA|CREAZIONE' 

compute sum of BYTES_A on report
compute sum of BYTES_A on TABLESPACE

break on report
break ON TABLESPACE

spool %WINDIR%\temp\VisSpace.txt

select  
    a.Username,
    a.tablespace_name TABLESPACE,
    to_char(c.Created,'DD-Mon-YYYY') CREATED,
	a.bytes BYTES_A,
	sum(b.bytes) TOT_TABLESPACE,
	(a.bytes/sum(b.bytes))*100 PCT
from
    dba_ts_quotas  a,
    dba_data_files b,
    all_users      c
where
    a.tablespace_name = b.tablespace_name 
and a.Username = c.username
and a.tablespace_name  NOT in ('SYSTEM','RBS','TEMP','TOOLS','INDX')
group by 
    a.Username,  
    a.tablespace_name, 
    to_char(c.Created,'DD-Mon-YYYY'), a.bytes
order by 5 desc
;

select     
    tablespace_name, 
    sum(bytes) TOTALE_TABLESPACE
from
    dba_data_files
where   
    tablespace_name NOT in ('SYSTEM','RBS','TEMP','TOOLS','INDX')
group by 
    tablespace_name
/

spool off;
