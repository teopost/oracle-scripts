
SET ECHO off
REM NAME:    TFSDTFRG.SQL
REM USAGE:"@path/tfsdtfrg"
REM ------------------------------------------------------------------------
REM REQUIREMENTS:
REM    SELECT on TFRAG table created by TFSLDTFR.SQL
REM ------------------------------------------------------------------------
REM AUTHOR:
REM    Craig A. Shallahamer, Oracle US
REM ------------------------------------------------------------------------
REM PURPOSE:
REM    Detailed report of table fragmentation characteristics based on the
REM    data in the tfrag table.
REM ------------------------------------------------------------------------
REM EXAMPLE:
REM                      Detailed Table Fragmentation Characteristics
REM
REM
REM    Table Owner         : scott
REM          Name          : s_emp
REM    Extents             : 1
REM    High water mark     : 1
REM    Blocks with rows    : 1
REM    Block frag: Omega1  : 0
REM    Migrated rows       : 0
REM
REM ------------------------------------------------------------------------
REM DISCLAIMER:
REM    This script is provided for educational purposes only. It is NOT
REM    supported by Oracle World Wide Technical Support.
REM    The script has been tested and appears to work as intended.
REM    You should always run new scripts on a test instance initially.
REM ------------------------------------------------------------------------
REM Main text of script follows:

col towner	format a70
col tname	format a70
col exts	format 999
col omega1	format 90.9999
col chains	format 99,990
col rpb		format 999
col hwm		format 9,999,999
col bwr		format 9,999,999

ttitle -
  center  'Detailed Table Fragmentation Characteristics'  skip 2

set heading off

select 'Table Owner         : '||owner		towner,
       '      Name          : '||name		tname,
       'Extents             : '||no_extents		exts,
       'High water mark     : '||hwm			hwm,
       'Blocks with rows    : '||blks_w_rows		bwr,
       'Block frag: Omega1  : '||(hwm - blks_w_rows)/(hwm + 0.0001) omega1,
       'Migrated rows       : '||no_frag_rows		chains
from   tfrag
order by 1,2
/

set heading on

