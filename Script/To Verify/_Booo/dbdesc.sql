set heading on linesize 1500 pagesize 1000 termout on echo off feedback off verify off trims on

col Username format a20 heading 'UTENTE'
col BYTES_A format 999,999,999,999 HEADING 'SPAZIO|OCCUPATO'
col TOT_TABLESPACE format 999,999,999,999 HEADING 'TOTALE|SPAZIO' noprint
col TOTALE_TABLESPACE format 999,999,999,999 HEADING 'TOTALE|SPAZIO'
col PCT format 99.99 HEADING 'PCT'
col GRAPH format a30 HEADING 'GRAPH'
col Created format a11 HEADING 'DATA|CREAZIONE' 

compute sum of BYTES_A on report
break on report

spool %WINDIR%\temp\VisSpace.txt

select  a.Username,
        to_char(c.Created,'DD-Mon-YYYY') Created,
	a.bytes BYTES_A,
	sum(b.bytes) TOT_TABLESPACE,
	(a.bytes/sum(b.bytes))*100 PCT,
	substr(d.descrizione,1,60) DESCRIZIONE,
	substr(d.rif,1,30) RIFERIMENTO
from   DBA_TS_QUOTAS a,
       dba_data_files b,
       all_users c,
       dbdesc d
where  a.tablespace_name = b.tablespace_name 
and 	a.Username = c.username
and    a.tablespace_name = 'USER_DATA'
and 	a.username = d.utente (+)
group by a.Username, to_char(c.Created,'DD-Mon-YYYY'), a.bytes, substr(d.descrizione,1,60), substr(d.rif,1,30)
order by 5 desc
/

select 	sum(bytes) TOTALE_TABLESPACE
from    dba_data_files
where   tablespace_name = 'USER_DATA'
/
--clear compute
--clear breaks
spool off;
