@echo off
@set iasver=1.2
@setlocal DisableDelayedExpansion

::============================================================================
::   IDM Activation Script (IAS)
::   Homepages: https://github.com/sadmanadib33/IDM_Activation/
::       Email: sadmanadib33@gmail.com
::============================================================================

:: Parameters for script
set _activate=0
set _freeze=0
set _reset=0

:: Check for parameters
if /i "%~1"=="/act" set _activate=1
if /i "%~1"=="/frz" set _freeze=1
if /i "%~1"=="/res" set _reset=1

:: Set Path variable
set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%PATH%"
)

:: Elevate script if not running as Admin
:: Ensures compatibility with Windows 11's UAC restrictions
:CheckAdmin
openfiles >nul 2>&1
if '%errorlevel%' NEQ '0' (
    echo This script requires administrator privileges. Please run as Administrator.
    exit /b
)

:: Check Windows version
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G

:: Ensure Windows 7/8/8.1/10/11
if %winbuild% LSS 7600 (
echo Unsupported OS version detected [%winbuild%]. Supported for Windows 7/8/8.1/10/11.
goto :done
)

:: Check if PowerShell exists
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" (
    echo Unable to find powershell.exe in the system.
    goto :done
)

:: Initialize and prepare for action
cls
title IDM Activation Script %iasver%
echo Initializing...

:: Get user SID
set _sid=
for /f "delims=" %%a in ('powershell.exe "[System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value"') do set _sid=%%a

:: Check if SID was retrieved
if not defined _sid (
echo Error: Could not retrieve User Account SID. Aborting...
goto :done
)

:: Begin Activation or Freezing Process
if %_reset%==1 goto :_reset
if %_activate%==1 goto :_activate
if %_freeze%==1 goto :_freeze

:: Main menu
:MainMenu
cls
echo [1] Activate IDM
echo [2] Freeze IDM Trial
echo [3] Reset Activation
echo [4] Help
echo [0] Exit
set /p choice="Choose an option: "
if '%choice%'=='1' goto :_activate
if '%choice%'=='2' goto :_freeze
if '%choice%'=='3' goto :_reset
if '%choice%'=='4' goto :Help
if '%choice%'=='0' exit /b

:_activate
cls
echo Activating IDM...
:: Add registry keys for activation
set "regKey=HKCU\SOFTWARE\DownloadManager"
reg add "%regKey%" /v FName /t REG_SZ /d "John" /f
reg add "%regKey%" /v LName /t REG_SZ /d "Doe" /f
reg add "%regKey%" /v Email /t REG_SZ /d "john.doe@idm.com" /f
reg add "%regKey%" /v Serial /t REG_SZ /d "XXXX-XXXX-XXXX-XXXX" /f
echo Activation completed!
goto :done

:_freeze
cls
echo Freezing IDM Trial...
:: Add freeze trial registry key
reg add "HKCU\SOFTWARE\DownloadManager" /v tvfrdt /t REG_SZ /d "99999999" /f
echo Trial period frozen!
goto :done

:_reset
cls
echo Resetting IDM activation and trial...
:: Reset registry keys
reg delete "HKCU\SOFTWARE\DownloadManager" /f
echo Activation and trial reset completed!
goto :done

:Help
start https://github.com/sadmanadib33/IDM_Activation/
goto :MainMenu

:done
pause
exit /b
