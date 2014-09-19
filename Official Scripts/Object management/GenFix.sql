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
prompt
prompt DROP TABLE &nome_tabella._TMP;;
prompt
prompt CREATE TABLE &nome_tabella._TMP AS SELECT * FROM &NOME_TABELLA;;
prompt

select 	'ALTER TABLE '||table_name||' DROP CONSTRAINT '||constraint_name||';'
from 	user_constraints 
where 	r_constraint_name in (
					select 	constraint_name 
					from 	user_constraints 
					where   table_name=upper('&nome_tabella')
					and 	constraint_type in ('P','U')
				     );

prompt
prompt DROP TABLE &nome_tabella CASCADE CONSTRAINTS;;
prompt
prompt CREATE TABLE &nome_tabella
select decode(column_id,1,'(',',')
     ||rpad(column_name,40)
     ||decode(data_type,'DATE'    ,'DATE             '
                       ,'LONG'    ,'LONG             '
                       ,'LONG RAW','LONG RAW         '
                       ,'RAW'     ,'RAW              '
                       ,'CHAR'    ,'CHAR     '
                       ,'VARCHAR' ,'VARCHAR  '
                       ,'VARCHAR2','VARCHAR2 '
                       ,'NUMBER'  ,'NUMBER   '
                       ,'unknown')
     ||rpad(
       decode(data_type,'DATE'    ,null
                       ,'LONG'    ,null
                       ,'LONG RAW',null
                       ,'RAW'     ,decode(data_length,null,null
                                               ,'('||data_length||')')
                       ,'CHAR'    ,decode(data_length,null,null
                                               ,'('||data_length||')')
                       ,'VARCHAR' ,decode(data_length,null,null
                                               ,'('||data_length||')')
                       ,'VARCHAR2',decode(data_length,null,null
                                               ,'('||data_length||')')
                       ,'NUMBER'  ,decode(data_precision,null,'   '
                                           ,'('||data_precision||
decode(data_scale,null,null
,','||data_scale)||')')
                       ,'unknown'),8,' ')
     ||decode(nullable,'Y','NULL','NOT NULL') c1
from user_tab_columns
where table_name = upper('&nome_tabella')
order by column_id;

prompt );;
prompt


/* Default delle colonne della tabella */
/* ----------------------------------- */
declare
cursor c1 is
select table_name, column_name, data_default
from user_tab_columns
where table_name = '&nome_tabella'
and data_default is not null;
b1 varchar2(100);
b2 varchar2(100);
b3 varchar2(100);
begin
dbms_output.enable(999999);
open c1;
loop
 fetch c1 into b1,b2,b3;
 exit when c1%NOTFOUND;
 dbms_output.put_line('ALTER TABLE '|| ltrim(rtrim(b1)) ||' MODIFY '||ltrim(rtrim(b2))||' DEFAULT '||rtrim(ltrim(b3))||';');
end loop;
end;
/
prompt

set serveroutput on

/* Reverse dei check constraints */
/* ----------------------------- */
declare
cursor c1 is
select 'ALTER TABLE '||'&nome_tabella'||' ADD CONSTRAINT ' a1,
       constraint_name||CHR(10)||'  CHECK (' a2,
      search_condition a3,
      ') '||decode(status,'DISABLED','DISABLE','') a4,
      ';'||CHR(10)       a5
from user_constraints
where table_name = upper('&nome_tabella') and
constraint_type='C';
b1 varchar2(100);
b2 varchar2(100);
b3 varchar2(32000);
b4 varchar2(100);
b5 varchar2(100);
fl number;
begin
dbms_output.enable(999999);
open c1;
loop
 fetch c1 into b1,b2,b3,b4,b5;
 exit when c1%NOTFOUND;
 select count(*) into fl from user_tab_columns where table_name =
upper('&nome_tabella') 
	and (
	 upper(column_name)||' IS NOT NULL' = upper(b3)
	 	or
	 '"' || upper(column_name)||'" IS NOT NULL' = upper(b3)
	 );
 if fl = 0 then
   dbms_output.put(b1);
   dbms_output.put(ltrim(rtrim(b2)));
   dbms_output.put(ltrim(rtrim(b3)));
   dbms_output.put(ltrim(rtrim(b4)));
   dbms_output.put_line(ltrim(rtrim(b5)));
 end if;
end loop;
end;
/

prompt rem /* Verificare questa porzione */
prompt rem /* -------------------------- */
prompt INSERT INTO &nome_tabella
select decode(column_id,1,'(',',')  ||rpad(column_name,40)
from user_tab_columns
where table_name = upper('&nome_tabella')
order by column_id;
prompt )
prompt SELECT 
select decode(column_id,1,' ',',')  ||rpad(column_name,40)
from user_tab_columns
where table_name = upper('&nome_tabella')
order by column_id;
prompt FROM &nome_tabella._TMP;;
prompt
set serveroutput on
     
