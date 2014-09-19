set serveroutput on verify off linesize 132

declare 
cursor c1 is
select utc.table_name, utc.column_name  , utc.data_type , uc.constraint_name
from user_tab_columns utc
   join user_cons_columns ucc on (
           utc.table_name = ucc.table_name and utc.column_name = ucc.column_name)
   join user_constraints uc on (
       uc.constraint_name = ucc.constraint_name)
where 1=1
and uc.constraint_type = 'P'
and utc.data_type not in ('NUMBER', 'DATE', 'BLOB', 'CBLOB')
and utc.table_name not in ('ZZ_OBJECTS')
;

cursor c2 (cname varchar2) is
select table_name, column_name 
from user_constraints natural join  user_cons_columns
where constraint_type='R' and r_constraint_name = cname
;

begin
for q1 in c1 loop

dbms_output.put_line('Elaboro: '||q1.table_name);
dbms_output.put_line('=========================');
dbms_output.put_line('update '||q1.table_name || ' set ' || q1.column_name || '=  upper(' || q1.column_name ||');');

  for q2 in c2(q1.constraint_name)  loop
    dbms_output.put_line('update '||q2.table_name || ' set ' || q2.column_name || '=  upper(' || q2.column_name ||');');
  end loop;
  
 dbms_output.put_line('');
end loop;
end;
/


