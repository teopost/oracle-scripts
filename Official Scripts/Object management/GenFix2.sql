rem 
rem GenFix.sql
rem ---------------- 
rem Ultima revisione:
rem 	r2.1 del 17/09/99
rem 	r2.2 del 24/01/2001, S. Teodorani - Aggiunta clausola CASCADE CONSTRAINT in DROP TABELLA
rem 				            Aggiuto elenco delle colonne nello statement di insert
rem Descrizione: 
rem 	Ricostruzione degli statements necessari per rigenerare una tabella.
rem Input:
rem 	Nome della Tabella
rem Output:
rem 	Script c:\temp\GenFix.txt
rem Nota: 
rem 	Deve esistere la directory C:\Temp
rem 	

ACCEPT nome_tabella CHAR PROMPT 'Tabella: '

undef tab;
set echo off

set pages 0 feed off verify off lines 150 trims on
col c1 format a80

spool c:\temp\GenFix.txt


select 	'ALTER TABLE '||table_name||' DROP CONSTRAINT '||constraint_name||';'
from 	user_constraints 
where 	r_constraint_name in (
					select 	constraint_name 
					from 	user_constraints 
					where   table_name=upper('&nome_tabella')
					and 	constraint_type in ('P','U')
				     );


set serveroutput on


/* Creazione delle Foreign Key */ 
/* --------------------------- */

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
        decode(c.delete_rule,'CASCADE',' ON DELETE CASCADE ',' ') delete_rule,
	c.r_owner r_user
from    all_constraints c,
        all_constraints r
where   c.constraint_type='R' 
and     c.r_constraint_name = r.constraint_name 
and     c.table_name = upper('&nome_tabella')
and 	c.owner = user
and 	c.r_owner = r.owner
union
select c.constraint_name,c.r_constraint_name cname2,
       c.table_name table1, r.table_name table2,
       decode(c.status,'DISABLED','DISABLE',' ') status,
       decode(c.delete_rule,'CASCADE',' ON DELETE CASCADE ',' ') delete_rule,
       c.r_owner r_user
from   user_constraints c,
       user_constraints r
where c.constraint_type='R' and
      c.r_constraint_name = r.constraint_name and
      r.table_name = upper('&nome_tabella');

cursor c2 is
select ltrim(rtrim(decode(position,1,'(',',')||rpad(column_name,40))) colname
from user_cons_columns
where   constraint_name = cname
order by position;

cursor c3 is
select ltrim(rtrim(decode(position,1,'(',',')||rpad(column_name,40))) refcol
from all_cons_columns
where constraint_name = cname2
and owner = r_user
order by position;

begin
dbms_output.enable(999999);
for q1 in c1 loop
 cname := q1.constraint_name;
 cname2 := q1.cname2;
 r_user := q1.r_user;

 dbms_output.put('ALTER TABLE '||q1.table1||' ADD CONSTRAINT '||cname||CHR(10)||'  FOREIGN KEY');
 for q2 in c2 loop
   dbms_output.put_line(q2.colname);
 end loop;
 dbms_output.put(') '||CHR(10)||' REFERENCES '||q1.table2);
 for q3 in c3 loop
   dbms_output.put_line(q3.refcol);
 end loop;
 dbms_output.put(')'||q1.delete_rule||q1.status||';');
 dbms_output.put_line(chr(10));
end loop;
end;
/

spool off
set echo on feed on verify on