/* Estrazione degli indici definiti sulla tabella */
/* ---------------------------------------------- */
declare
cursor c1 is  select index_name,decode(uniqueness,'UNIQUE','UNIQUE')
unq
from user_indexes where
table_name = upper('&nome_tabella')
and index_name not in (
			select constraint_name 
			from user_constraints 
			where constraint_type = 'P' 
			and table_name = upper('&nome_tabella')
		      );
indname varchar2(50);
cursor c2 is select
decode(column_position,1,'(',',')||rpad(column_name,40) cl
from user_ind_columns where table_name = upper('&nome_tabella') and
 index_name = indname
order by column_position;
begin
dbms_output.enable(999999);
for c in c1 loop
 dbms_output.put('CREATE '||c.unq||' INDEX '||c.index_name||' ON '||CHR(10)||'  &nome_tabella ');
 indname := c.index_name;
 for q in c2 loop
  dbms_output.put_line(ltrim(rtrim(q.cl)));
 end loop;
  dbms_output.put_line(');'||CHR(10));
end loop;
end;
/

/* Creazione della Primary Key */
/* --------------------------- */

declare
cursor c1 is
select constraint_name, decode(constraint_type,'U',' UNIQUE',' PRIMARY KEY') typ,
decode(status,' DISABLED',' DISABLE',' ') status from user_constraints
where table_name = upper('&nome_tabella')
and   constraint_type in ('U','P');
cname varchar2(100);
cursor c2 is
select ltrim(rtrim(decode(position,1,'(',',')||rpad(column_name,40))) coln
from user_cons_columns
where table_name = upper('&nome_tabella')
and   constraint_name = cname
order by position;
begin
dbms_output.enable(999999);
for q1 in c1 loop
 cname := q1.constraint_name;
 dbms_output.put('ALTER TABLE &nome_tabella ADD CONSTRAINT '||cname||CHR(10)||'  '||q1.typ);
 --dbms_output.put(q1.typ);
 for q2 in c2 loop
  dbms_output.put(q2.coln);
 end loop;
  dbms_output.put_line(')'||q1.status||';');
  dbms_output.put_line(CHR(10));
end loop;
end;
/

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

/* Reverse dei Triggers */
/* -------------------- */

col c1 format a79 word_wrap
col x1 format a255
set long 32000
set arraysize 1

select 'create or replace trigger ' c1,
       description c1,
      'WHEN ('||when_clause||')' c1,
      trigger_body x1,
      '/'         c1
from user_triggers
where table_name = upper('&nome_tabella') and when_clause is not null
/
select 'create or replace trigger ' c1,
       description c1,
      trigger_body x1,
      '/'         c1
from user_triggers
where table_name = upper('&nome_tabella') and when_clause is null
/

select 'alter trigger '||trigger_name||decode(status,'DISABLED','
DISABLE',' ENABLE')||';'
from user_Triggers where table_name='&nome_tabella';


create or replace procedure dumzxcvreorg_dep(nam varchar2,typ varchar2) as
cursor cur is
select type,decode(type,'PACKAGE BODY','PACKAGE',type) type1,
name from  user_dependencies
where referenced_name=upper(nam) and referenced_type=upper(typ);
begin
dbms_output.enable(999999);
for c in cur loop
 dbms_output.put_line('ALTER '||c.type1||' '||c.name||' COMPILE;');
 dumzxcvreorg_dep(c.name,c.type);
end loop;
end;
/
exec dumzxcvreorg_dep('&nome_tabella','TABLE');

drop procedure dumzxcvreorg_Dep;

select 'GRANT '||privilege||' ON '||table_name||' TO '||grantee||
decode(grantable,'YES',' with grant option;',';') from
user_tab_privs where table_name = upper('&nome_tabella');

select 'GRANT '||privilege||' ('||column_name||') ON &nome_tabella TO
'||grantee||
decode(grantable,'YES',' with grant option;',';')
from user_col_privs where grantor=user and
table_name=upper('&nome_tabella')
order by grantee, privilege;

select 'CREATE SYNONYM '||synonym_name||' FOR
'||table_owner||'.'||table_name||';'
from user_synonyms where table_name=upper('&nome_tabella');

select 'CREATE PUBLIC SYNONYM '||synonym_name||' FOR
'||table_owner||'.'||table_name||';'
from all_synonyms where owner='PUBLIC' and table_name=upper('&nome_tabella') and
table_owner=user;

spool off
set echo on feed on verify on

