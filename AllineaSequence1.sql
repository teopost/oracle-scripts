spool %WINDIR%\temp\AllignSequences.log

/************************************************************
 Copyright Apex-net srl - Via Riccardo Brusi, 151/2 - 47023 Cesena
 ------------------------------------------------------------
 Autore 	: Stefano Teodorani
 Data   	: 29/01/2001
 Descrizione 	: Ricostruzione sequences
 ************************************************************/

set serveroutput on size 1000000

declare
   
   cursor_id     number;        /* Variabili per gestione sql dinamico*/
   ret_val       number;

   sql_statement varchar2(200);
   max_prg_val   number;

   table_name    varchar2(30);
   prg_name      varchar2(60);
   
        procedure allinea_sequence(table_name_in VARCHAR2, prg_name_in VARCHAR2) 
        is
        begin

                table_name := upper(ltrim(rtrim(table_name_in)));
                prg_name   := upper(ltrim(rtrim(prg_name_in)));
                
                /* Calcolo del progressivo */
                sql_statement := 'select max(' || prg_name || ') from ' || table_name ;
                cursor_id := dbms_sql.open_cursor;
                dbms_sql.parse(cursor_id, sql_statement, dbms_sql.native);
                dbms_sql.define_column(cursor_id, 1, max_prg_val);
                ret_val := dbms_sql.execute(cursor_id);

      		loop 
			if dbms_sql.fetch_rows(cursor_id) > 0 then
		      		dbms_sql.column_value (cursor_id, 1, max_prg_val);                 
--				dbms_output.put_line('max_prg_val>>'||max_prg_val);
			else
				exit;
			end if;
               	
                end loop;

		if max_prg_val is null then 
			max_prg_val := 0;
		end if;
		
                dbms_sql.close_cursor(cursor_id);
        
                /* Drop della sequence */
                sql_statement := 'DROP SEQUENCE SEQ_' || table_name;
                
                cursor_id := dbms_sql.open_cursor;
                dbms_sql.parse(cursor_id, sql_statement, dbms_sql.native);
                ret_val := dbms_sql.execute(cursor_id);
                dbms_sql.close_cursor(cursor_id);
        
                /* Creazione della sequence */
                sql_statement := 'CREATE SEQUENCE SEQ_' || table_name || ' INCREMENT BY 1 START WITH ' || to_char(max_prg_val+1) || ' MAXVALUE 9999999999 NOCYCLE NOCACHE';
                
                cursor_id := dbms_sql.open_cursor;
                dbms_sql.parse(cursor_id, sql_statement, dbms_sql.native);
                ret_val := dbms_sql.execute(cursor_id);
                dbms_sql.close_cursor(cursor_id);

                dbms_output.put_line('Ricostruzione SEQ_' || table_name || ', progressivo ' || prg_name || ' = ' || to_char(max_prg_val+1));
        end;
begin
        dbms_output.put_line('Controllo sequences in corso...');
        dbms_output.put_line(chr(0));
        
--        allinea_sequence('CPXX_STFOESART  ','PRG_STFOESART   ');
        
        allinea_sequence('CAXX_PRCLESART  ','PRG_PRCLESART   ');
        allinea_sequence('CAXX_PRCLIART   ','PRG_PRCLIART    ');
        allinea_sequence('CAXX_PRCLIPOLO  ','PRG_PRCLIPOLO   ');
        allinea_sequence('CAXX_PRCLPESPAR ','PRG_PRCLPESPAR  ');
        allinea_sequence('CAXX_PRCLPOESAR ','PRG_PRCLPOESAR  ');
        allinea_sequence('CAXX_PRCLPOLART ','PRG_PRCLPOLART  ');
        allinea_sequence('CAXX_STCLESART  ','PRG_STCLESART   ');
        allinea_sequence('CAXX_STCLIART   ','PRG_STCLIART    ');
        allinea_sequence('CAXX_STCLIPOLO  ','PRG_STCLIPOLO   ');
        allinea_sequence('CAXX_STCLPESPAR ','PRG_STCLPESPAR  ');
        allinea_sequence('CAXX_STCLPOESAR ','PRG_STCLPOESAR  ');
        allinea_sequence('CAXX_STCLPOLART ','PRG_STCLPOLART  ');
        allinea_sequence('CPXX_PRFOESART  ','PRG_PRFOESART   ');
        allinea_sequence('CPXX_PRFOPESPAR ','PRG_PRFOPESPAR  ');
        allinea_sequence('CPXX_PRFOPOESAR ','PRG_PRFOPOESAR  ');
        allinea_sequence('CPXX_PRFOPOLART ','PRG_PRFOPOLART  ');
        allinea_sequence('CPXX_PRFORART   ','PRG_PRFORART    ');
        allinea_sequence('CPXX_PRFORPOLO  ','PRG_PRFORPOLO   ');
        allinea_sequence('CPXX_STFOESART  ','PRG_STFOESART   ');
        allinea_sequence('CPXX_STFOPESPAR ','PRG_STFOPESPAR  ');
        allinea_sequence('CPXX_STFOPOESAR ','PRG_STFOPOESAR  ');
        allinea_sequence('CPXX_STFOPOLART ','PRG_STFOPOLART  ');
        allinea_sequence('CPXX_STFORART   ','PRG_STFORART    ');
        allinea_sequence('CPXX_STFORPOLO  ','PRG_STFORPOLO   ');
        allinea_sequence('MGXX_PRESARPOLO ','PRG_PRESARPOLO  ');
        allinea_sequence('MGXX_PRGIACART  ','PRG_PRGIACART   ');
        allinea_sequence('MGXX_PRGIACARTM ','PRG_PRGIACARTM  ');
        allinea_sequence('MGXX_PRIMPORD   ','PRG_PRIMPORD    ');
        allinea_sequence('MGXX_PRPEARPOLO ','PRG_PRPEARPOLO  ');
        allinea_sequence('MGXX_STESARPOLO ','PRG_STESARPOLO  ');
        allinea_sequence('MGXX_STGIACART  ','PRG_STGIACART   ');
        allinea_sequence('MGXX_STGIACARTM ','PRG_STGIACARTM  ');
        allinea_sequence('MGXX_STIMPORD   ','PRG_STIMPORD    ');
        allinea_sequence('MGXX_STPEARPOLO ','PRG_STPEARPOLO  ');
        allinea_sequence('MGXX_DATIINVENT ','PRG_DATIINVENT  ');
        allinea_sequence('MGXX_DETVALMAG  ','PRG_DETVALMAG   ');
        allinea_sequence('MGXX_DOCRIGMOPR ','PRG_ELABORAZIONE');
        allinea_sequence('MGXX_INVENTARIO ','PRG_INVENTARIO  ');
        allinea_sequence('MGXX_INVENTMAT  ','PRG_INVENTMAT   ');
        allinea_sequence('MGXX_SCHEDAMAG  ','PRG_SCHEDAMAG   ');
        allinea_sequence('MGXX_VALABC     ','PRG_VALABC      ');

        dbms_output.put_line(chr(0));
        dbms_output.put_line('Elaborazione Terminata...');
end;
/
spool off;
