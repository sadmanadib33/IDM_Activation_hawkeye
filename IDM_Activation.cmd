@echo off
setlocal DisableDelayedExpansion

::========================================================================================================================================

:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows
if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    if exist %SystemRoot%\Sysnative\cmd.exe (
        set "_cmdf=%~f0"
        setlocal EnableDelayedExpansion
        start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %*"
        exit /b
    )
)

:: Set Path variable, it helps if it is misconfigured in the system
set "SysPath=%SystemRoot%\System32"
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"

::========================================================================================================================================

cls
color 07

set _args=%*
if defined _args set _args=%_args:"=%
for %%A in (%_args%) do (
    if /i "%%A"=="-el"  set _elev=1
    if /i "%%A"=="/res" set Unattended=1&set activate=&set reset=1
    if /i "%%A"=="/act" set Unattended=1&set activate=1&set reset=
    if /i "%%A"=="/s"   set Unattended=1&set Silent=1
)

::========================================================================================================================================

set "_psc=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G

if defined Silent if not defined activate if not defined reset exit /b
if defined Silent call :begin >nul 2>&1 & exit /b

:begin

::========================================================================================================================================

if not exist "%_psc%" (
    echo Powershell is not installed in the system.
    echo Aborting...
    goto done2
)

if %winbuild% LSS 7600 (
    echo Unsupported OS version Detected.
    echo Project is supported only for Windows 7/8/8.1/10/11 and their Server equivalent.
    goto done2
)

::========================================================================================================================================

:: Elevate script as admin
if not defined _elev (
    %_psc% -Command "Start-Process cmd -ArgumentList '/c \"%~f0\" %*' -Verb RunAs"
    exit /b
)

::========================================================================================================================================

:: Check architecture and set paths accordingly
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "arch=x64"
) else (
    set "arch=x86"
)

if "%arch%"=="x64" (
    set "IDMan=%ProgramFiles(x86)%\Internet Download Manager\IDMan.exe"
) else (
    set "IDMan=%ProgramFiles%\Internet Download Manager\IDMan.exe"
)

set _temp=%SystemRoot%\Temp
set regdata=%SystemRoot%\Temp\regdata.txt
set "idmcheck=tasklist /fi "imagename eq idman.exe" | findstr /i "idman.exe" >nul"

::========================================================================================================================================

if defined Unattended (
    if defined reset goto _reset
    if defined activate goto _activate
)

:MainMenu

cls
title IDM Activator
mode 65, 25

:: Check firewall status
for %%# in (DomainProfile PublicProfile StandardProfile) do (
    for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\%%# /v EnableFirewall 2^>nul') do (
        if /i %%b equ 0x1 (set /a _ena+=1) else (set /a _dis+=1)
    )
)

if %_ena%==3 (
    set _status=Enabled
    set _col=%_Green%
)

if %_dis%==3 (
    set _status=Disabled
    set _col=%_Red%
)

if not %_ena%==3 if not %_dis%==3 (
    set _status=Status_Unclear
    set _col=%_Yellow%
)

echo:
echo:          ::: IDM Activator v0.7                       
echo:
echo:          ---------------------------------------------   
echo:          [1] Activate IDM                                
echo:          [2] Reset IDM Activation / Trial in Registry
call :_color2 %_White% "          [3] Toggle Windows Firewall  " %_col% "[%_status%]"
echo:          ---------------------------------------------   
echo:          [4] Readme                                      
echo:          [5] Homepage                                    
echo:          [6] Exit                                        
echo:
echo:       ---------------------------------------------------
call :_color2 %_White% "        " %_Green% "Enter a menu option in the Keyboard [1,2,3,4,5,6]"
choice /C:123456 /N
set _erl=%errorlevel%

if %_erl%==6 exit /b
if %_erl%==5 goto homepage
if %_erl%==4 call :readme&goto MainMenu
if %_erl%==3 call :_tog_Firewall&goto MainMenu
if %_erl%==2 goto _reset
if %_erl%==1 goto _activate
goto :MainMenu

