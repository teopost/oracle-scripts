
SELECT   r.name "RB NAME ", p.pid "ORACLE PID",         
 p.spid "SYSTEM PID ", NVL (p.username, 'NO TRANSACTION') "OS USER",    
       p.terminal FROM v$lock l, v$process p, v$rollname r, v$session s 
	   WHERE    l.sid = s.sid(+) AND      s.paddr = p.addr
	    AND      TRUNC (l.id1(+)/65536) = r.usn 
		AND      l.type(+) = 'TX' 
		AND      l.lmode(+) = 6 ORDER BY r.name
		;