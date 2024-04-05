# Spotify Uninstaller for Windows

This script is designed to help you thoroughly remove the desktop version of Spotify from your Windows system.

## Usage

1. **Download**: Get the batch script from [here](https://raw.githack.com/amd64fox/Uninstall-Spotify/main/Uninstall-Spotify.bat).
2. **Run**: Double-click the downloaded `Uninstall-Spotify.bat` file to execute it.

## What the Script Does

The script executes the following steps:

1. **Permission Reset**: Resets permissions for the Spotify Update folder, if present.
2. **Silent Uninstallation**: Uninstalls Spotify silently if its executable is located in the AppData directory.
3. **AppData Cleanup**: Removes the Spotify AppData folder.
4. **LocalAppData Cleanup**: Clears the Spotify LocalAppData folder.
5. **Executable Deletion**: Deletes any SpotifyUninstall.exe file found.
6. **Completion Message**: Provides feedback on whether Spotify was successfully located and removed.

## Disclaimer

- **Caution**: Deploy this script at your own risk. Prior to execution, ensure you comprehend the actions it will take on your system. The author accepts no liability for any damage or loss arising from the use of this script.
