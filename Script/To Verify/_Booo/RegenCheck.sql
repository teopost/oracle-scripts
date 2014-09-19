rem 
rem RegenCheck.sql
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

spool c:\temp\RegenCheck.txt

/* Reverse dei check constraints */
/* ----------------------------- */
declare
cursor c1 is
select 'exec esa.drop_fk('''|| constraint_name || ''')',
      search_condition a3
from user_constraints
where table_name = upper('&nome_tabella') and
constraint_type='C';
b1 varchar2(100);
b3 varchar2(32000);
fl number;
begin
dbms_output.enable(999999);
open c1;
loop
 fetch c1 into b1,b3;
 exit when c1%NOTFOUND;
 select count(*) into fl from user_tab_columns where table_name =
upper('&nome_tabella') 
	and (
	 upper(column_name)||' IS NOT NULL' = upper(b3)
	 	or
	 '"' || upper(column_name)||'" IS NOT NULL' = upper(b3)
	 );
 if fl = 0 then
   dbms_output.put_line(b1);
 end if;
end loop;
end;
/

prompt 

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
spool off
set echo on feed on verify on

