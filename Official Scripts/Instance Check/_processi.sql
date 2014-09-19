select vb.name NOME,
substr(vp.program,1,20)  PROCESSNAME,
vp.spid THREADID,
vs.sid SID
from v$session vs,v$process vp, v$bgprocess vb
where vb.paddr <> '00'
and          vb.paddr = vp.addr
and          vp.addr = vs.paddr;

/*

select 
 p.spid "Thread ID",
 b.name "Background Process",
 s.username "User Name",
 s.osuser "OS User",
 s.status "STATUS",
 s.sid "Session ID",
 s.serial# "Serial No.",
 s.program "OS Program"   
from 
     v$process p,
     v$bgprocess b,
     v$session s   
where 
    s.paddr = p.addr and b.paddr(+) = p.addr; 
    
*/