ttitle -
  center  'SGA Cache Hit Ratios' skip 2

set pagesize 60
set heading off
set termout off

col lib_hit     format        999.999 justify right
col dict_hit    format  999.999 justify right
col db_hit      format        999.999 justify right
col ss_share_mem  format      999.99  justify right
col ss_persit_mem format      999.99  justify right
col ss_avg_users_cursor format 999.99 justify right
col ss_avg_stmt_exe     format 999.99 justify right

col val2 new_val lib noprint
select 1-(sum(reloads)/sum(pins)) val2
from   v$librarycache
/
col val2 new_val dict noprint
select 1-(sum(getmisses)/sum(gets)) val2
from   v$rowcache
/
col val2 new_val phys_reads noprint
select value val2
from   v$sysstat
where  name = 'physical reads'
/
col val2 new_val log1_reads noprint
select value val2
from   v$sysstat
where  name = 'db block gets'
/
col val2 new_val log2_reads noprint
select value val2
from   v$sysstat
where  name = 'consistent gets'
/
col val2 new_val chr noprint
select 1-(&phys_reads / (&log1_reads + &log2_reads)) val2
from   dual
/

col val2 new_val avg_users_cursor noprint
col val3 new_val avg_stmts_exe    noprint
select sum(users_opening)/count(*) val2,
       sum(executions)/count(*)    val3
from   v$sqlarea
/

set termout on
set heading off

select  'Data Block Buffer Hit Ratio : '||&chr db_hit_ratio,
        'Shared SQL Pool                        ',
        '  Dictionary Hit Ratio      : '||&dict dict_hit,
        '  Shared SQL Buffers (Library Cache)                        ',
     '    Cache Hit Ratio         : '||&lib lib_hit,
        '    Avg. Users/Stmt   : '||
          &avg_users_cursor||'         ',
        '    Avg. Executes/Stmt      : '||
          &avg_stmts_exe||'            '
from    dual
/
