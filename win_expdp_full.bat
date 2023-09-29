@echo off
SET ORACLE_SID=STEP
SET HNAME=ITMILPPIMDB01
SET BASE_FOLDER="K:\dbexports"
SET DUMPFILE_FOLDER="K:\dbexports"
SET ARCHIVE_PROGRAM="C:\Program Files\7-Zip\7z.exe"
SET DATAPUMP_DIR="dbbackup"

setlocal enabledelayedexpansion

rem Ottieni la data e l'ora correnti
for /f "delims=" %%A in ('wmic OS Get localdatetime ^| find "."') do set datetime=%%A

rem Estrai l'anno, il mese, il giorno, l'ora e il minuto dalla data corrente
set year=!datetime:~0,4!
set month=!datetime:~4,2!
set day=!datetime:~6,2!
set hour=!datetime:~8,2!
set minute=!datetime:~10,2!

rem Costruisci il nome del file di log con il timestamp
set exportfilename=%year%-%month%-%day%_%hour%-%minute%_%ORACLE_SID%_FULLEXP.DMP
set logfilename=%year%-%month%-%day%_%hour%-%minute%_%ORACLE_SID%_FULLEXP.LOG

REM Script begin
expdp '/ as sysdba' full=y directory=%DATAPUMP_DIR% dumpfile=%exportfilename% logfile=%logfilename% flashback_time=SYSTIMESTAMP

endlocal




@echo off
setlocal enabledelayedexpansion

rem Definisci la directory in cui desideri eliminare i file
set "directory=%DUMPFILE_FOLDER%"

rem Definisci il numero massimo di file da mantenere (in questo caso, 7)
set "keep=7"

rem Elabora tutti i file nella directory specificata e crea un elenco ordinato per data
for /f "delims=" %%A in ('dir /b /a-d /o-d "%directory%\*"') do (
    set /a "count+=1"
    if !count! gtr %keep% (
        echo Eliminazione di "%%A"
        del /q "%directory%\%%A"
    )
)

endlocal




EXIT 0
