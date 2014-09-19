/*************************************************************************/
/* tabdiff.sql - Lists the differences in table definitions in the tables*/ 
/*               for a schema in two different instances.   Uses database*/
/*               links and the SQL MINUS operator to make the comparison.*/
/*                                                                       */
/*    Author:  Ken Atkins (katkins@cco.net)                              */
/*             http://www.cco.net/~katkins/oratip                        */
/*                                                                       */
/*   Written:  5/11/95                                                   */
/*                                                                       */
/* You need to have a database link setup for any instance that you want */
/* to make a comparison for.                                             */
/*                                                                       */
/* Please feel free to use and modify this script as long it is not sold */
/* or included in any software without the prior permission of the author*/
/* If you do make some good improvements, please send them to me, and I  */
/* can incorporate them in a future version and make them available to   */
/* others (giving you credit of course!).                                */
/*                                                                       */
/*************************************************************************/
set pagesize 60 
set linesize 105 
set verify off
set feedback off 
set pause off;

--define obj_owner = '&1'
--define inst_1 = '&2'
--define inst_2 = '&3'
accept obj_owner prompt 'Table Owner: '
accept inst_1 prompt 'First instance DB Link (Include @):'
accept inst_2 prompt 'Second instance DB Link (Include @):'

clear breaks
ttitle off 
set heading off

column datetime noprint new_value datetime
column inst_code1 noprint new_value inst_code1
column inst_code2 noprint new_value inst_code2

select to_char(sysdate,'MM/DD/YY') datetime
  from dual
/
select value inst_code1
  from v$parameter&inst_1
where name = 'db_name'
/
select value inst_code2
  from v$parameter&inst_2
where name = 'db_name'
/
set feedback on
set heading on
set newpage 0


ttitle  left 'TABDIFF'-
	col 25 'SCHEMA DIFFERENCE REPORT' -
        col 53 'Report Date: ' datetime -
 skip 1 col 60 'Page: ' sql.pno -
 skip 1 col 10 'OWNER:  ' obj_owner   -
 skip 1 center 'Differences between &inst_code1 and &inst_code2' -
 skip 2 


column table_name format a25 heading 'Table';
column column_name format a25 heading 'Column';
column data_type format a8 heading 'DataType';
column data_length format 999 heading 'Len';
column data_precision format 999 heading 'Pr';
column nullable format a5 heading 'Null?';
column inst_code format a8 heading 'Instance';
(
select '&inst_code1' inst_code, table_name, column_name, data_type, data_length, data_precision, nullable
from all_tab_columns&inst_1
where owner = UPPER('&obj_owner')
  and table_name in (select table_name from all_tables&inst_2
                     where owner = UPPER('&obj_owner'))
MINUS
select '&inst_code1' inst_code, table_name, column_name, data_type, data_length, data_precision, nullable
from all_tab_columns&inst_2
where owner = UPPER('&obj_owner')
)
UNION
(
select '&inst_code2' inst_code, table_name, column_name, data_type, data_length, data_precision, nullable
from all_tab_columns&inst_2
where owner = UPPER('&obj_owner')
  and table_name in (select table_name from all_tables&inst_1
                     where owner = UPPER('&obj_owner'))
MINUS
select '&inst_code2' inst_code, table_name, column_name, data_type, data_length, data_precision, nullable
from all_tab_columns&inst_1
where owner = UPPER('&obj_owner')
)
order by 2, 3
/
undefine datetime
undefine inst_code1
undefine inst_code2
undefine obj_owner
