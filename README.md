# Uninstall Spotify for Windows

If you're looking to uninstall Spotify from your Windows system, you can use the provided batch script.

## Usage

1. Download the batch script: [Uninstall-Spotify.bat](https://raw.githack.com/amd64fox/Uninstall-Spotify/main/Uninstall-Spotify.bat).
2. Double-click the downloaded `Uninstall-Spotify.bat` file to run it.

## Script Details

The script performs the following actions:

1. Resets permissions for the Spotify Update folder, if it exists.
2. Uninstalls Spotify using a silent uninstallation process, if the executable is found in the AppData directory.
3. Removes the Spotify AppData folder.
4. Removes the Spotify LocalAppData folder.
5. Deletes any SpotifyUninstall.exe if found.
6. Displays a message based on whether Spotify was found and removed or not.

## Disclaimer

Use this script at your own risk. Make sure you understand the actions it will perform on your system before running it. The author of this script is not responsible for any damage or loss caused by its usage.
