spool %WINDIR%\temp\AutoValid.log

/************************************************************
 
 ------------------------------------------------------------
 Autore	: Stefano Teodorani
 Data	: 08/03/99
 Descrizione : Ricompilazione oggetti invalidi
 ************************************************************/

set serveroutput on size 1000000

declare
   sql_statement varchar2(200);
   cursor_id     number;
   ret_val       number;
   also_invalid  number;
   attempt       number;
   max_attempt   number;
begin

   attempt       := 0;
   max_attempt   := 8;

   dbms_output.put_line(chr(0));
   dbms_output.put_line('AUTOVALIDAZIONE DEGLI OGGETTI INVALIDI');
   dbms_output.put_line('--------------------------------------');
   dbms_output.put_line(chr(0));

   loop
    select 	count(*) into also_invalid
    from 	user_objects
    where 	status = 'INVALID';

    exit when (also_invalid = 0 or attempt = max_attempt);
    attempt := attempt + 1;
    dbms_output.put_line(chr(0));
    dbms_output.put_line('Tentativo numero : '||attempt);
    dbms_output.put_line('----------------------------');
      for invalid in ( select 	object_type,
		    		object_name,
     				decode(object_type,'VIEW',1,'FUNCTION',2,'PROCEDURE',3,'PACKAGE',4,'PACKAGE BODY',5,'TRIGGER',6)
   		        from   	user_objects
   			where  	status        = 'INVALID'
   			and    	object_type in ('PACKAGE',
                       		'PACKAGE BODY',
                       		'FUNCTION',
                       		'PROCEDURE',
                       		'TRIGGER',
                       		'VIEW')
			order by 3) loop

      if invalid.object_type = 'PACKAGE BODY' then
        sql_statement := 'alter package '||invalid.object_name||' compile body';
      else
        sql_statement := 'alter '||invalid.object_type||' '||invalid.object_name||' compile';

      end if;

		  begin
			  cursor_id := dbms_sql.open_cursor;
		      dbms_sql.parse(cursor_id, sql_statement, dbms_sql.native);
		      ret_val := dbms_sql.execute(cursor_id);
		      dbms_sql.close_cursor(cursor_id);
		      dbms_output.put_line
					(rpad(initcap(invalid.object_type)||' '||invalid.object_name, 32)||' : compilato');
		  	exception when others then
			  dbms_output.put_line('Problemino in fase di compilazione di : ' ||invalid.object_name);

		  end;

   end loop;
   end loop;
   if attempt = max_attempt then
        dbms_output.put_line(chr(0));
   	dbms_output.put_line('ATTENZIONE');
   	dbms_output.put_line('Dopo '||attempt||' tentativi, alcuni oggetti sono rimasti invalidi.');
   	dbms_output.put_line('Effettuare una controllo della base dati');
   else
   	dbms_output.put_line(chr(0));
   	dbms_output.put_line('Tutti gli oggetti sono stati compilati con successo dopo '||attempt||' tentativi');
   end if;
end;
/

spool off;
