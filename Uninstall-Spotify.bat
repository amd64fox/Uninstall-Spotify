@echo off
set PWSH="%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command
set RawGit='https://raw.githubusercontent.com/amd64fox/Uninstall-Spotify/refs/heads/main/core.ps1'
set JsDelivr='https://cdn.jsdelivr.net/gh/amd64fox/Uninstall-Spotify@refs/heads/main/core.ps1'
set TLS=[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12;

if "%1"=="e" goto :run

%PWSH% "([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)" | findstr "True" >nul

if %errorLevel% == 0 (
    goto :run
) else (
    %PWSH% "try { start wt 'cmd /c \"\"%~dpnx0\" e\"' -v RunAs } catch { start cmd '/c \"\"%~dpnx0\" e\"' -v RunAs }"
    exit
)

:run
if exist "%~dp0core.ps1" (
    %PWSH% "& { $(Get-Content '%~dp0core.ps1' -Raw) } | iex; exit $LASTEXITCODE"
) else (
    %PWSH% %TLS% "& { $(try { iwr -useb %RawGit% } catch { iwr -useb %JsDelivr% }) } | iex; exit $LASTEXITCODE"
)

exit