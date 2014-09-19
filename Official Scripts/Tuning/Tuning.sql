spool tuning_stats.txt  
 
ttitle 'SYSTEM STATISTICS'  
 
select 'LIBRARY CACHE STATISTICS:' from dual;  
 
ttitle off  
 
select 'PINS - # of times an item in the library cache was executed - '||  
        sum(pins),  
       'RELOADS - # of library cache misses on execution steps - '|| 
        sum (reloads),  
       'RELOADS / PINS * 100 = '||round((sum(reloads) / sum(pins) *  
100),2)||'%' 
from    v$librarycache  
/  
 
prompt Increase memory until RELOADS is near 0 but watch out for  
prompt Paging/swapping 
prompt To increase library cache, increase SHARED_POOL_SIZE  
prompt  
prompt ** NOTE: Increasing SHARED_POOL_SIZE will increase the SGA size.  
prompt  
prompt Library Cache Misses indicate that the Shared Pool is not big  
prompt enough to hold the shared SQL area for all concurrently open cursors.  
prompt If you have no Library Cache misses (PINS = 0), you may get a small  
prompt increase in performance by setting CURSOR_SPACE_FOR_TIME = TRUE which  
prompt prevents ORACLE from deallocating a shared SQL area while an  
prompt application  
prompt cursor associated with it is open.  
prompt  
prompt For Multi-threaded server, add 1K to SHARED_POOL_SIZE per user.  
prompt  
prompt------------------------------------------------------------------------  
  
column xn1 format a50  
column xn2 format a50  
column xn3 format a50  
column xv1 new_value xxv1 noprint  
column xv2 new_value xxv2 noprint  
column xv3 new_value xxv3 noprint  
column d1  format a50  
column d2  format a50  
 
prompt HIT RATIO:  
prompt  
prompt Values Hit Ratio is calculated against:  
prompt  
 
select lpad(name,20,' ')||'  =  '||value xn1, value xv1  
from   v$sysstat  
where  name = 'db block gets'  
/  
 
select lpad(name,20,' ')||'  =  '||value xn2, value xv2   
from   v$sysstat  
where  name = 'consistent gets'  
/  
 
select lpad(name,20,' ')||'  =  '||value xn3, value xv3   
from   v$sysstat b  
where  name = 'physical reads'  
/  
 
set pages 60  
 
select 'Logical reads = db block gets + consistent gets ',  
        lpad ('Logical Reads = ',24,' ')||to_char(&xxv1+&xxv2) d1  
from    dual  
/  
 
select 'Hit Ratio = (logical reads - physical reads) / logical reads',  
        lpad('Hit Ratio = ',24,' ')||  
        round( (((&xxv2+&xxv1) - &xxv3) / (&xxv2+&xxv1))*100,2 )||'%' d2  
from    dual  
/  
 
prompt If the hit ratio is less than 60%-70%, increase the initialization  
prompt parameter DB_BLOCK_BUFFERS.  ** NOTE:  Increasing this parameter will  
prompt increase the SGA size.  
prompt  
prompt------------------------------------------------------------------------  
  
col name format a30  
col gets format 9,999,999  
col waits format 9,999,999  
 
prompt ROLLBACK CONTENTION STATISTICS:  
prompt  
  
prompt GETS - # of gets on the rollback segment header 
prompt WAITS - # of waits for the rollback segment header  
  
set head on;  
 
select name, waits, gets  
from   v$rollstat, v$rollname  
where  v$rollstat.usn = v$rollname.usn  
/  
 
set head off  
 
select 'The average of waits/gets is '||  
   round((sum(waits) / sum(gets)) * 100,2)||'%'  
From    v$rollstat  
/  
  
prompt  
prompt If the ratio of waits to gets is more than 1% or 2%, consider  
prompt creating more rollback segments  
prompt  
prompt Another way to gauge rollback contention is:  
prompt  
  
column xn1 format 9999999  
column xv1 new_value xxv1 noprint  
 
set head on  
 
select class, count  
from   v$waitstat  
where  class in ('system undo header', 'system undo block', 
                 'undo header',        'undo block'          )  
/  
 
set head off  
 
select 'Total requests = '||sum(count) xn1, sum(count) xv1  
from    v$waitstat  
/  
 
select 'Contention for system undo header = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from  v$waitstat  
where   class = 'system undo header'  
/  
 
select 'Contention for system undo block = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from    v$waitstat  
where   class = 'system undo block'  
/  
 
select 'Contention for undo header = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from    v$waitstat  
where   class = 'undo header'  
/  
 
