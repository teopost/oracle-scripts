#per attivare trucco 1 (indifferentemente dalle statistiche)
alter system set "_unnest_subquery" = false scope = SPFILE sid='ORCL';
alter system set optimyzer = CHOOSE scope = SPFILE sid='ORCL';

#trucco 2
optimizer_index_cost_adj=100 (ridurlo a 50)



# Nella 10 ritorna i param nascosti
SELECT x.ksppinm NAME,
y.ksppstvl VALUE,
ksppdesc DESCRIPTION
FROM x$ksppi x, sys.x$ksppcv y
WHERE x.inst_id = userenv('Instance')
AND y.inst_id = userenv('Instance')
AND x.indx = y.indx
AND SUBSTR(x.ksppinm,1,1) = '_'
ORDER BY 1;


#trigger che scatta in fase di logon
CREATE OR REPLACE TRIGGER SESS_TRACE
 AFTER LOGON  ON DATABASE
DECLARE
  curr_sid         number;
  curr_terminal    varchar2(16);
  curr_PROGRAM     varchar2(64);
  curr_USER        varchar2(30);
BEGIN
select distinct a.sid, a.terminal, a.program , a.username
into curr_sid, curr_terminal, curr_program , curr_user
from v$session a
where  a.audsid   = (select sys_context ('USERENV','SESSIONID') from dual);
if (curr_USER = 'MARZO' or curr_USER = 'CLKANA')  then
  execute immediate 'alter session set sql_trace=TRUE';
end if;
 EXCEPTION
 WHEN OTHERS THEN 
   NULL;
END;
/


How can I find what the values are for the hidden (underscore) parameters ?

--------------------------------------------------------------------------------

Author's name: Connor McDonald 
Author's Email: connor_mcdonald@yahoo.com
 Date written: July 18, 2001
Oracle version(s): 8.0+
 
How can I find what the values are for the hidden (underscore) parameters ? 

Back to index of questions


--------------------------------------------------------------------------------

In trying to hunt down hidden parameters, we start by looking at the V$PARAMETER table to see where it sources its information from

SQL> select VIEW_DEFINITION 
  2  from v$fixed_view_definition
  3  where view_name = 'V$PARAMETER';

select  NUM , NAME , TYPE , VALUE , ISDEFAULT , ISSES_MODIFIABLE , 
        ISSYS_MODIFIABLE , ISMODIFIED , ISADJUSTED , DESCRIPTION 
from GV$PARAMETER where inst_id = USERENV('Instance')

So lets try that again - this time GV$PARAMETER (the consolidated view of parameters across all instances)

SQL> select VIEW_DEFINITION 
  2  from v$fixed_view_definition
  3  where view_name = 'GV$PARAMETER';

select x.inst_id,x.indx+1,ksppinm,ksppity,ksppstvl,ksppstdf,  
       decode(bitand(ksppiflg/256,1),1,'TRUE','FALSE'),
       decode(bitand(ksppiflg/65536,3),1,'IMMEDIATE',2,'DEFERRED',3,'IMMEDIATE','FALSE'),  
       decode(bitand(ksppstvf,7),1,'MODIFIED',4,'SYSTEM_MOD','FALSE'),  
       decode(bitand(ksppstvf,2),2,'TRUE','FALSE'),  
       ksppdesc 
from   x$ksppi x, 
       x$ksppcv y 
where (x.indx = y.indx) 
and  (translate(ksppinm,'_','#') not like '#%' 
or   (translate(ksppinm,'_','#') like '#%'and ksppstdf = 'FALSE'))

From this output, its relatively straight forward to generate a query to list the hidden parameters and their descriptions 

select KSPPINM  name,
       KSPPDESC description
from   X$KSPPI
where  substr(KSPPINM,1,1) = '_'

which of course will only work as SYS. I have not included the values because whilst the hidden parameters have an associated entry in X$KSPPCV, this "value" is often ZERO, which is not necessarily the value actually in use by the instance, so interpreting them should take this into consideration. Similarly in OPS environments, you can restrict this for a particular instance in the same way that V$PARAMETER does 


SELECT KSPFTCTXPN, KSPPINM, KSPPITY, KSPFTCTXVL, 
KSPFTCTXDF, KSPPIFLG, KSPFTCTXVF 
FROM X$KSPPI X, X$KSPPCV2 Y 
WHERE (X.INDX+1) = KSPFTCTXPN
and KSPPINM like '_unnest%' ;