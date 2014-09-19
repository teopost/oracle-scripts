SET ECHO off  
REM NAME:   TFSLATCH.SQL  
REM USAGE:"@path/tfslatch"  
REM ------------------------------------------------------------------------ 
REM AUTHOR:   
REM    Virag Saksena, Craig A. Shallahamer, Oracle US       
REM    (c)1994 Oracle Corporation       
REM ------------------------------------------------------------------------  
REM Main text of script follows 

ttitle -  
   center   'Latch Contention Report'  skip 3  
  
col name form A25  
col gets form 999,999,999  
col misses form 999.99  
col spins form 999.99  
col igets form 999,999,999  
col imisses form 999.99  
  
select name,gets,misses*100/decode(gets,0,1,gets) misses,  
spin_gets*100/decode(misses,0,1,misses) spins, immediate_gets igets  
,immediate_misses*100/decode(immediate_gets,0,1,immediate_gets) imisses  
from v$latch order by gets + immediate_gets  
/   

SET ECHO off  
REM NAME:   TFSLTSLP.SQL  
REM USAGE:"@path/tfsltslp"  
REM ------------------------------------------------------------------------ 
REM AUTHOR:   
REM    Virag Saksena, Craig A. Shallahamer, Oracle US       
REM    (c)1994 Oracle Corporation  
REM ------------------------------------------------------------------------  
REM Main text of script follows:  

col name form A18 trunc  
col gets form 999,999,990  
col miss form 90.9  
col cspins form A6 heading 'spin|sl06'  
col csleep1 form A5 heading 'sl01|sl07'  
col csleep2 form A5 heading 'sl02|sl08'  
col csleep3 form A5 heading 'sl03|sl09'  
col csleep4 form A5 heading 'sl04|sl10'  
col csleep5 form A5 heading 'sl05|sl11'  
col Interval form A12  
set recsep off  
  
select a.name  
      ,a.gets gets  
      ,a.misses*100/decode(a.gets,0,1,a.gets) miss  
      ,to_char(a.spin_gets*100/decode(a.misses,0,1  
       ,a.misses),'990.9')||  
       to_char(a.sleep6*100/decode(a.misses,0,1  
       ,a.misses),'90.9') cspins  
      ,to_char(a.sleep1*100/decode(a.misses,0,1  
       ,a.misses),'90.9')||  
       to_char(a.sleep7*100/decode(a.misses,0,1  
       ,a.misses),'90.9') csleep1  
      ,to_char(a.sleep2*100/decode(a.misses,0,1  
       ,a.misses),'90.9')||  
       to_char(a.sleep8*100/decode(a.misses,0,1  
       ,a.misses),'90.9') csleep2  
      ,to_char(a.sleep3*100/decode(a.misses,0,1  
       ,a.misses),'90.9')||  
       to_char(a.sleep9*100/decode(a.misses,0,1  
       ,a.misses),'90.9') csleep3  
      ,to_char(a.sleep4*100/decode(a.misses,0,1  
       ,a.misses),'90.9')||  
       to_char(a.sleep10*100/decode(a.misses,0,1  
       ,a.misses),'90.9') csleep4   
      ,to_char(a.sleep5*100/decode(a.misses,0,1  
       ,a.misses),'90.9')||  
       to_char(a.sleep11*100/decode(a.misses,0,1  
       ,a.misses),'90.9') csleep5  
from v$latch a  
where a.misses <> 0  
order by 2 desc  
/  