select 'Contention for undo block = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from    v$waitstat  
where   class = 'undo block'  
/  
 
prompt  
prompt If the percentage for an area is more than 1% or 2%, consider  
prompt creating more rollback segments.  Note:  This value is usually very  
prompt small 
prompt and has been rounded to 4 places.  
prompt  
prompt------------------------------------------------------------------------  
  
prompt REDO CONTENTION STATISTICS:  
prompt  
prompt The following shows how often user processes had to wait for space in  
prompt the redo log buffer:  
  
select name||' = '||value  
from   v$sysstat  
where  name = 'redo log space requests'  
/  
 
prompt  
prompt This value should be near 0.  If this value increments consistently,  
prompt processes have had to wait for space in the redo buffer.  If this  
prompt condition exists over time, increase the size of LOG_BUFFER in the  
prompt init.ora file in increments of 5% until the value nears 0.  
prompt ** NOTE: increasing the LOG_BUFFER value will increase total SGA size.  
prompt  
prompt -----------------------------------------------------------------------  
  
  
col name format a15  
col gets format 9999999  
col misses format 9999999  
col immediate_gets heading 'IMMED GETS' format 9999999  
col immediate_misses heading 'IMMED MISS' format 9999999  
col sleeps format 999999  
 
prompt LATCH CONTENTION:  
prompt  
prompt GETS - # of successful willing-to-wait requests for a latch  
prompt MISSES - # of times an initial willing-to-wait request was unsuccessful  
prompt IMMEDIATE_GETS - # of successful immediate requests for each latch  
prompt IMMEDIATE_MISSES = # of unsuccessful immediate requests for each latch  
prompt SLEEPS - # of times a process waited and requests a latch after an  
prompt          initial willing-to-wait request  
prompt  
prompt If the latch requested with a willing-to-wait request is not  
prompt available, the requesting process waits a short time and requests  
prompt again.  
prompt If the latch requested with an immediate request is not available,  
prompt the requesting process does not wait, but continues processing  
prompt  
  
set head on  
 
select name,          gets,              misses,  
       immediate_gets,  immediate_misses,  sleeps  
from   v$latch  
where  name in ('redo allocation',  'redo copy')  
/  
 
set head off  
 
select 'Ratio of MISSES to GETS: '||  
        round((sum(misses)/(sum(gets)+0.00000000001) * 100),2)||'%'  
from    v$latch  
where   name in ('redo allocation',  'redo copy')  
/  
 
select 'Ratio of IMMEDIATE_MISSES to IMMEDIATE_GETS: '||  
        round((sum(immediate_misses)/  
       (sum(immediate_misses+immediate_gets)+0.00000000001) * 100),2)||'%'  
from    v$latch  
where   name in ('redo allocation',  'redo copy')  
/  
 
prompt  
prompt If either ratio exceeds 1%, performance will be affected.  
prompt  
prompt Decreasing the size of LOG_SMALL_ENTRY_MAX_SIZE reduces the number of  
prompt processes copying information on the redo allocation latch.  
prompt  
prompt Increasing the size of LOG_SIMULTANEOUS_COPIES will reduce contention  
prompt for redo copy latches.  
  
rem  
rem This shows the library cache reloads  
rem  
 
set head on  
 
prompt  
prompt------------------------------------------------------------------------  
  
prompt  
prompt Look at gethitratio and pinhit ratio  
prompt  
prompt GETHITRATIO is number of GETHTS/GETS  
prompt PINHIT RATIO is number of PINHITS/PINS - number close to 1 indicates  
prompt that most objects requested for pinning have been cached.  Pay close  
prompt attention to PINHIT RATIO.  
prompt  
  
column namespace    format a20   heading 'NAME'  
column gets         format 99999999 heading 'GETS'  
column gethits      format 99999999 heading 'GETHITS'  
column gethitratio  format 999.99   heading 'GET HIT|RATIO'  
column pins         format 9999999  heading 'PINHITS'  
column pinhitratio  format 999.99   heading 'PIN HIT|RATIO'  
 
select namespace,    gets,  gethits,  
       gethitratio,  pins,  pinhitratio  
from   v$librarycache  
/  
 
rem  
rem  
rem This looks at the dictionary cache miss rate  
rem  
 
prompt  
prompt------------------------------------------------------------------------  
  
prompt THE DATA DICTIONARY CACHE:  
prompt  
prompt  
prompt Consider keeping this below 5% to keep the data dictionary cache in  
prompt the SGA.  Up the SHARED_POOL_SIZE to improve this statistic. **NOTE:  
prompt increasing the SHARED_POOL_SIZE will increase the SGA.  
prompt  
 
