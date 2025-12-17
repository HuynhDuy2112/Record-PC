@echo off
setlocal EnableDelayedExpansion

:: Thu muc goc luu anh
set BASE=C:\ProgramData\WinRC

:LOOP

:: Lay ngay hien tai (YYYY-MM-DD)
for /f %%D in ('powershell -NoProfile -Command "Get-Date -Format dd-MM-yyyy"') do set CURDATE=%%D

:: Lay gio hien tai
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format HH-mm-ss"') do set CURTIME=%%T

:: Tao thu muc theo ngay
set TODAY=%BASE%\%CURDATE%
if not exist "%TODAY%" mkdir "%TODAY%"

:: Ten file
set FILE=%TODAY%\%CURDATE%_%CURTIME%.jpg

:: Chup man hinh
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Add-Type -AssemblyName System.Windows.Forms; ^
 Add-Type -AssemblyName System.Drawing; ^
 $screen=[System.Windows.Forms.SystemInformation]::VirtualScreen; ^
 $bmp=New-Object System.Drawing.Bitmap $screen.Width,$screen.Height; ^
 $gfx=[System.Drawing.Graphics]::FromImage($bmp); ^
 $gfx.CopyFromScreen($screen.Left,$screen.Top,0,0,$bmp.Size); ^
 $bmp.Save('%FILE%',[System.Drawing.Imaging.ImageFormat]::Jpeg); ^
 $gfx.Dispose(); ^
 $bmp.Dispose();"

:: Cho 60 giay
timeout /t 60 /nobreak >nul

goto LOOP
