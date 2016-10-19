CREATE OR REPLACE procedure write_clob_to_file ( p_tabella varchar2)
as
  file1 utl_file.file_type;
  l_buffer VARCHAR2 (32767);
  l_amount PLS_INTEGER := 32767;
  l_pos    PLS_INTEGER := 1;
  l_lg     PLS_INTEGER;
begin

        dbms_output.put_line('--- Inzio Drop');
   
        
     
        file1:= utl_file.fopen('EXT_SCRIPT','script_cattolica.sql','wb', max_linesize => l_amount);
      

        for cur_file in (select TESTO_CREA  as TESTO_CREA
                        from appoggio_script a
                       where (tabella = p_tabella or p_tabella = 'all')
                       --and rownum < 100
                       order by tabella)
        loop
              
            l_lg := dbms_lob.getlength(cur_file.TESTO_CREA);

            WHILE l_pos <= l_lg LOOP
                DBMS_LOB.read (cur_file.TESTO_CREA, l_amount, l_pos, l_buffer);

                utl_file.put_raw( file1, utl_raw.cast_to_raw(l_buffer)) ;


                 l_pos := l_pos + l_amount;
            END LOOP; 
            l_pos:=1;          
            utl_file.put_raw( file1, utl_raw.cast_to_raw(chr(13) || chr(10)));
            UTL_FILE.fflush(file1); 
  
        end loop;
        

    utl_file.fclose(file1);
    
    dbms_output.put_line('--- Fine');
    
end;
/