column dictcache format 999.99 heading 'Dictionary Cache | Ratio %'  
 
select sum(getmisses) / (sum(gets)+0.00000000001) * 100 dictcache  
from   v$rowcache  
/  
 
prompt  
prompt------------------------------------------------------------------------  
  
prompt  
prompt SYSTEM EVENTS:  
prompt  
prompt Not sure of the value of this section yet but it looks interesting.  
prompt  
 
col event format a37 heading 'Event'  
col total_waits format 99999999 heading 'Total|Waits'  
col time_waited format 9999999999 heading 'Time Wait|In Hndrds'  
col total_timeouts format 999999 heading 'Timeout'  
col average_wait heading 'Average|Time' format 999999.999  
 
set pages 999  
 
select *  
from   v$system_event  
/  
  
prompt  
prompt------------------------------------------------------------------------  
  
rem  
rem  
rem This looks at the sga area breakdown  
rem  
 
prompt THE SGA AREA ALLOCATION:  
prompt  
prompt  
prompt This shows the allocation of SGA storage.  Examine this before and  
prompt after making changes in the INIT.ORA file which will impact the SGA.  
prompt  
 
col name format a40  
 
select name, bytes  
from   v$sgastat  
/  
 
set head off  
 
select 'total of SGA                            '||sum(bytes)  
from    v$sgastat  
/ 
 
prompt  
prompt------------------------------------------------------------------------  
  
rem  
rem Displays all the base session statistics  
rem  
 
set head on  
set pagesize 110  
 
column name        format a55            heading 'Statistic Name'  
column value       format 9,999,999,999  heading 'Result'  
column statistic#  format 9999           heading 'Stat#' 
 
ttitle center 'Instance Statistics' skip 2  
 
prompt  
prompt Below is a dump of the core Instance Statistics that are greater than0.  
prompt Although there are a great many statistics listed, the ones of greatest  
prompt value are displayed in other formats throughout this report.  Of   
prompt interest here are the values for:  
prompt  
prompt  cumulative logons  
prompt(# of actual connections to the DB since last startup - good  
prompt  volume-of-use statistic)  
prompt  
prompt  #93  table fetch continued row  
prompt  (# of chained rows - will be higher if there are a lot of long fields   
prompt  if the value goes up over time, it is a good signaller of general   
prompt  database fragmentation)  
prompt  
  
select statistic#,  name,  value  
from   v$sysstat  
where  value > 0  
/  
 
prompt  
prompt -----------------------------------------------------------------------  
  
set pages 66;  
set space 3;  
set heading on;  
 
prompt  
prompt Parse Ratio usually falls between 1.15 and 1.45.  If it is higher, then  
prompt it is usually a sign of poorly written Pro* programs or unoptimized  
prompt SQL*Forms applications.  
prompt  
prompt Recursive Call Ratio will usually be between  
prompt  
prompt   7.0 - 10.0 for tuned production systems  
prompt  10.0 - 14.5 for tuned development systems  
prompt  
prompt Buffer Hit Ratio is dependent upon RDBMS size, SGA size and  
prompt the types of applications being processed.  This shows the %-age  
prompt of logical reads from the SGA as opposed to total reads - the  
prompt figure should be as high as possible.  The hit ratio can be raised  
prompt by increasing DB_BUFFERS, which increases SGA size.  By turning on  
prompt the "Virtual Buffer Manager" (db_block_lru_statistics = TRUE and  
prompt db_block_lru_extended_statistics = TRUE in the init.ora parameters),  
prompt you can determine how many extra hits you would get from memory as  
prompt opposed to physical I/O from disk.  **NOTE:  Turning these on will  
prompt impact performance.  One shift of statistics gathering should be enough  
prompt to get the required information.  
prompt  
  
ttitle left 'Ratios for this Instance' skip 2  
 
column pcc   heading 'Parse|Ratio'       format 99.99  
column rcc   heading 'Recsv|Cursr'       format 99.99  
column hr    heading 'Buffer|Ratio'      format 999,999,999.999  
column rwr   heading 'Rd/Wr|Ratio'       format 999,999.9  
column bpfts heading 'Blks per|Full TS'  format 999,999 
 
REM Modified for O7.1 to reverse 'cumulative opened cursors' to  
REM 'opened cursors cumulative'  
REM was:sum(decode(a.name,'cumulative opened cursors',value, .00000000001))  
REM pcc,  
REM and:sum(decode(a.name,'cumulative opened cursors',value,.00000000001))  
REM rcc,  
 
