$paths = @{
    RoamingFolder      = Join-Path $env:APPDATA "Spotify"
    LocalFolder        = Join-Path $env:LOCALAPPDATA "Spotify"
    RoamingFolderSpice = Join-Path $env:APPDATA "spicetify"
    LocalFolderSpice   = Join-Path $env:LOCALAPPDATA "spicetify"
    UninstallExe       = Join-Path ([System.IO.Path]::GetTempPath()) "SpotifyUninstall.exe"
    TempSearch         = Join-Path ([System.IO.Path]::GetTempPath()) "SpotX_Temp*"
    DesktopShortcut    = Join-Path $env:USERPROFILE "Desktop\Spotify.lnk"
    StartMenuShortcut  = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Spotify.lnk"
}

$registryKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Spotify"
    "HKCU:\Software\Spotify"
    "HKCU:\Software\Classes\spotify"
    "HKCU:\Software\Microsoft\Internet Explorer\Low Rights\ElevationPolicy\{5C0D11B8-C5F6-4be3-AD2C-2B1A3EB94AB6}"
    "HKCU:\Software\Microsoft\Internet Explorer\Low Rights\DragDrop\{5C0D11B8-C5F6-4be3-AD2C-2B1A3EB94AB6}"
)

$registryValue = @(
    @{
        Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Name = "Spotify Web Helper"
    }
    @{
        Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Name = "Spotify"
    }
)

$removedItems = 0
$errorMessages = @()
$ieCachePath = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\INetCache\IE"

function Find-ItemsToRemove {
    $foundItems = @{
        FilesFolders    = @()
        RegistryKeys    = @()
        RegistryValues  = @()
        StoreApp        = $null
        TempSearchFiles = @()
        IeCacheFiles    = @()
    }

    $sortedItems = $paths.GetEnumerator() | Where-Object { $_.Key -ne "TempSearch" } | ForEach-Object {
        if (Test-Path $_.Value) {
            Get-Item $_.Value
        }
    } | Sort-Object @{Expression = { -not $_.PSIsContainer } }, @{Expression = { $_.Extension -ne ".lnk" } }
    
    $foundItems.FilesFolders = $sortedItems.FullName

    $foundItems.TempSearchFiles = @(Get-ChildItem -Path $paths.TempSearch -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)

    $foundItems.IeCacheFiles = @(Get-ChildItem -Path $ieCachePath -Force -Recurse -Filter "SpotifyFullSetup*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)

    $registryKeys | ForEach-Object {
        if (Test-Path $_) { $foundItems.RegistryKeys += $_ }
    }

    $registryValue | ForEach-Object {
        if (Get-ItemProperty -Path $_.Path -Name $_.Name -ErrorAction SilentlyContinue) {
            $foundItems.RegistryValues += $_
        }
    }

    $foundItems.StoreApp = Get-AppxPackage -Name "SpotifyAB.SpotifyMusic" -ErrorAction SilentlyContinue	 

    return $foundItems
}

function Remove-ItemSafely {
    param([string]$Path)
    
    if (Test-Path -LiteralPath $Path) {
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            Write-Host "Removed: $Path"
            return 1
        }
        catch {
            $script:errorMessages += "Failed to remove $Path : $($_.Exception.Message)"
            return 0
        }
    }
    return 0
}

function Remove-FoundItems {
    param($foundItems)
    
    $count = 0
	
    if ($foundItems.StoreApp) {
        try {
            $ProgressPreference = 'SilentlyContinue'
            Remove-AppxPackage -Package $foundItems.StoreApp.PackageFullName -ErrorAction Stop
            Write-Host "Removed: Spotify Store version"
            $count++
        }
        catch {
            $script:errorMessages += "Failed to remove Store app: $_"
        }
    }
	
    # Remove files/folders
    $foundItems.FilesFolders + $foundItems.TempSearchFiles + $foundItems.IeCacheFiles | ForEach-Object {
        $count += Remove-ItemSafely -Path $_
    }

    # Remove registry keys
    $foundItems.RegistryKeys | ForEach-Object {
        try {
            Remove-Item -Path $_ -Recurse -Force -ErrorAction Stop
            Write-Host "Removed: $_"
            $count++
        }
        catch {
            $script:errorMessages += "Failed to remove registry key $_ : $_"
        }
    }

    # Remove registry values
    $foundItems.RegistryValues | ForEach-Object {
        try {
            Remove-ItemProperty -Path $_.Path -Name $_.Name -Force -ErrorAction Stop
            Write-Host "Removed: $($_.Path)\value=$($_.Name)"
            $count++
        }
        catch {
            $script:errorMessages += "Failed to remove registry value $($_.Name) : $_"
        }
    }

    return $count
}

