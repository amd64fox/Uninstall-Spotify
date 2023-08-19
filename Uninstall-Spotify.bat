@echo off

setlocal enabledelayedexpansion

REM Reset permissions for Spotify Update folder
if exist "%localappdata%\Spotify\Update" (
    icacls "%localappdata%\Spotify\Update" /reset /T > NUL 2>&1
)

set a=0
set b=0

REM Uninstall Spotify if it exists
if exist "%appdata%\Spotify\Spotify.exe" (
    start "" /wait "%appdata%\Spotify\Spotify.exe" /UNINSTALL /SILENT
    set /a b=!b! + 1
)

timeout /t 1 > NUL 2>&1

REM Remove Spotify data folders
for %%d in ("%appdata%\Spotify" "%localappdata%\Spotify") do (
    if exist "%%d" (
        rd /s/q "%%d" > NUL 2>&1
        set /a b=!b! + 1
    )
)

REM Delete SpotifyUninstall.exe if it exists
if exist "%temp%\SpotifyUninstall.exe" (
    del /s /q  "%temp%\SpotifyUninstall.exe" > NUL 2>&1
    set /a b=!b! + 1
)

if !b! == 0 (
    echo Spotify not found
) else (
    echo Spotify removed
)

pause & exit
