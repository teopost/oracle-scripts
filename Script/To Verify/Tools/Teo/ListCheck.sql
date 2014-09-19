/************************************************************
 Copyright ESA Software SpA. Via Draghi, 39 RIMINI
 ------------------------------------------------------------
 Autore	     : Stefano Teodorani 
 Data	     : 26/07/99
 Release     : 02.00.00
 Descrizione : Elenca i check constraints non conformi
 ************************************************************/

PROMPT *** Fix: for.sql
set serveroutput on

begin
dbms_output.enable(1000000);
for temptable in (select table_name,
                         constraint_name,
                         search_condition
                  from   user_constraints
                  where  constraint_type = 'C'
                  and    constraint_name like 'SYS%')  loop

if instr(temptable.search_condition, ' IS NOT NULL') = 0 then
        dbms_output.put_line(rpad(temptable.table_name,15) ||' | ' || rpad(temptable.constraint_name,15)||' | ' || temptable.search_condition);
end if;
end loop;

end;
/
