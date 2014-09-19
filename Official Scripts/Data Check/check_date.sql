create or replace procedure CHECK_DATE as
TROVATO  boolean;
nome_tabella varchar2(100);
nome_colonna varchar2(100);
v_SQL varchar2(1000);
a number;
num_records number;
BEGIN
	
declare cursor c1 is
select table_name, column_name 
from user_tab_columns where data_type = 'DATE';

begin 
	dbms_output.enable(99999999);
	dbms_output.put_line('Inizio controllo...');
	for cursore in c1 loop
--		dbms_output.put_line('Table: [' || cursore.table_name || '] Column: [' || cursore.column_name||']');
		v_SQL := 'select count(*) from ' || cursore.table_name || ' where ' || cursore.column_name || ' > trunc(sysdate)';
		--v_SQL := 'select count(*) from :1 where :2 > trunc(sysdate) and :1 like ''A%''';
--		dbms_output.put_line(v_SQL);
--		execute immediate v_SQL into num_records using cursore.table_name, cursore.column_name;
		execute immediate v_SQL into num_records;
		if num_records != 0 then
				dbms_output.put_line('Table: [' || cursore.table_name || '] Column: [' || cursore.column_name||']');
		end if;
--		a := execute immediate (v_SQL);
-- 		dbms_output.put_line('Result: ' || to_string(a));
	end loop;
	dbms_output.put_line('Controllo terminato');
end;


END;
/