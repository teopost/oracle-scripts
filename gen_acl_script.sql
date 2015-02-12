select
'BEGIN DBMS_NETWORK_ACL_ADMIN.CREATE_ACL
(acl => '''||acl||''','||'principal => '''||PRINCIPAL||''','||'is_grant => ' ||
IS_GRANT||','||'privilege => '''||PRIVILEGE||'''); commit; END;'
from dba_NETWORK_ACL_PRIVILEGES
where privilege='connect'
union all
select
'BEGIN DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE
(acl => '''||acl||''','||'principal => '''||PRINCIPAL||''','||'is_grant => ' ||
IS_GRANT||','||'privilege => '''||PRIVILEGE||'''); commit; END;'
from dba_NETWORK_ACL_PRIVILEGES
where privilege<>'connect'
union all
select
'BEGIN DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (acl => '''||acl||''', '||
'host => '''||host||''', '||
'lower_port => '||lower_port||', '||
'upper_port => '||upper_port||'); commit; END;'
from dba_NETWORK_ACLS
/
