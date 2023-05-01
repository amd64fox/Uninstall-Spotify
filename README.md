# Uninstall Spotify for Windows

* Just download and run [Uninstall-Spotify.bat](https://raw.githack.com/amd64fox/Uninstall-Spotify/main/Uninstall-Spotify.bat)

* Or, run this command in PowerShell
```
Invoke-WebRequest -Uri https://github.com/amd64fox/Uninstall-Spotify/raw/main/Uninstall-Spotify.bat -OutFile Uninstall-Spotify.bat; Start-Process -FilePath "Uninstall-Spotify.bat" -Wait; Remove-Item -Path "Uninstall-Spotify.bat"
```