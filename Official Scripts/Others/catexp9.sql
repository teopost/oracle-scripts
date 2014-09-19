
-- modificata da eseguire su sys di oracle 9.2.0.1 per far funzionare export del
-- client 8 su server 9.

-- Dopo la modifica
-- Export da server  9:

-- Export da client 9 eseguito correttamente, creato file exp9.dmp
-- Export da client 8 eseguito correttamente, creato file exp8.dmp
-- import di exp9.dmp con il client 9 .....
-- import di exp8.dmp con il client 8 ....


CREATE OR REPLACE view exu81rls 
(objown,objnam,policy,polown,polsch,polfun,stmts,chkopt,enabled,spolicy) 
AS select u.name, o.name, r.pname, r.pfschma, r.ppname, r.pfname, 
decode(bitand(r.stmt_type,1), 0,'', 'SELECT,') 
|| decode(bitand(r.stmt_type,2), 0,'', 'INSERT,') 
|| decode(bitand(r.stmt_type,4), 0,'', 'UPDATE,') 
|| decode(bitand(r.stmt_type,8), 0,'', 'DELETE,'), 
r.check_opt, r.enable_flag, 
DECODE(BITAND(r.stmt_type, 16), 0, 0, 1) 
from user$ u, obj$ o, rls$ r 
where u.user# = o.owner# 
and r.obj# = o.obj# 
and (uid = 0 or 
uid = o.owner# or 
exists ( select * from session_roles where role='SELECT_CATALOG_ROLE') 
); 

grant select on sys.exu81rls to public; 