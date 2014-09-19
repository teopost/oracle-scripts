SET ECHO off
REM --------------------------------------------------------------------------
REM REQUIREMENTS:
REM    SELECT on the given table(s)
REM --------------------------------------------------------------------------
REM PURPOSE:
REM    Generates a sql*plus script to unload a table to a file and a
REM    SQL*Loader script to reload the same data.  Intent is to create
REM    a faster alternative to export/import.
REM ---------------------------------------------------------------------------
REM DISCLAIMER:
REM    This script is provided for educational purposes only. It is NOT
REM    supported by Oracle World Wide Technical Support.
REM    The script has been tested and appears to work as intended.
REM    You should always run new scripts on a test instance initially.
REM --------------------------------------------------------------------------
REM Main text of script follows:

set tab off
set heading off heading off feedback off echo off verify off space 1 pagesize 0 linesize 120
accept owner             prompt 'What schema owns the table to be unloaded? '
accept table_name        prompt 'What table is to be unloaded? '
accept default_precision prompt 'Total number of digits to be reserved for numbrs w/out defined precision?' 
accept default_scale     prompt 'Total number of DECIMAL digits to be reserved for numbers w/out defined scale? '
---------------------------------------------------
--  Generate the unload script
---------------------------------------------------
spool unload_fixed2.sql
select 'SET HEADING OFF FEEDBACK OFF ECHO OFF VERIFY OFF SPACE 0 PAGESIZE 0
TERMOUT OFF'
  from dual
/

--Calculate the sum of all output field lengths and set the output record size
select 'SET LINESIZE '
       || (sum(decode(data_type,
                      'CHAR',data_length,
                      'VARCHAR',data_length,
    'VARCHAR2',data_length,
                      'DATE',14,
   'NUMBER',decode(data_precision,
                                   '',&default_precision+2,
greatest(data_precision-data_scale,1)+decode(data_scale,0,0,1)+data_scale)+1,
                      'FLOAT',&default_precision+2,
           data_length)))
  from dba_tab_columns
 where owner=upper('&&owner')
   and table_name=upper('&&table_name')
/

--  Generate an appropriate SQL*Plus COLUMN command to control formatting of
--  each output field
select 'COLUMN ' || rpad('"'||column_name||'"',32)
       || ' FORMAT '
       || rpad(decode(data_type,
                   'CHAR','A'||data_length,
                   'VARCHAR2','A'||data_length,
                   'VARCHAR','A'||data_length,'DATE','A14',
'NUMBER',decode(data_precision,'',rpad('0',&default_precision-&default_scale,'9')||'.'
||rpad('9',&default_scale,'9'), rpad('0',greatest(data_precision-data_scale,1),'9') ||
decode(data_scale,0,'','.') ||
decode(data_scale,0,'',rpad('9',data_scale,'9'))),
'FLOAT',rpad('0',&default_precision-&default_scale,'9')||'.'||rpad('9',&default_scale,'9'),
                 'ERROR'),40)|| ' HEADING ''X'''
  from dba_tab_columns
 where owner=upper('&&owner')
   and table_name=upper('&&table_name')
 order by column_id
/
--  Generate the actual SELECT statement to unload table data
select 'SPOOL c:\temp\&&owner..&&table_name..DAT'
  from dual
/
column var1 noprint
column var2 noprint
select 'a' var1, 0 var2, 'SELECT '
  from dual
union
select 'b', column_id, decode(column_id, 1, '    ', '  , ')||
decode(data_type,'DATE','to_char('||'"'||column_name||'"'||',''YYYYMMDDHH24MISS
'') '||'"'||column_name||'"'  ,
                       '"'||column_name||'"')
  from dba_tab_columns
 where owner=upper('&&owner')
   and table_name=upper('&&table_name')
union
select 'c', 0, 'FROM &&owner..&&table_name'
from dual
union
select 'd', 0, ';'
  from dual
 order by 1,2
/
select 'SPOOL OFF'
  from dual
/
select 'SET TERMOUT ON'
  from dual
/

spool off
-----------------------------------------------------------------------------
--  Generate the SQL*Loader control file
-----------------------------------------------------------------------------
set lines 120 pages 0
spool &&owner..&&table_name..CTL
select 'a' var1, 0 var2, 'OPTIONS(DIRECT=TRUE)'
  from dual
union
select 'b', 0, 'LOAD DATA'
  from dual
union
select 'c', 0, 'INFILE  ''c:\temp\&&owner..&&table_name..DAT'''
  from dual
union
select 'd', 0, 'BADFILE  &&owner..&&table_name..BAD'
  from dual
union
select 'e', 0, 'DISCARDFILE  &&owner..&&table_name..DSC'
  from dual
union
select 'f', 0, 'DISCARDMAX 999'
  from dual
union
select 'm', 0, 'INTO TABLE &&owner..&&table_name'
  from dual
union
select 'n', column_id,
rpad(decode(column_id,1,'(',',')||'"'||column_name||'"',31)
                       || decode(data_type,
 'CHAR','CHAR('||data_length||')',
                                 'VARCHAR','CHAR('||data_length||')',
                             'VARCHAR2','CHAR('||data_length||')',
                    'DATE','DATE(14) "YYYYMMDDHH24MISS"',
 'NUMBER','DECIMAL
EXTERNAL('||decode(data_precision,
'',&default_precision+2, greatest(data_precision-data_scale,1)+decode(data_scale,0,0,1)+data_scale+1)
              ||')',
                                 'FLOAT','DECIMAL
EXTERNAL('||to_char(&default_precision+2)||')',
  'ERROR--'||data_type)
                       || ' NULLIF ("' ||column_name||'" = BLANKS)'
  from dba_tab_columns
 where owner = upper('&&owner')
   and table_name = upper('&&table_name')
union
select 'z', 0, ')'
  from dual
 order by 1, 2
/

spool off

-----------------------------------------------------------------------------
--  Cleanup
-----------------------------------------------------------------------------
clear column
clear break
clear compute
undef owner
undef table_name
undef default_precision
undef default_scale
