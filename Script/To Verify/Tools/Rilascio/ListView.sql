spool c:\temp\ListView.bat

set heading off verify off feedback off arraysize 1 long 1000000 termout off
set pages 0 lines 78 trims on
column vtext format a78 wrap
column AA NOPRINT
column BB NOPRINT
column CC NOPRINT
select 'echo PROMPT *** View: '||upper(v.view_name)||'>>view.sql'||chr(10)|| 'type '||upper(v.view_name)||'.VW>> view.sql '||chr(10)||'del '||upper(v.view_name)||'.VW',
	object_name   AA,
	d.dlevel      BB,
	o.object_type CC
from   	sys.dba_objects o,
	sys.order_object_by_dependency d,
	all_views v
where  	o.object_id    = d.object_id(+)
and  	o.object_type  = 'VIEW'
and 	o.owner = upper('RILASCIO')
and 	o.owner = v.owner
and 	v.view_name = o.object_name
order  by d.dlevel desc, o.object_type
/

spool off
set termout on feedback on verify on heading on

 
 
 
