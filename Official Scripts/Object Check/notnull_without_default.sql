/*
 ===========================================================
 Filename...: notnull_without_default.sql
 Author.....: Stefano Teodorani
 Release....: 1.0 - 14-sep-2000
 Description: Verifica l'esistenza di campi not null senza default
 Notes......: Sono esclusi dall'estrazione le primary key
 ===========================================================
*/ 

set serveroutput on

declare
 cursor c1 is
 select	
 	data_default,
 	default_length,
 	column_name,
 	table_name,
 	nullable
 from	
 	user_tab_columns,
 	tab
 where tab.tname = user_tab_columns.table_name
 and tabtype = 'TABLE';
 

 v_data_default	   varchar2(255);
 v_default_length  number(38);
 v_column_name     varchar2(35);
 v_table_name      varchar2(35);
 v_nullable        varchar2(1);
 v_num_rec         number(10);
 
begin
 dbms_output.enable(900000);
 open c1;
 loop
   fetch c1 into v_data_default, v_default_length, v_column_name, v_table_name, v_nullable;
   exit when c1%NOTFOUND;
   
   if v_nullable = 'N' and v_default_length is null then
   	
		 select count(*) into v_num_rec
		 from 
		 		user_indexes a, 
		 		user_cons_columns b, 
		 		user_constraints c
		 where 
		 		 a.table_name = v_table_name
		 and a.table_name = b.table_name
		 and b.constraint_name = c.constraint_name
		 and b.constraint_name = a.index_name 
		 and b.column_name = v_column_name
		 and c.constraint_type = 'P';
   	
   	 if v_num_rec != 0 then
   	   -- dbms_output.put_line(substr(v_data_default,1, v_default_length));
   	   dbms_output.put_line('Table: ' || rpad(v_table_name,30, '.')  || ' Column: ' ||v_column_name);
     end if;
   end if;

 end loop;
 close c1;
end;
/