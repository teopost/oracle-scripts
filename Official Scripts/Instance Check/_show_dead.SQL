REM  sho_dead.sql
REM  Show deadlocks 
REM
column Username format  A15 
column Sid      format  9990    heading SID 
column Type     format  A4 
column Lmode    format  990     heading 'HELD' 
column Request  format  990     heading 'REQ' 
column Id1      format  9999990 
column Id2      format  9999990 
break on Id1 skip 1 dup 
select SN.Username, 
       sn.osuser,
       M.Sid, 
       M.Type, 
       DECODE(M.Lmode, 0, 'None', 
                       1, 'Null', 
                       2, 'Row Share', 
                       3, 'Row Excl.', 
                       4, 'Share', 
                       5, 'S/Row Excl.', 
                       6, 'Exclusive', 
                Lmode, LTRIM(TO_CHAR(Lmode,'990'))) Lmode, 
       DECODE(M.Request, 0, 'None', 
                         1, 'Null', 
                         2, 'Row Share', 
                         3, 'Row Excl.', 
                         4, 'Share', 
                         5, 'S/Row Excl.', 
                         6, 'Exclusive', 
                Request, LTRIM(TO_CHAR(M.Request, 
                                '990'))) Request, 
        M.Id1, M.Id2 
  from V$SESSION SN, V$LOCK M 
 where (SN.Sid = M.Sid 
          and M.Request != 0) 
    or (SN.Sid = M.Sid 
          and M.Request = 0 and Lmode != 4 
          and (id1, id2) in
           (select S.Id1, S.Id2 
              from V$LOCK S 
             where Request != 0 
               and S.Id1 = M.Id1 
               and S.Id2 = M.Id2)  ) 
order by Id1, Id2, M.Request; 

clear breaks 
clear columns