function Get-RemovalSummary {
    if ($errorMessages.Count -gt 0 -or $removedItems -gt 0) {
        if ($removedItems -gt 0) {
            Write-Host "`nCleanup completed: removed $removedItems items"
        }

        if ($errorMessages.Count -gt 0) {
            Write-Host "`nErrors encountered ($($errorMessages.Count)):"
            $errorMessages | ForEach-Object { Write-Warning $_ }
            Write-Host "`nSome items may require manual removal."
        }
    }
    else {
        Write-Host "No traces of Spotify were detected"
    }

    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "`nPress any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Stop-SpotifyProcesses {
    param(
        [int]$maxAttempts = 5,
        [int]$retryDelay = 1000
    )

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $processes = Get-Process -Name "Spotify","SpotifyLauncher","SpotifyUninstall" -ErrorAction SilentlyContinue
        if (-not $processes) { break }

        $processes | ForEach-Object {
            try {
                Stop-Process -Id $_.Id -Force -ErrorAction Stop
            }
            catch {
                $script:errorMessages += "Failed to stop process $($_.Name) (PID: $($_.Id)): $_"
            }
        }
        Start-Sleep -Milliseconds $retryDelay
    }
}

function Reset-TargetACLs {
    param(
        [Parameter(Mandatory)]
        $foundItems
    )
    
    $aclPaths = $foundItems.FilesFolders + $foundItems.TempSearchFiles + $foundItems.IeCacheFiles
    
    foreach ($path in $aclPaths) {
        if (Test-Path -Path $path) {
            try {
                Write-Verbose "Resetting ACLs for: $path"
                $result = icacls $path /reset /T /Q
                if ($LASTEXITCODE -ne 0) {
                    throw "icacls failed with exit code $LASTEXITCODE"
                }
            }
            catch {
                Write-Warning "Failed to reset ACLs for $path : $_"
            }
        }
    }
}

try {
    # Stop all running Spotify processes before cleanup
    Stop-SpotifyProcesses -retryDelay 500

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Import-Module Appx -UseWindowsPowerShell -WarningAction SilentlyContinue
    }

    Write-Host "Search items..."
    Write-Host
    $itemsToRemove = Find-ItemsToRemove
    $maxAttempts = 5
    $attempt = 0

    do {
        $attempt++
		
        # Reset access control lists (ACLs) to ensure proper file/folder access
        Reset-TargetACLs -foundItems $itemsToRemove

        # Remove all identified Spotify-related items (files, registry entries, etc.)
        $removedItems += Remove-FoundItems -foundItems $itemsToRemove

        # Scan again for any remaining items that need cleanup
        $itemsToRemove = Find-ItemsToRemove

        # Exit loop if maximum attempts reached to prevent infinite loops
        if ($attempt -ge $maxAttempts) {
            Write-Host "The maximum number of attempts $($maxAttempts) has been reached. Terminating the loop"
            break
        }
		
        if ($attempt -ge 1) { Start-Sleep -Milliseconds 1500 }
		
    } while (($itemsToRemove.FilesFolders.Count + 
            $itemsToRemove.RegistryKeys.Count + 
            $itemsToRemove.RegistryValues.Count + 
            $itemsToRemove.TempSearchFiles.Count + 
            $itemsToRemove.IeCacheFiles.Count) -gt 0 -or 
        $itemsToRemove.StoreApp)

    # Display final cleanup summary and any encountered errors
    Get-RemovalSummary
}
catch {
    Write-Host "Critical error:" -ForegroundColor Red -NoNewline
    Write-Host " $($_.Exception.Message)"
    Write-Host "$($_.ScriptStackTrace)"
    exit 1
}