select sum(decode(a.name,'parse count',value,0)) /  
       sum(decode(a.name,'opened cursors cumulative',value,.00000000001)) pcc,  
       sum(decode(a.name,'recursive calls',value,0)) /  
       sum(decode(a.name,'opened cursors cumulative',value,.00000000001)) rcc,  
       (1-(sum(decode(a.name,'physical reads',value,0)) /  
       sum(decode(a.name,'db block gets',value,.00000000001)) +  
  sum(decode(a.name,'consistent gets',value,0))) * (-1)) hr,  
       sum(decode(a.name,'physical reads',value,0)) /  
       sum(decode(a.name,'physical writes',value,.00000000001)) rwr,  
       (sum(decode(a.name,'table scan blocks gotten',value,0)) -  
       sum(decode(a.name,'table scans (short tables)',value,0)) * 4) /  
       sum(decode(a.name,'table scans (long tables)',value,.00000000001))  
bpfts  
from   v$sysstat a  
/  
 
prompt  
prompt -----------------------------------------------------------------  
prompt This looks at overall i/o activity against individual  
prompt files within a tablespace  
prompt  
prompt Look for a mismatch across disk drives in terms of I/O  
prompt  
prompt Also, examine the Blocks per Read Ratio for heavily accessed  
prompt TSs - if this value is significantly above 1 then you may have  
prompt full tablescans occurring (with multi-block I/O)  
prompt  
prompt If activity on the files is unbalanced, move files around to balance  
prompt the load.  Should see an approximately even set of numbers across files  
prompt  
  
set pagesize 100;  
set space 1  
 
column pbr       format 99999999  heading 'Physical|Blk Read'  
column pbw       format 999999    heading 'Physical|Blks Wrtn'  
column pyr       format 999999    heading 'Physical|Reads'  
column readtim   format 99999999  heading 'Read|Time'  
column name      format a40       heading 'DataFile Name'  
column writetim  format 99999999  heading 'Write|Time'  
 
ttitle center 'Tablespace Report' skip 2  
 
compute sum of f.phyblkrd, f.phyblkwrt on report  
 
select fs.name name,  f.phyblkrd pbr,  f.phyblkwrt pbw, 
       f.readtim,     f.writetim  
from   v$filestat f, v$datafile fs  
where  f.file#  =  fs.file#  
order  by fs.name  
/  
 
prompt  
prompt -----------------------------------------------------------------  
  
prompt GENERATING WAIT STATISTICS:  
prompt  
prompt This will show wait stats for certain kernel instances.  This  
prompt may show the need for additional rbs, wait lists, db_buffers  
prompt  
 ttitle center 'Wait Statistics for the Instance' skip 2  
 
column class  heading 'Class Type'  
column count  heading 'Times Waited'  format 99,999,999 
column time   heading 'Total Times'   format 99,999,999  
 
select class,  count,  time  
from   v$waitstat  
where  count > 0  
order  by class  
/  
 
prompt  
prompt Look at the wait statistics generated above (if any). They will  
prompt tell you where there is contention in the system.  There will  
prompt usually be some contention in any system - but if the ratio of  
prompt waits for a particular operation starts to rise, you may need to  
prompt add additional resource, such as more database buffers, log buffers,  
prompt or rollback segments  
prompt  
prompt -----------------------------------------------------------------  
  
prompt ROLLBACK STATISTICS:  
prompt  
  
ttitle off;  
 
set linesize 80  
 
column extents    format 999        heading 'Extents'  
column rssize     format 999,999,999  heading 'Size in|Bytes'  
column optsize    format 999,999,999  heading 'Optimal|Size'  
column hwmsize    format 99,999,999   heading 'High Water|Mark'  
column shrinks    format 9,999        heading 'Num of|Shrinks'  
column wraps      format 9,999        heading 'Num of|Wraps'  
column extends    format 999,999      heading 'Num of|Extends'  
column aveactive  format 999,999,999  heading 'Average size|Active Extents'  
column rownum noprint  
 
select rssize,    optsize,  hwmsize,  
       shrinks,   wraps,    extends,  aveactive  
from   v$rollstat  
order  by rownum  
/  
 
prompt  
prompt -----------------------------------------------------------------  
  
set linesize 80  
 
break on report  
 
compute sum of gets waits writes on report  
 
ttitle center 'Rollback Statistics' skip 2  
 
select rownum,  extents,  rssize,  
       xacts,   gets,     waits,   writes  
from   v$rollstat  
order  by rownum  
/  
 
ttitle off  
 