:_tog_Firewall

if %_status%==Enabled (
    netsh AdvFirewall Set AllProfiles State Off >nul
) else (
    netsh AdvFirewall Set AllProfiles State On >nul
)
exit /b

:readme

set "_Readme=%SystemRoot%\Temp\Readme.txt"
if exist "%_Readme%" del /f /q "%_Readme%" >nul 2>&1
call :export txt "%_Readme%"
start notepad "%_Readme%"
timeout /t 2 >nul
del /f /q "%_Readme%" >nul 2>&1
exit /b

:export
%_psc% -Command "$f=[io.file]::ReadAllText('%~f0') -split ':%~1:.*`r`n'; [io.file]::WriteAllText('%~2',$f[1].Trim(),[System.Text.Encoding]::ASCII);"
exit /b

:_reset
if not defined Unattended (
    mode 93, 32
    %_psc% -Command "&{$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=31;$B.Height=300;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}"
)

echo:
set _error=

reg query "HKCU\Software\DownloadManager" "/v" "Serial" >nul 2>&1 && (
    %idmcheck% && taskkill /f /im idman.exe
)

if exist "%appdata%\DMCache\settings.bak" del /s /f /q "%appdata%\DMCache\settings.bak" >nul 2>&1

set "_action=call :delete_key"
call :reset

echo:
echo: ---------------------------------
if not defined _error (
    echo IDM Activation - Trial is successfully reset in the registry.
) else (
    echo Failed to completely reset IDM Activation - Trial.
)
goto done

:_activate
if not defined Unattended (
    mode 93, 32
    %_psc% -Command "&{$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=31;$B.Height=300;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}"
)

echo:
set _error=

if not exist "%IDMan%" (
    echo IDM [Internet Download Manager] is not Installed.
    echo You can download it from https://www.internetdownloadmanager.com/download.html
    goto done
)

ping -n 1 internetdownloadmanager.com >nul || (
    %_psc% -Command "$t = New-Object Net.Sockets.TcpClient;try{$t.Connect('internetdownloadmanager.com', 80)}catch{};$t.Connected" | findstr /i true 1>nul
)

if not [%errorlevel%]==[0] (
    echo Unable to connect to internetdownloadmanager.com, aborting...
    goto done
)

echo Internet is connected.

%idmcheck% && taskkill /f /im idman.exe

if exist "%appdata%\DMCache\settings.bak" del /s /f /q "%appdata%\DMCache\settings.bak" >nul 2>&1

set "_action=call :delete_key"
call :reset

set "_action=call :count_key"
call :register_IDM

echo:
if defined _derror call :f_reset & goto done

set lockedkeys=
set "_action=call :lock_key"
echo Locking registry keys...
call :action

if not defined _error if [%lockedkeys%] GEQ [7] (
    echo:
    echo: ---------------------------------
    echo IDM is successfully activated.
    echo:
    echo If fake serial screen appears, run activation option again. After that it won't appear anymore.
    goto done
)

call :f_reset

:done
echo:
echo: ---------------------------------
if defined Unattended (
    timeout /t 3 >nul
    exit /b
)

echo Press any key to return...
pause >nul
goto MainMenu

:done2
echo Press any key to exit...
pause >nul
exit /b

:homepage
cls
echo:
echo Going Home...
timeout /t 3 >nul
start https://github.com/NaeemBolchhi/IDM-Activator
goto MainMenu

:f_reset
echo:
echo: ---------------------------------
echo Error found, resetting IDM activation...
set "_action=call :delete_key"
call :reset
echo: ---------------------------------
echo Failed to activate IDM.
exit /b

:reset
set take_permission=
call :delete_queue
set take_permission=1
call :action
call :add_key
exit /b

:_rcont
reg add %reg% >nul 2>&1
call :_add_key
exit /b

