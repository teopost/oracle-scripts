


ALTER SESSION SET SQL_TRACE=TRUE;
alter system set timed_statistics= true


-- se vuoi tracciare le biund variables
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 4';

-- oppure 

ALTER SYSTEM SET EVENTS '10046 trace name context forever, level 12';


select sid, serial#, username from v$session where sid = 80


exec sys.dbms_system.set_sql_trace_in_session ( 80, 20044, true);


exec sys.dbms_system.set_sql_trace_in_session ( 93, 9006, false);


-- stop trace
ALTER SYSTEM SET EVENTS '10046 trace name context off';


select * from v$parameter 


select * from v$session_event