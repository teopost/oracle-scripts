set ORACLE_SID=ORCL
cd c:\hotbackup
sqlplus -s system/unimckion@orcl @hotbackup.sql
svrmgrl @backup_script.sql
pause
