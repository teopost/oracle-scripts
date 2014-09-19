SET ECHO off
REM NAME:   TFSLDTFR.SQL
REM USAGE:"@path/tfsldtr table_owner table_name"
REM ------------------------------------------------------------------------
REM REQUIREMENTS:
REM    ANALYZE on table, SELECT on DBA_TABLES, DBA_SEGMENTS, DBA_EXTENTS
REM ------------------------------------------------------------------------
REM AUTHOR:
REM    Craig A. Shallahamer, Oracle US
REM ------------------------------------------------------------------------
REM PURPOSE:
REM    Load the tfrag table with a given table's fragmentation stats.
REM ------------------------------------------------------------------------
REM EXAMPLE:
REM    N/A
REM ------------------------------------------------------------------------
REM DISCLAIMER:
REM    This script is provided for educational purposes only. It is NOT
REM    supported by Oracle World Wide Technical Support.
REM    The script has been tested and appears to work as intended.
REM    You should always run new scripts on a test instance initially.
REM ------------------------------------------------------------------------
REM Main text of script follows:

set feedback on
set echo on
set verify off

def towner=&1
def tname=&2

rem *******************************************************************
rem * Goal: Analyze table to gather statistics
rem *******************************************************************
rem Specifically we are looking for:
rem - blocks ABOVE the hwm, i.e. empty blocks (dba_tables.blocks)
rem - average row length (dba_tables.blocks)

analyze table &towner..&tname compute statistics
/
col val1 new_value blks_w_rows noprint
col val2 new_value blks_above noprint
select blocks val1,
  empty_blocks val2
from   dba_tables
where  owner = upper('&towner') and
    table_name = upper('&tname')
/
rem *******************************************************************
rem * Goal: Get the number of blocks allocated to the segment
rem *******************************************************************
rem Specifically we are looking for:
rem - allocated blocks dba_segments.blocks

col val1 new_value alloc_blocks noprint
select blocks val1
from   dba_segments
where owner        = upper('&towner') and
      segment_name = upper('&tname')
/

rem *******************************************************************
rem * Goal: Calculate the HWM
rem *******************************************************************
rem Specifically we are looking for:
rem HWM = dba_segments.blocks - dba_tables.empty_blocks - 1
rem HWM = allocated blocks - blocks above the hwn - 1
col val1 new_value hwm noprint
select &alloc_blocks-&blks_above-1 val1
from dual
/

rem *******************************************************************
rem * Goal: Get the Number of Fragmented Rows or Chained Frows (cr)
rem *******************************************************************
col val1 new_value cr noprint
select chain_cnt val1
from dba_tables
where owner        = upper('&towner') and
      table_name   = upper('&tname')
/

rem ***********************************************************
rem * Goal :  Determine the Segment Fragmentation (sf)
rem ***********************************************************
col val1 new_val sf noprint
select count(*) val1
from   dba_extents
where  owner        = upper('&towner') and
       segment_name = upper('&tname')
/
rem ***********************************************************
rem ***********************************************************
rem * Load the TFRAG table with the just gathered information.
rem ***********************************************************
rem ***********************************************************
rem *
rem * Create the tfrag table if it does not exist.
rem *
drop table tfrag;

create table tfrag
(
  owner				char(30),
  name				char(30),
  hwm				number,
  blks_w_rows			number,
  avg_row_size			number,
  possible_bytes_per_block	number,
  no_frag_rows			number,
  no_extents			number
)
/
create unique index tfrag_u1 on tfrag (owner,name)
/
rem *
rem * Delete and insert the new stats.
rem *
delete
from  tfrag
where owner='&towner' and
      name='&tname'
/
insert into tfrag values
('&towner','&tname',&hwm,&blks_w_rows,0,0,&cr,&sf)
/
commit;

set echo off
set verify on
