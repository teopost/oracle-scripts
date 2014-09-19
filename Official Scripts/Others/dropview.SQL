spool c:\temp\~view.sql
select 'drop view '|| tname ||';' from tab where tabtype = 'VIEW'
/
@c:\temp\~view.sql
