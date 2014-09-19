-------------------------------------------------------------------------
--    SQL Script Name:  unload_fixed.sql
--
--    Function:         generates a SQL*Plus script to unload a table to a
--                      file and a SQL*Loader script to reload the same
--                      data.  Intent is to create a faster alternative
--                      to export/import.
--
--                      Initial testing indicates that the unload takes about
--                      20% longer than EXP, but that the reload takes only
--                      45% as long as IMP.  In Oracle7 version 7.1, the 
--                      capability of parallelizing direct loads (but not IMP) 
--                      should provide much faster load times, reasonably 10% 
--                      of the time for IMP.
--
--                      WORD OF WARNING REGARDING PERFORMANCE:
--                      Performance is very specific to the data distribution
--                      of the table data.  Much poorer performance has been
--                      seen in the following cases:
--                       -  many long varchar columns which actually contain
--                          short data values;
--                       -  many number columns without precision or scale
--                          which are defaulted to large numbers;
--                       -  lots of null values;
--                      All of these cases lead to inefficient use of the
--                      fixed record format of the unload file.  Padding the
--                      unload file with leading/trailing zeros or trailing
--                      blanks yields files 4X the size of an export dmp file
--                      and unload times 4X those of export.  (Even in these
--                      extreme test situations, the load time was still 
--                      between 80% and 90% of IMP.)
--
--
--                      This unload/reload utility has some other advantages
--                      besides speed.  The unload can easily select a subset
--                      of the original table (for statistical sampling or
--                      retrieving rows for a particular department or busines
--                      date for instance) whereas EXP/IMP deals with entire
--                      tables.  Additionally, if desired, unload can sort
--                      the output in order to speed index builds and/or
--                      optimize cache hits on the reloaded data based on
--                      loading frequently used rows contiguously.  This may
--                      provide an additional benefit in some reorg efforts.
--                      Finally, the unload might have a GROUP BY appended
--                      which would facilitate development of summary tables.
--
--                      By editing the generated unload2.sql and SQL*Loader
--                      .CTL scripts, one could additionally remove columns
--                      or modify them with SQL (or PL/SQL functions in r7.1)
--                      during the extract.  Just be sure to adjust the length
--                      of the COLUMN and PAGESIZE in unload2.sql and the
--                      input field in .CTL to reflect whatever changes.
--
--                      This utility can also unload data from a view which
--                      is not possible via EXP.  This facility may be used
--                      to do subsets--selection (specific rows), projection 
--                      (specific columns), joins, GROUP BY summaries or
--                      function application without having to edit this
--                      script or its generated output scripts.
--
--    Arguments IN:     prompts for table_owner, table_name as well as
--                      default_precision and default_scale for columns
--                      defined as NUMBER or FLOAT (without precision or
--                      scale defined).
--
--    Arguments OUT:    none
--
--    Calls:            none
--
--    Called by:        none
--
--    Change History:   05/25/94  gcdodge   original development
--
--    Limitations:      Doesn't handle long, raw, long raw, rowid, mlslabel
--                      datatypes.
--
--                      This utility has been tested in a Solaris 2.3 
--                      environment, but is expected to be fully portable
--                      to any ASCII platform.  Unlike EXP/IMP, however,
--                      it will not automatically make translations when
--                      the unload file is moved from ASCII to EBCDIC or
--                      vice versa.  Since all data is written in external
--                      formats, one should expect that file transfer 
--                      utilities that do such conversions should work.
--                      As an alternative, one could edit the SQL*Loader
--                      .CTL script to specify the alternative encoding
--                      scheme.
--
--                      If a numeric column is encountered which has no
--                      defined precision or scale, then this script will
--                      use default values (prompted for); this poses three
--                      risks: 1) that you may overspecify the precision
--                      and thereby waste space in the unload file; 2)
--                      you may underspecify the precision and thereby
--                      get overflow indicators in the unloaded data which
--                      may not be caught prior to loading; 3) you may
--                      underspecify the scale and introduce truncation
--                      which will not be found by either the unload or
--                      load processes.  For this reason, it is strongly
--                      recommended that numeric table columns be defined
--                      with appropriate precision and scale values.
--
--                      The generated SQL*Loader script assumes that fields
--                      of blanks should be loaded as NULLS...if the table
--                      has columns for which SPACES are valid values, then
--                      it will be necessary to edit the generated unload2.sql
--                      script to concatenate double quotes before and after
--                      the affected column(s) along with changing the length
--                      (pagesize in unload2.sql and the individual field's
--                      length in the generated .CTL file) by two bytes.
--
-------------------------------------------------------------------------
REM
set tab off
set heading off heading off feedback off echo off verify off space 1 pagesize 0 linesize 120
accept owner             prompt 'What schema owns the table to be unloaded? '
accept table_name        prompt 'What table is to be unloaded? '
accept default_precision prompt 'What TOTAL number of digits should be reserved for numbers without defined precision? '
accept default_scale     prompt 'What number of DECIMAL digits should be reserved for numbers without defined scale? '
---------------------------------------------------
--  Generate the unload script
---------------------------------------------------
spool unload_fixed2.sql
select 'SET HEADING OFF FEEDBACK OFF ECHO OFF VERIFY OFF SPACE 0 PAGESIZE 0 TERMOUT OFF'
  from dual
/

--  Calculate the sum of all output field lengths and set the output record size
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

--  Generate an appropriate SQL*Plus COLUMN command to control formatting of each output field
select 'COLUMN ' || rpad('"'||column_name||'"',32) 
       || ' FORMAT ' 
       || rpad(decode(data_type,
                   'CHAR','A'||data_length,
                   'VARCHAR2','A'||data_length,
                   'VARCHAR','A'||data_length,
                   'DATE','A14',
                   'NUMBER',decode(data_precision,
                                   '', rpad('0',&default_precision-&default_scale,'9')||'.'||rpad('9',&default_scale,'9'),
                                   rpad('0',greatest(data_precision-data_scale,1),'9') || decode(data_scale,0,'','.')
                                       || decode(data_scale,0,'',rpad('9',data_scale,'9'))),
                   'FLOAT',rpad('0',&default_precision-&default_scale,'9')||'.'||rpad('9',&default_scale,'9'),
                   'ERROR'),40)
       || ' HEADING ''X'''
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
select 'b', column_id, decode(column_id, 1, '    ', '  , ')
                       || decode(data_type,'DATE','to_char('||'"'||column_name||'"'||',''YYYYMMDDHH24MISS'')
'||'"'||column_name||'"'  ,
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
REM
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
select 'n', column_id, rpad(decode(column_id,1,'(',',')||'"'||column_name||'"',31)
                       || decode(data_type,
                                 'CHAR','CHAR('||data_length||')',
                                 'VARCHAR','CHAR('||data_length||')',
                                 'VARCHAR2','CHAR('||data_length||')',
                                 'DATE','DATE(14) "YYYYMMDDHH24MISS"',
                                 'NUMBER','DECIMAL EXTERNAL('||decode(data_precision,
                                                          '',&default_precision+2,
                                                          greatest(data_precision-data_scale,1)+decode(data_scale,0,0,1)+data_scale+1)

                                                ||')',
                                 'FLOAT','DECIMAL EXTERNAL('||to_char(&default_precision+2)||')',
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
REM
clear column
clear break
clear compute
undef owner
undef table_name
undef default_precision
undef default_scale
.

