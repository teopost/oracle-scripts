SET HEADING OFF
SET ECHO OFF
SET FEEDBACK OFF
SET PAGESIZE 0
set numwidth 10
SELECT uv.view_name SORT1, 0 SORT2, 0 SORT3, 0 SORT4,
'create or replace view '||uv.view_name ||' ('
from dba_views uv
WHERE uv.owner = upper('&2')
and uv.view_name = upper('&1')
union all
SELECT utc.view_name SORT1, utc.column_id SORT2, 0 SORT3, 0 SORT4,
utc.column_name
from dba_tab_columns
WHERE utc.owner = upper('&2')
and utc.table_name = upper('&1')
and utc.column_id = 1
union all
SELECT utc.view_name SORT1, utc.column_id SORT2, 0 SORT3, 0 SORT4,
' , '||utc.column_name
from dba_tab_columns
WHERE utc.owner = upper('&2')
and utc.table_name = upper('&1')
and utc.column_id <> 1
SELECT uv.view_name SORT1, 999 SORT2, 0 SORT3, 0 SORT4,
' )'
from dba_views uv
WHERE uv.owner = upper('&2')
and uv.view_name = upper('&1')
ORDER BY 1, 2, 3, 4;
SELECT uv.text
from dba_views uv
WHERE uv.owner = upper('&2')
and uv.view_name = upper('&1')
;
SELECT uv.view_name SORT1, 999 SORT2, 0 SORT3, 0 SORT4,
' ;'
from dba_views uv
WHERE uv.owner = upper('&2')
and uv.view_name = upper('&1')
; 