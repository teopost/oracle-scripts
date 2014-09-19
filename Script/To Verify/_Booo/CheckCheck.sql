rem 
rem CheckCheck.sql
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

undef tab;
set echo off

set pages 0 feed off verify off lines 150 trims on
col c1 format a80

set serveroutput on
spool c:\temp\CheckCheck.txt

prompt Please Wait...

/* Reverse dei check constraints */
/* ----------------------------- */
declare
cursor c1 is
select  constraint_name a2,
      search_condition a3,
      table_name a4
from user_constraints
where constraint_type='C';
b1 varchar2(100);
b2 varchar2(100);
b3 varchar2(32000);
b4 varchar2(100);
b5 varchar2(100);
extcheck varchar2(200);
fl number;
ck1 number;
ck2 number;
begin
dbms_output.enable(999999);
open c1;
loop
 fetch c1 into b2,b3,b4;
 exit when c1%NOTFOUND;
  select count(*) into fl 
  from user_tab_columns 
  where table_name = b4
  and ( 
  	upper(column_name)||' IS NOT NULL' = upper(b3) 
  or 
  	'"' || upper(column_name)||'" IS NOT NULL' = upper(b3)
  );
 
 if fl = 0 then
   extcheck := substr(b2,instr(b2, '_E', -1)+1);
   
--   dbms_output.put_line('constraint='||b2);
--   dbms_output.put_line('table='||b4);
--   dbms_output.put_line('id='||extcheck);
   
   select count(*) into ck1
   from ts_tableid 
   where table_name = b4;
   if ck1 = 0 then
   	dbms_output.put_line('Riferimento TABLE_NAME mancante sulla TS_TABLEID per la tabella '||b4);	
   end if;
   select count(*) into ck2
   from ts_tableid 
   where id = extcheck;
   if ck2 = 0 then
   	dbms_output.put_line('Il check '|| b2 ||' non ha un ID sulla TS_TABLEID per la tabella '||b4);	
   end if;
 end if;
end loop;
end;
/
spool off
set echo on feed on verify on