set heading off  
 
prompt  
prompt -----------------------------------------------------------------  
  
prompt  
prompt SORT AREA SIZE VALUES:  
prompt  
prompt To make best use of sort memory, the initial extent of your Users  
prompt sort-work Tablespace should be sufficient to hold at least one sort  
prompt run from memory to reduce dynamic space allocation.  If you are getting  
prompt a high ratio of disk sorts as opposed to memory sorts, setting  
prompt sort_area_retained_size = 0 in init.ora will force the sort area to be  
prompt released immediately after a sort finishes.  
prompt  
 
column value format 999,999,999  
 
select 'INIT.ORA sort_area_size: '||value  
from    v$parameter  
where   name like 'sort_area_size' 
/ 
  
select a.name,  value  
from   v$statname a,  v$sysstat  
where  a.statistic#  =   v$sysstat.statistic#  
and    a.name        in ('sorts (disk)', 'sorts (memory)', 'sorts (rows)')  
/  
 
prompt  
prompt -----------------------------------------------------------------  
  
set heading on  
set space 2  
 
prompt  
prompt This looks at Tablespace Sizing - Total bytes and free bytes  
prompt  
 
ttitle center 'Tablespace Sizing Information' Skip 2  
 
column tablespace_name  format a30            heading 'TS Name'  
column sbytes           format 9,999,999,999  heading 'Total Bytes'  
column fbytes           format 9,999,999,999  heading 'Free Bytes'  
column kount            format 999            heading 'Ext'  
 
compute sum of fbytes on tablespace_name  
compute sum of sbytes on tablespace_name  
compute sum of sbytes on report  
compute sum of fbytes on report  
 
break on report  
 
select a.tablespace_name,    a.bytes sbytes,  
       sum(b.bytes) fbytes,  count(*) kount  
from   dba_data_files a,  dba_free_space b  
where  a.file_id  =  b.file_id  
group  by a.tablespace_name, a.bytes  
order  by a.tablespace_name  
/  
 
set linesize 80  
 
prompt  
prompt A large number of Free Chunks indicates that the tablespace may need  
prompt to be defragmented and compressed.  
prompt  
prompt -----------------------------------------------------------------  
  
set heading off  
 
ttitle off  
 
column value format 99,999,999,999  
 
select 'Total Physical Reads', value  
from    v$sysstat  
where   statistic# = 39  
/  
 
prompt  
prompt If you can significantly reduce physical reads by adding incremental  
prompt data buffers...do it.  To determine whether adding data buffers will  
prompt help, set db_block_lru_statistics = TRUE and  
prompt db_block_lru_extended_statistics = TRUE in the init.ora parameters.  
prompt You can determine how many extra hits you would get from memory as  
prompt opposed to physical I/O from disk.  **NOTE:  Turning these on will  
prompt impact performance.  One shift of statistics gathering should be enough  
prompt to get the required information.  
prompt  
  
set heading on  
 
clear computes  
 
ttitle off  
 
prompt  
prompt -----------------------------------------------------------------  
prompt CHECKING FOR FRAGMENTED DATABASE OBJECTS:  
prompt  
prompt Fragmentation report - If number of extents is approaching Maxextents,  
prompt it is time to defragment the table.  
prompt  
 
column owner  noprint  new_value  owner_var  
column segment_name  format a30          heading 'Object Name'  
column segment_type  format a9           heading 'Table/Indx'  
column sum(bytes)    format 999,999,999  heading 'Bytes Used'  
column count(*)      format 999          heading 'No.'  
 
break on owner skip page 2  
 
ttitle center 'Table Fragmentation Report' skip 2 -  
       left 'creator: ' owner_var skip 2  
 
select a.owner,     segment_name,  segment_type,  
    sum(bytes),  max_extents,   count(*)  
from   dba_extents a,  dba_tables b  
where  segment_name  =  b.table_name  
having count(*) > 3  
group  by a.owner, segment_name, segment_type, max_extents  
order  by a.owner, segment_name, segment_type, max_extents  
/  
 
ttitle center 'Index Fragmentation Report' skip 2 -  
  left 'creator: ' owner_var skip 2  
 
select a.owner,     segment_name,  segment_type, 
       sum(bytes),  max_extents,   count(*)  
from   dba_extents a, dba_indexes b  
where  segment_name = index_name  
having count(*) > 3  
group  by a.owner, segment_name, segment_type, max_extents  
order  by a.owner, segment_name, segment_type, max_extents  
/  
  
prompt  
prompt -----------------------------------------------------------------  
  
spool off 