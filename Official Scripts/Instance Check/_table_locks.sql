set pagesize 50
set linesize 350
column "Pid - Tempo di Login" format a30
column "OS user - Oracle user" format a60
column tabella format a40
break on tabella skip1
prompt "Sessioni Bloccate/Bloccanti con oggetti"
select v.INST_ID "Istanza" ,
  to_char(b.spid,'999999') || ' - ' ||to_char(v.logon_time,'dd/mon/yyyy hh24:mi:ss') "Pid - Tempo di Login",
  substr(o.owner || '.' ||o.object_name,1,30) tabella,
  decode(l.xidusn+l.xidslot+l.xidsqn, 
  0,'In attesa ','Bloccata da ') "Stato",
  l.os_user_name || ' - ' ||
  ' alter system kill session '''||v.sid||','||to_char(v.serial#)||'''; ' "OS user - Comando di kill"
  from
    gv$locked_object l, all_objects o, gv$session v
    , gv$process b 
where
  l.INST_ID=v.INST_ID and
  l.object_id=o.object_id and 
  l.session_id=v.sid      and
  v.paddr = b.addr 
  order by 2,3,4;

prompt  
prompt Oggetti usati dalle transazioni correnti

break on owner skip1 
break on object_name skip1
select 	
	a.owner,
	a.object_name,
	sid,
	serial#,
	start_time,
	a.object_type 
from v$transaction t,
     v$session v,
     v$locked_object o,
     all_objects a
where t.ses_addr=v.saddr 
and o.session_id=v.sid 
and o.object_id=a.object_id
order by owner,object_name;
Prompt Sessioni attive
select count(*) from gv$session;
break on MACHINE skip
compute sum of CONTEGGIO on machine
Prompt Sessioni di utenti con troppe sessioni aperte
select decode(inst_id,1,'db1',2,'db2',3,'db3','boh') db,machine,count(*) CONTEGGIO
       from gv$session group by 1,inst_id,machine having count(*)>2 order by machine;

Prompt Sessioni delle macchine importanti
select decode(inst_id,1,'db1',2,'db2',3,'db3','boh') db,machine,count(*) CONTEGGIO
       from gv$session where machine in ('as1','as2','as3','iasform','db1','db2','db3','timmi')
       group by 1,inst_id,machine 
       order by machine;
