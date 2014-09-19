/*************************************************************************/
/* objdiff.sql - Lists the objects in a schema that are not in both of   */
/*               two instances.   Uses database links and the SQL MINUS  */
/*               operator to make the comparison.                        */
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
set linesize 80 
set verify off
set feedback off 
set pause off;
--define obj_owner = '&1'
--define inst_1 = '&2'
--define inst_2 = '&3'
accept obj_owner prompt 'Object Owner: '
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


ttitle  left 'OBJDIFF'-
	col 25 'OBJECT DIFFERENCE REPORT' -
        col 53 'Report Date: ' datetime -
 skip 1 col 60 'Page: ' sql.pno -
 skip 1 col 10 'OWNER:  ' obj_owner   -
 skip 1 center 'Objects in &inst_code1 but not &inst_code2' -
 skip 2 

set null=0

column object_type format a15 heading 'Object Type';
column object_name format a35 heading 'Object Name';
column status format a10 heading 'Status';
column inst_code format a10 heading 'Instance';
select object_name, object_type, status
from all_objects&inst_1
where owner = UPPER('&obj_owner')
--  and object_type != 'SYNONYM'
MINUS
select object_name, object_type, status
from all_objects&inst_2
where owner = UPPER('&obj_owner')
--  and object_type != 'SYNONYM'
order by 2,3
/
set heading off;
set feedback off;
select '' from dual
/
set heading on;
set feedback on;
ttitle  left 'OBJDIFF'-
	col 25 'OBJECT DIFFERENCE REPORT' -
        col 53 'Report Date: ' datetime -
 skip 1 col 60 'Page: ' sql.pno -
 skip 1 col 10 'OWNER:  ' obj_owner   -
 skip 1 center 'Objects in &inst_code2 but not &inst_code1' -
 skip 2 

select object_name, object_type, status
from all_objects&inst_2
where owner = UPPER('&obj_owner')
  and object_type != 'SYNONYM'
MINUS
select object_name, object_type, status
from all_objects&inst_1
where owner = UPPER('&obj_owner')
  and object_type != 'SYNONYM'
order by 2,3
/