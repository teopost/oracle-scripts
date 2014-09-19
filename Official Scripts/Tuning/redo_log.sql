/*
If the ratio of MISSES to GETS exceeds 1%, 
or the ratio of IMMEDIATE_MISSES to (IMMEDIATE_GETS + IMMEDIATE_MISSES) 
exceeds 1%, there is latch contention. 
*/


SELECT
	substr(ln.name, 1, 20), 
	gets,
	misses,
        (gets - misses)/gets,
	immediate_gets,
	immediate_misses
--        ((immediate_gets + immediate_misses ) - immediate_misses)/immediate_gets
FROM 
v$latch l, 
v$latchname ln 
WHERE   ln.name in ('redo allocation', 'redo copy') 
                and ln.latch# = l.latch#; 



/*

The statistic 'redo log space requests' represents the number
 of times that the background was requested to allocate space
 in the redo log file. 

It does not represent waiting for space
 in the log buffer or for LGWR to finish doing a write.

 The only way to get more disk space is to do a log switch
--which you note is occurring at the time. 

This statistic gives an indication of how many 
times a user process waited for space in the redo log.

 The statistic 'redo log space wait time' represents 
the amount of time waited for space in the redo log 
in 1/100's of a second. 

*/

SELECT name, value 
   FROM v$sysstat 
   WHERE name = 'redo log space requests'; 
