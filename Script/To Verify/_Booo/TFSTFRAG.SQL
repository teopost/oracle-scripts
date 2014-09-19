
SET ECHO off
REM NAME:    TFSTFRAG.SQL
REM USAGE:"@path/tfstfrag"
REM ------------------------------------------------------------------------
REM REQUIREMENTS:
REM     SELECT on TFRAG
REM ------------------------------------------------------------------------
REM AUTHOR:
REM    Craig A. Shallahamer, Oracle USA
REM ------------------------------------------------------------------------
REM PURPOSE:
REM    This script displays summary table  fragmentation  information.  The
REM    information is queried from the tfrag table which  is  loaded via the
REM    ldtfrag script.  Once the ldtfrag script has been run for a given
REM    table, this report displays the  following information:
REM
REM      - Table owner
REM      - Table name
REM      - Segment fragmentation (number of extents)
REM      - Number of table rows
REM      - Table block fragmentation (1.0 bad, 0.0 good)
REM      - Row fragmentation (chains)
REM ------------------------------------------------------------------------
REM EXAMPLE:
REM                          Table Fragmentation Characteristics
REM
REM    Owner    Table Name                               Exts Omega1  Chains
REM    -------- ---------------------------------------- ---- ------ -------
REM    scott    s_emp                                       1  0.000       0
REM ------------------------------------------------------------------------
REM DISCLAIMER:
REM    This script is provided for educational purposes only. It is NOT
REM    supported by Oracle World Wide Technical Support.
REM  The script has been tested and appears to work as intended.
REM    You should always run new scripts on a test instance initially.
REM ------------------------------------------------------------------------
REM Main text of script follows:

col towner	heading 'Owner'			format a8 	trunc
col tname	heading 'Table Name'		format a40 	trunc
col exts	heading 'Exts'			format 999 	trunc
col omega1	heading 'Omega1'		format 0.999 	trunc
col chains	heading 'Chains'		format 99,990 	trunc

ttitle -
  center  'Table Fragmentation Characteristics'   skip 2

select owner						towner,
       name						tname,
       no_extents					exts,
  (hwm - blks_w_rows)/(hwm + 0.0001) 		omega1,
       no_frag_rows					chains
from   tfrag
order by 1,2
/

