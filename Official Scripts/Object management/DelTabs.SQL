set heading off pagesize 0
spool c:\temp\delete.sql
select 'delete '||tname ||';' from tab where tabtype = 'TABLE';
spool off
@c:\temp\delete.sql

