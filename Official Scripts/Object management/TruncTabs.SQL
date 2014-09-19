set heading off pagesize 0
spool c:\temp\truncate.sql
select 'truncate table '||tname ||';' from tab where tabtype = 'TABLE';
spool off
@c:\temp\truncate.sql

