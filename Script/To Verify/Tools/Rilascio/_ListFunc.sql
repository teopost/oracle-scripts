spool c:\temp\ListFunc.bat

set heading off verify off feedback off arraysize 1 long 1000000 termout off
set pages 0 lines 78 trims on
column vtext format a78 wrap
column AA NOPRINT
column BB NOPRINT
column CC NOPRINT
select 'echo PROMPT *** Function: '||upper(object_name)||'>>function.sql'||chr(10)|| 'type '||upper(object_name)||'.PRC>> function.sql ',
	object_name   AA,
	d.dlevel      BB,
	o.object_type CC
from   	sys.dba_objects o,
	sys.order_object_by_dependency d
where  	o.object_id    = d.object_id(+)
and  	o.object_type  = 'FUNCTION'
and 	o.owner = upper('RILASCIO')
order  by d.dlevel desc, o.object_type
/

spool off
set termout on feedback on verify on heading on

 
 
 
