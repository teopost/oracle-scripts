/*
/		GEN_ABLE
/		--------				Keith McLeod
/							96/10/4
/		Create scripts to DISABLE and ENABLE all FK, PK
/		and UNIQUE constraints in the executed-in schema.
/
/		Disable FKs first, then PKs and Unique.  *En*able
/		in reverse order.
*/


set	feed off	sqln off	sqlp ' '
set	pause off	hea off		echo off	pages 0
set     termout on      timing off


--				** DISable **

spool c:\con_dis.sql
--			FKs first.
select
	'alter table '
	|| table_name
	|| ' disable constraint '
	|| constraint_name
	|| ';'
from
	user_constraints
where
	constraint_type = 'R'
order by
	table_name,
	constraint_name
;
--			PKs and UNIQUE.
select
	'alter table '
	|| table_name
	|| ' disable constraint '
	|| constraint_name
	|| ';'
from
	user_constraints
where
	constraint_type in( 'P', 'U' )
order by
	table_name,
	constraint_name
;





--				** ENable **

spool off
spool c:\con_en.sql
--			PKs and UNIQUE first.
select
	'alter table '
	|| table_name
	|| ' enable constraint '
	|| constraint_name
	|| ';'
from
	user_constraints
where
	constraint_type in( 'P', 'U' )
order by
	table_name,
	constraint_name
;
--			FKs.
select
	'alter table '
	|| table_name
	|| ' enable constraint '
	|| constraint_name
	|| ';'
from
	user_constraints
where
	constraint_type = 'R'
order by
	table_name,
	constraint_name
;

spool 	off
set	feed on		sqln on		sqlp 'SQL>'
set	pause on	hea on		echo on	
set     termout on      timing on	pages 40
