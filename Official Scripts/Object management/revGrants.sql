-- eseguire sullo schema clonato del cliente per creare lo script
-- eseguire poi lo script creato sempre sullo schema clonato

set feedback off verify off HEADING OFF
SPOOL C:\TEMP\GRANTS.SQL
select 'grant all on ' || tname || ' to public;' from tab where tabtype = 'TABLE';
SPOOL OFF


