SELECT DISTINCT 
                To_char(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || chr(13) || chr(10)
                || ' User ' 
                || S1.username 
                || '@' 
                || S1.machine 
                || ' ( INST=' 
                || S1.inst_id 
                || ' SID=' 
                || S1.sid 
                || ' SERIAL=' 
                || S1.serial#
                || ' OSUSER=' 
                || s1.osuser 
                || ' ) ' || chr(13) || chr(10)
                || 'with the statement: '  || chr(13) || chr(10)
                || '  ' || sqlt2.sql_text || chr(13) || chr(10)
                || 'is blocking the SQL statement for ' ||L1.ctime ||' seconds on ' || S2.username || '@' || S2.machine || ' ( INST='|| S2.inst_id || ' SID=' || S2.sid || ' OSUSER=' || s2.osuser || ' ) ' || chr(13) || chr(10)
                || 'blocked SQL -> ' || chr(13) || chr(10)
                || '  ' || sqlt1.sql_text || chr(13) || chr(10)
                || 'kill statement:' || chr(13) || chr(10)
                || 'alter system kill session ''' || S1.sid ||','|| S1.serial# || ',' || '@' ||  S1.inst_id  ||''' immediate;' AS blocking_status
FROM   gv$lock L1, 
       gv$session S1, 
       gv$lock L2, 
       gv$session S2, 
       gv$sql sqlt1, 
       gv$sql sqlt2 
WHERE  S1.sid = L1.sid 
       AND S2.sid = L2.sid 
       AND S1.inst_id = L1.inst_id 
       AND S2.inst_id = L2.inst_id 
       AND L1.BLOCK > 0 
       AND L2.request > 0 
       AND sqlt1.sql_id = s2.sql_id 
       AND sqlt2.sql_id = s1.prev_sql_id 
       AND L1.id1 = L2.id1 
       AND L1.id2 = L2.id2 
      -- AND L1.ctime > 300; 
