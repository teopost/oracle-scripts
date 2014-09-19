rem -----------------------------------------------------------------------
rem Filename:   whoami.sql
rem Purpose:    Reports information about your current database context
rem Author:     Frank Naude (frank@onwe.co.za)
rem -----------------------------------------------------------------------

set termout off
store set store rep
set head off
set pause off
set termout on

select 'User: '|| user || ' on database ' || global_name,
       '  (term='||USERENV('TERMINAL')||
       ', audsid='||USERENV('SESSIONID')||')' as MYCONTEXT
from   global_name;

@store
set termout on