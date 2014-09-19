set echo on
spool backup_script.log
connect internal@orcl
host echo *** Inizio Backup Tablespace :SYSTEM
alter tablespace SYSTEM begin backup;
spool off
host ocopy E:\ORACLE\ORADATA\ORCL\SYSTEM01.DBF c:\temp
alter tablespace SYSTEM end backup;

--
host echo *** Inizio Backup Tablespace :RBS
alter tablespace RBS begin backup;
host ocopy E:\ORACLE\ORADATA\ORCL\RBS01.DBF c:\temp
host ocopy E:\ORACLE\ORADATA\ORCL\RBS02.DBF c:\temp
alter tablespace RBS end backup;
--
host echo *** Inizio Backup Tablespace :USERS
alter tablespace USERS begin backup;
host ocopy E:\ORACLE\ORADATA\ORCL\USERS01.DBF c:\temp
host ocopy E:\ORACLE\ORADATA\ORCL\USERS02.DBF c:\temp
host ocopy E:\ORACLE\ORADATA\ORCL\USERS03.DBF c:\temp
host ocopy E:\ORACLE\ORADATA\ORCL\USERS04.DBF c:\temp
host ocopy E:\ORACLE\ORADATA\ORCL\USERS05.DBF c:\temp
alter tablespace USERS end backup;
--
host echo *** Inizio Backup Tablespace :TEMP
alter tablespace TEMP begin backup;
host ocopy E:\ORACLE\ORADATA\ORCL\TEMP01.DBF c:\temp
alter tablespace TEMP end backup;
--
host echo *** Inizio Backup Tablespace :TOOLS
alter tablespace TOOLS begin backup;
host ocopy E:\ORACLE\ORADATA\ORCL\TOOLS01.DBF c:\temp
alter tablespace TOOLS end backup;
--
host echo *** Inizio Backup Tablespace :INDX
alter tablespace INDX begin backup;
host ocopy E:\ORACLE\ORADATA\ORCL\INDX01.DBF c:\temp
alter tablespace INDX end backup;
--
host echo *** Inizio Backup Tablespace :MACERATA_MIG
alter tablespace MACERATA_MIG begin backup;
host ocopy E:\ORACLE\ORADATA\ORCL\MACERATA_MIG01.DBF c:\temp
host ocopy E:\ORACLE\ORADATA\ORCL\MACERATA_MIG02.DBF c:\temp
host ocopy E:\ORACLE\ORADATA\ORCL\MACERATA_MIG03.DBF c:\temp
alter tablespace MACERATA_MIG end backup;
--
host echo *** Inizio Backup Tablespace :BLOB_FILE
alter tablespace BLOB_FILE begin backup;
host ocopy E:\ORACLE\ORADATA\ORCL\BLOB01.DBF c:\temp
host ocopy E:\ORACLE\ORADATA\ORCL\BLOB02.DBF c:\temp
alter tablespace BLOB_FILE end backup;
--
prompt *** Inizio Backup Control file
alter database backup controlfile to 'c:\temp\control.ctl' reuse;
alter system switch logfile;
alter database backup controlfile to trace;
host copy E:\ORACLE\ORADATA\ORCL\REDO01.LOG  c:\temp
host copy E:\ORACLE\ORADATA\ORCL\REDO02.LOG  c:\temp
host copy E:\ORACLE\ORADATA\ORCL\REDO03.LOG  c:\temp
host copy C:\Oracle\oradata\ORCL\archive\*.arc c:\temp
host del C:\Oracle\oradata\ORCL\archive\*.arc
spool off
exit
