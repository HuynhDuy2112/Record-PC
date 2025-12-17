@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

set "SRC=D:\Record_PC"
set "SERVER=\\192.168.0.254\data\IT\RECORD_PC"
set "MAP=C:\Users\PC\Documents\record_pc_src\updata\mapusername.txt"

set "USER=" ::điền username
set "PASS=" ::điền password

:: Connect NAS
net use \\192.168.0.254\data /user:%USER% %PASS% /persistent:no >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Khong ket noi duoc server
    exit /b 1
)

:: Chuyển tên folder
for /f "usebackq tokens=1,2 delims=|" %%A in ("%MAP%") do (

    set "IP=%%A"
    set "PCNAME=%%B"

    rem ==== LOCAL LUÔN LÀ IP ====
    if exist "%SRC%\!IP!" (

        echo =========================================
        echo [POST] IP local: !IP!
        echo [POST] Ten tren server: !PCNAME!

        rem ==== SERVER DÙNG TÊN MÁY ====
        set "DEST=%SERVER%\!PCNAME!"

        if not exist "!DEST!" (
            echo [POST] Tao folder server !PCNAME!
            md "!DEST!" >nul 2>&1
            if errorlevel 1 (
                echo [ERROR] Khong tao duoc folder server
                goto FAIL
            )
        )

        rem ==== COPY TOÀN BỘ FOLDER NGÀY ====
        for /D %%D in ("%SRC%\!IP!\??-??-????") do (
            echo [POST] Dang gui %%~nxD

            robocopy "%%D" "!DEST!\%%~nxD" /E /R:3 /W:5 >nul
            if errorlevel 8 (
                echo [ERROR] Loi robocopy %%~nxD
                goto FAIL
            )

            rem ==== COPY OK → XÓA FOLDER NGÀY ====
            echo [POST] Xoa local %%~nxD
            rd /S /Q "%%D"
        )

        rem ==== NEU IP KHONG CON FOLDER CON → XOA IP ====
        dir "%SRC%\!IP!\??-??-????" /A:D >nul 2>&1
        if errorlevel 1 (
            echo [POST] Folder IP rong → Xoa %SRC%\!IP!
            rd /S /Q "%SRC%\!IP!"
        )
    )
)

goto END

:FAIL
echo [POST] That bai → KHONG xoa du lieu local
net use \\192.168.0.254\data /delete >nul 2>&1
exit /b 1

:END
net use \\192.168.0.254\data /delete >nul 2>&1
echo [POST] Hoan tat
exit /b 0
