select 'ALTER '||decode(object_type,'PACKAGE BODY','PACKAGE',object_type) ||' '||object_name|| ' COMPILE;' OGGETTI_INVALIDI 
from user_objects where status = 'INVALID'
/
