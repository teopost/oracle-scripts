/*
/			GEN_DCON
/			--------			Keith McLeod
/							96/10/4
/			Create 2 scripts:  to DROP and to CREATE
/			constraints in the executed-in schema.
/			Files C:\con_drop.sql and c:\con_cr.sql
/
/			Omits the EXCEPTIONS INTO and USING INDEX clauses.
/
/			DROPs FKs first, then PK and UNIQUE.
/
/			CREATE PF and Unique first, then FKs.
*/


set	feed off	sqln off	sqlp ' '
set	pause off	hea off		echo off
set     termout on      timing off	pages 0
set	serveroutput on


--				** DROP **

spool c:\con_drop.sql
select
	'alter table '
	|| table_name
	|| ' drop constraint '
	|| constraint_name
	|| ';'
from
	user_constraints
where
	constraint_type = 'R'
order by
	table_name,
	constraint_name;

select
	'alter table '
	|| table_name
	|| ' drop primary key;'
from
	user_constraints
where
	constraint_type = 'P'
order by
	table_name,
	constraint_name;

select
	'alter table '
	|| table_name
	|| ' drop constraint '
	|| constraint_name
	|| ';'
from
	user_constraints
where
	constraint_type = 'U'
order by
	table_name,
	constraint_name;

spool off



--			** CREATE **

spool c:\con_cr.sql

begin
	dbms_output.enable( 50000 );
	for statement in (
				select
				'alter table '
				|| c.table_name
				|| ' add constraint '
				|| c.constraint_name
				|| decode( c.constraint_type, 'U', ' unique( ',
					'P', ' primary key( ', null )
				|| cl.column_name alter_1,
				c.table_name,
				c.constraint_name
				from user_constraints	c,
				     user_cons_columns  cl
				where c.constraint_type in ( 'P', 'U' )
				and c.table_name = cl.table_name
				and c.constraint_name = cl.constraint_name
				and cl.position = 1
				order by c.table_name
			) loop
		dbms_output.put_line( statement.alter_1 );
		for colname in (
				select column_name
				from user_cons_columns
				where table_name = statement.table_name
				and constraint_name = statement.constraint_name
				and position > 1
				order by position
				) loop
			dbms_output.put_line( ', '|| colname.column_name );
		end loop;
		dbms_output.put_line( ' );' );
	end loop;
end;
.
/

--				Foreign Key constraints.
begin
	dbms_output.enable( 50000 );
	for statement in (
				select
				  'alter table '
				  || c.table_name
				  || ' add constraint '
				  || c.constraint_name
				  || ' foreign key( '
				  || cl.column_name	alter_1,
				c.table_name,
				c.constraint_name,
				c.delete_rule,
				r.owner			r_owner,
				r.table_name            r_table,
				r.constraint_name       r_constraint_name
				from user_constraints	c,
				     user_cons_columns  cl,
				     user_constraints   r
				where c.constraint_type = 'R'
				and c.table_name = cl.table_name
				and c.constraint_name = cl.constraint_name
				and cl.position = 1
				and c.r_constraint_name = r.constraint_name
				and c.r_owner = r.owner
				order by c.table_name
			) loop
		dbms_output.put_line( statement.alter_1 );
		for colname in (
				select column_name
				from user_cons_columns
				where table_name = statement.table_name
				and constraint_name = statement.constraint_name
				and position > 1
				order by position
				) loop
			dbms_output.put_line( ', '|| colname.column_name );
		end loop;
		dbms_output.put( ' ) references '
			|| statement.r_owner
			|| '.'
			|| statement.r_table
			|| '( ' );
		for colname in (
				select column_name
				from user_cons_columns
				where table_name = statement.r_table
				and constraint_name = statement.r_constraint_name
				and position = 1
				order by position
				) loop
			dbms_output.put_line( colname.column_name );
		end loop;
		for colname in (
				select column_name
				from user_cons_columns
				where table_name = statement.r_table
				and constraint_name = statement.r_constraint_name
				and position > 1
				order by position
				) loop
			dbms_output.put_line( ', '|| colname.column_name );
		end loop;
		dbms_output.put( ' )' );
		if statement.delete_rule = 'CASCADE' then
			dbms_output.put( ' on delete cascade' );
		end if;
		dbms_output.put_line( ';' );
	end loop;
end;
.
/


spool off
set	feed on		sqln on		sqlp 'SQL>'
set	pause on	hea on		echo on	
set     termout on      timing on	pages 40