:register_IDM
echo:
echo Applying registration details...

set /p "name=Set a name for the license (default: %username%): "
If not defined name set "name=%username%"
echo:

set "reg=HKCU\SOFTWARE\DownloadManager /v FName /t REG_SZ /d "%name%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v LName /t REG_SZ /d """ & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Email /t REG_SZ /d "info@tonec.com"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Serial /t REG_SZ /d "FOX6H-3KWH4-7TSIN-Q4US7"" & call :_rcont

echo Triggering a few downloads to create certain registry keys, please wait...

set "file=%_temp%\temp.png"
set _fileexist=
set _derror=

%idmcheck% && taskkill /f /im idman.exe

set link=https://www.internetdownloadmanager.com/images/idm_box_min.png
call :download
set link=https://www.internetdownloadmanager.com/register/IDMlib/images/idman_logos.png
call :download

timeout /t 3 >nul

set foundkeys=
call :action
if [%foundkeys%] GEQ [7] goto _skip

set link=https://www.internetdownloadmanager.com/pictures/idm_about.png
call :download
set link=https://www.internetdownloadmanager.com/languages/bengali.png
call :download

timeout /t 3 >nul

set foundkeys=
call :action
if not [%foundkeys%] GEQ [7] set _derror=1

:_skip
echo:
if not defined _derror (
    echo Required registry keys were created successfully.
) else (
    if not defined _fileexist echo Unable to download files with IDM.
    echo Failed to create required registry keys.
    echo Try again - disable Windows firewall with script options - check Read Me.
)

%idmcheck% && taskkill /f /im idman.exe
if exist "%file%" del /f /q "%file%" >nul 2>&1
exit /b

:download
set /a attempt=0
if exist "%file%" del /f /q "%file%" >nul 2>&1
start "" /B "%IDMan%" /n /d "%link%" /p "%_temp%" /f temp.png

:check_file
timeout /t 1 >nul
set /a attempt+=1
if exist "%file%" set _fileexist=1&exit /b
if %attempt% GEQ 20 exit /b
goto :check_file

:delete_queue
echo:
echo Deleting registry keys...
for %%# in (
    "HKCU\Software\DownloadManager /v FName"
    "HKCU\Software\DownloadManager /v LName"
    "HKCU\Software\DownloadManager /v Email"
    "HKCU\Software\DownloadManager /v Serial"
    "HKCU\Software\DownloadManager /v scansk"
    "HKCU\Software\DownloadManager /v tvfrdt"
    "HKCU\Software\DownloadManager /v radxcnt"
    "HKCU\Software\DownloadManager /v LstCheck"
    "HKCU\Software\DownloadManager /v ptrk_scdt"
    "HKCU\Software\DownloadManager /v LastCheckQU"
    "%HKLM%"
) do for /f "tokens=* delims=" %%A in ("%%~#") do (
    set "reg=%%A" & reg query !reg! >nul 2>&1 && call :delete_key
)
exit /b

:add_key
echo:
echo Adding registry key...
set "reg=%HKLM% /v AdvIntDriverEnabled2"
reg add %reg% /t REG_DWORD /d "1" /f >nul 2>&1

:_add_key
if [%errorlevel%]==[0] (
    echo Added - !reg!
) else (
    set _error=1
    echo Failed - !reg!
)
exit /b

:action
if exist %regdata% del /f /q %regdata% >nul 2>&1

reg query %CLSID% > %regdata%

%_psc% -Command "(gc %regdata%) -replace 'HKEY_CURRENT_USER', 'HKCU' | Out-File -encoding ASCII %regdata%"

for /f %%a in (%regdata%) do (
    for /f "tokens=%_tok% delims=\" %%# in ("%%a") do (
        echo %%#|findstr /r "{.*-.*-.*-.*-.*}" >nul && (set "reg=%%a" & call :scan_key)
    )
)

if exist %regdata% del /f /q %regdata% >nul 2>&1
exit /b

:scan_key
reg query %reg% 2>nul | findstr /i "LocalServer32 InProcServer32 InProcHandler32" >nul && exit /b

reg query %reg% 2>nul | find /i "H" >nul || (
    %_action%
    exit /b
)

for /f "skip=2 tokens=*" %%a in ('reg query %reg% /ve 2^>nul') do echo %%a|findstr /r /e "[^0-9]" >nul || (
    %_action%
    exit /b
)

for /f "skip=2 tokens=3" %%a in ('reg query %reg%\Version /ve 2^>nul') do echo %%a|findstr /r "[^0-9]" >nul || (
    %_action%
    exit /b
)

for /f "skip=2 tokens=1" %%a in ('reg query %reg% 2^>nul') do echo %%a| findstr /i "MData Model scansk Therad" >nul && (
    %_action%
    exit /b
)

for /f "skip=2 tokens=*" %%a in ('reg query %reg% /ve 2^>nul') do echo %%a| find /i "+" >nul && (
    %_action%
    exit /b
)

exit /b

:delete_key
reg delete %reg% /f >nul 2>&1

if not [%errorlevel%]==[0] if defined take_permission (
    %_psc% -Command "$A='%reg%';iex(([io.file]::ReadAllText('%~f0')-split':Own1\:.*')[1])&exit/b:Own1:; $path=$A[0]; $rk=$path-split'\\',2; $HK=gi -lit Registry::$($rk[0]) -fo; $s=[Security.Principal.SecurityIdentifier]; $w=new-object $s('S-1-5-32-544'); $o=$t.GetAccessControl(); $o.SetOwner($w); $t.SetAccessControl($o); $p=$c.GetAccessControl(2);$p.SetAccessRuleProtection(1,1); $p.ResetAccessRule($rar);"
    reg delete %reg% /f >nul 2>&1
)

if [%errorlevel%]==[0] (
    echo Deleted - !reg!
) else (
    set _error=1
    echo Failed - !reg!
)
exit /b

:lock_key
%_psc% -Command "$A='%reg%';iex(([io.file]::ReadAllText('%~f0')-split':Own1\:.*')[1])&exit/b:Own1:; $path=$A[0]; $rk=$path-split'\\',2; $HK=gi -lit Registry::$($rk[0]) -fo; $s=[Security.Principal.SecurityIdentifier]; $w=new-object $s('S-1-5-32-544'); $o=$t.GetAccessControl(); $o.SetOwner($w); $t.SetAccessControl($o); $p=$c.GetAccessControl(2);$p.SetAccessRuleProtection(1,1); $p.ResetAccessRule($rar);"
reg delete %reg% /f >nul 2>&1

if not [%errorlevel%]==[0] (
    echo Locked - !reg!
    set /a lockedkeys+=1
) else (
    set _error=1
    echo Failed - !reg!
)
exit /b

:count_key
set /a foundkeys+=1
exit /b

:_colorprep
if %winbuild% GEQ 10586 (
    for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"
    set "Red=41;97m"
    set "Gray=100;97m"
    set "Black=30m"
    set "Green=42;97m"
    set "Blue=44;97m"
    set "Yellow=43;97m"
    set "Magenta=45;97m"
    set "_Red=40;91m"
    set "_Green=40;92m"
    set "_Blue=40;94m"
    set "_White=40;37m"
    set "_Yellow=40;93m"
    exit /b
)

if not defined _BS for /f %%A in ('"prompt $H&for %%B in (1) do rem"') do set "_BS=%%A %%A"
set "_coltemp=%SystemRoot%\Temp"
set "Red=CF"
set "Gray=8F"
set "Black=00"
set "Green=2F"
set "Blue=1F"
set "Yellow=6F"
set "Magenta=5F"
set "_Red=0C"
set "_Green=0A"
set "_Blue=09"
set "_White=07"
set "_Yellow=0E"
exit /b
