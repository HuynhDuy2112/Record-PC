@echo off
setlocal EnableDelayedExpansion

set "BASEDIR=C:\ProgramData\WinRC"
set "SERVER=10.0.0.10"
set "SHARE=Record_PC"
set "DEST_USER=" ::điền username    
set "DEST_PASS=" ::điền password
set "SUCCESS=C:\ProgramData\WinRC\src\post.success.txt"

del /f /q "%SUCCESS%" >nul 2>&1

:: Lấy IP 
set "MYIP="

for /f "tokens=2 delims=:" %%A in ('
    ipconfig ^| findstr /R /C:"IPv4.*192\.168\.0\."
') do (
    for /f "tokens=* delims= " %%B in ("%%A") do set "MYIP=%%B"
)

if "!MYIP!"=="" (
    for /f "tokens=2 delims=:" %%A in ('
        ipconfig ^| findstr /R /C:"IPv4.*10\.0\.0\."
    ') do (
        for /f "tokens=* delims= " %%B in ("%%A") do set "MYIP=%%B"
    )
)

if "!MYIP!"=="" (
    set "MYIP=%COMPUTERNAME%"
)

set "UNC=\\%SERVER%\%SHARE%\%MYIP%"


:: Check connect server
:: faild - 30s check lại cho đến khi true thì thực hiện action
:RETRY
echo [POST] Kiem tra server %SERVER%...

ping -n 1 %SERVER% >nul
if errorlevel 1 (
    echo [POST] Server OFF. Thu lai sau 30s...
    timeout /t 30 >nul
    goto RETRY
)

echo [POST] Ket noi share...
net use "\\%SERVER%\%SHARE%" "%DEST_PASS%" /user:"%DEST_USER%" /persistent:no >nul 2>&1
if errorlevel 1 (
    echo [POST] Loi ket noi share. Thu lai...
    timeout /t 30 >nul
    goto RETRY
)

if not exist "%UNC%" (
    md "%UNC%" >nul 2>&1
    if errorlevel 1 (
        echo [POST] Khong tao duoc folder tren server. Thu lai...
        net use "\\%SERVER%\%SHARE%" /delete >nul 2>&1
        timeout /t 30 >nul
        goto RETRY
    )
)

:: Post data lên server & xóa ở user
for /D %%F in ("%BASEDIR%\??-??-????") do (
    echo [POST] Dang gui %%~nxF ...

    robocopy "%%F" "%UNC%\%%~nxF" /E /R:3 /W:5 >nul
    if errorlevel 8 (
        echo [POST] Loi robocopy %%~nxF. Treo va thu lai...
        net use "\\%SERVER%\%SHARE%" /delete >nul 2>&1
        timeout /t 30 >nul
        goto RETRY
    )

    echo [POST] Gui OK → Xoa local %%~nxF
    rd /S /Q "%%F"
)

net use "\\%SERVER%\%SHARE%" /delete >nul 2>&1
echo OK > "%SUCCESS%"
echo [POST] HOAN TAT – Da tao post.success.txt

exit /b 0
