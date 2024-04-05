@echo off
setlocal enabledelayedexpansion

REM Reset permissions for Spotify Update folder.
if exist "%localappdata%\Spotify\Update" icacls "%localappdata%\Spotify\Update" /reset /T > NUL 2>&1

set actions=0

REM Uninstall Spotify if it exists.
if exist "%appdata%\Spotify\Spotify.exe" (
    start "" /wait "%appdata%\Spotify\Spotify.exe" /UNINSTALL /SILENT
    set /a actions+=1
    timeout /t 1 > NUL 2>&1
)

REM Remove Spotify data folders.
for %%d in ("%appdata%\Spotify" "%localappdata%\Spotify") do (
    if exist "%%d" (
        rd /s/q "%%d" > NUL 2>&1
        set /a actions+=1
    )
)

REM Delete SpotifyUninstall.exe if it exists.
if exist "%temp%\SpotifyUninstall.exe" (
    del /s /q  "%temp%\SpotifyUninstall.exe" > NUL 2>&1
    set /a actions+=1
)

echo %actions% | findstr "^0$" > nul && (
    echo Spotify is not installed or not found.
) || (
    echo Spotify has been successfully uninstalled.
)

pause & exit
