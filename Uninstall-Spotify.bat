@echo off

set a=0
set b=0

if exist %localappdata%\Spotify\Update (
    icacls %localappdata%\Spotify\Update /reset /T > NUL 2>&1
)

if exist %appdata%\Spotify\Spotify.exe ( 
    start "" /wait %appdata%\Spotify\Spotify.exe /UNINSTALL /SILENT
    set /a b=%a% + 1
)

TIMEOUT /T 1 > NUL 2>&1 

if exist %appdata%\Spotify (
    rd /s/q %appdata%\Spotify > NUL 2>&1
    set /a b=%a% + 1
)

if exist %localappdata%\Spotify (
    rd /s/q %localappdata%\Spotify > NUL 2>&1
    set /a b=%a% + 1
)

if exist %temp%\SpotifyUninstall.exe (
    del /s /q  %temp%\SpotifyUninstall.exe > NUL 2>&1
    set /a b=%a% + 1
)

if %b% == 0 echo Spotify not found
if %b% NEQ 0 echo Spotify removed
pause