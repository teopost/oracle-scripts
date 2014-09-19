/*

TGenSovFK.sql
------------- 
Ultima revisione:
	r1.1 del 09/12/98

Descrizione: 
	Ricostruzione degli statements di creazione delle relazioni definite
	sulle tabelle di uno schema verso un'altro schema

Parametri:
	Nessuno

*/


set serveroutput on verify off trims on feedback off

declare
cname varchar2(50);
cname2 varchar2(50);
r_user varchar2(50);

cursor c1 is
select 	c.constraint_name,
	c.r_constraint_name cname2,
	c.table_name table1, 
	r.table_name table2,
        decode(c.status,'DISABLED','DISABLE',' ') status,
        decode(c.delete_rule,'CASCADE',' on delete cascade ',' ') delete_rule,
	c.r_owner r_user
from    all_constraints c,
        all_constraints r
where   c.constraint_type='R' 
and     c.r_constraint_name = r.constraint_name 
and 	c.owner = user
and 	c.r_owner != user
and 	c.r_owner = r.owner;

cursor c2 is
select decode(position,1,'(',',')||column_name colname
from user_cons_columns
where   constraint_name = cname
order by position;

cursor c3 is
select decode(position,1,'(',',')||column_name refcol
from all_cons_columns
where constraint_name = cname2
and owner = r_user
order by position;

begin
dbms_output.enable(100000);
for q1 in c1 loop
 cname := q1.constraint_name;
 cname2 := q1.cname2;
 r_user := q1.r_user;
 
 dbms_output.put_line('ALTER TABLE '||q1.table1||' DROP CONSTRAINT '||cname||';');
 
 dbms_output.put_line('ALTER TABLE '||q1.table1||' ADD CONSTRAINT '||cname);
 dbms_output.put('FOREIGN KEY ');
 for q2 in c2 loop
   dbms_output.put(q2.colname);
 end loop;
 dbms_output.put_line(')');
 dbms_output.put('REFERENCES '||q1.table2||' ');
 for q3 in c3 loop
   dbms_output.put(q3.refcol);
 end loop;
 dbms_output.put_line(') '||q1.delete_rule||q1.status);
 dbms_output.put_line('/');
end loop;
end;
/
set serveroutput off verify on trims off feedback on