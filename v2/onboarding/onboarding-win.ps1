# G@FT.ai Studio - Windows Developer Onboarding Setup Script
# Version: 1.0.13 (Handle .env file copy to WSL for Bash script)
# Maintainer: Gem BB (Camille - Automation)
# Target OS: Windows 10 (version 2004 and higher) / Windows 11

# --- Script Configuration & Globals ---
$ScriptVersion = "1.0.13"
$DefaultWSLDistroBaseName = "Ubuntu"
$BashOnboardingScriptName = "gftai_onboarding.sh"
$EnvFileName = ".env" # Name of the environment file to look for

# --- Helper Functions ---
# (Identical to v1.0.12)
function Write-Color ($Text, $Color, $NewLine = $true) {
    if ($NewLine) { Write-Host $Text -ForegroundColor $Color }
    else { Write-Host $Text -ForegroundColor $Color -NoNewline }
}
function Info ($Message) { Write-Color "[INFO] $Message" "Cyan" }
function Success ($Message) { Write-Color "[SUCCESS] $Message" "Green" }
function Warning ($Message) { Write-Color "[WARNING] $Message" "Yellow" }
function Error-Msg ($Message, $ExitScript = $false) {
    Write-Color "[ERROR] $Message" "Red"
    if ($ExitScript) { Read-Host "Press Enter to exit..."; exit 1 }
}
function Ask-YesNo ($Question, $Default = "Yes") {
    $choices = "[Y]es, [N]o"; if ($Default -eq "Yes") { $prompt = "Y/n"; $defaultChoice = "Y" } else { $prompt = "y/N"; $defaultChoice = "N" }
    while ($true) {
        $response = Read-Host -Prompt "$(Write-Color '[QUESTION]' 'Yellow' -NoNewline) $Question ($prompt)"
        if ([string]::IsNullOrWhiteSpace($response)) { $response = $defaultChoice }
        if ($response -match "^[Yy]$") { return $true }
        if ($response -match "^[Nn]$") { return $false }
        Write-Color "Please answer Yes (y) or No (n)." "Red"
    }
}
function Test-IsAdmin {
    return (New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Check-CommandExists ($CommandName) {
    return (Get-Command $CommandName -ErrorAction SilentlyContinue) -ne $null
}
function Clean-String ($InputString) {
    if ($null -eq $InputString) { return "" }
    $cleaned = $InputString.Trim(); $cleaned = $cleaned -replace '\s+', ' '; $cleaned = $cleaned -replace '[^\x20-\x7E]+', ''; return $cleaned.Trim()
}
# End Helper Functions

# --- Section 1 & 1.1 (WSL Feature Enable & Default Version) ---
# (Identical to v1.0.12)
function Ensure-WSLFeatures {
    Info "SECTION 1: Checking Windows Subsystem for Linux (WSL) and VirtualMachinePlatform features..."
    Write-Color "------------------------------------------------------------------------------------" "Gray"
    $wslFeatureName = "Microsoft-Windows-Subsystem-Linux"; $vmPlatformFeatureName = "VirtualMachinePlatform"
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName $wslFeatureName -ErrorAction SilentlyContinue
    $vmPlatformFeature = Get-WindowsOptionalFeature -Online -FeatureName $vmPlatformFeatureName -ErrorAction SilentlyContinue
    if (($wslFeature -eq $null) -or ($vmPlatformFeature -eq $null)) { Error-Msg "Could not query Windows Optional Features. Ensure Windows is compatible with WSL2 (Win 10 v2004+ / Win 11)." "ExitScript" }
    $restartNeeded = $false
    if ($wslFeature.State -ne "Enabled") { Warning "Feature '$wslFeatureName' not enabled."; if (Test-IsAdmin) { if (Ask-YesNo "Enable '$wslFeatureName'? (May require restart)") { Info "Enabling '$wslFeatureName'..."; Enable-WindowsOptionalFeature -Online -FeatureName $wslFeatureName -NoRestart -All; $restartNeeded = $true } else { Error-Msg "'$wslFeatureName' required. Exiting." "ExitScript" } } else { Error-Msg "Admin rights needed for '$wslFeatureName'. Re-run as Admin or enable manually. Exiting." "ExitScript" } } else { Success "Feature '$wslFeatureName' enabled." }
    if ($vmPlatformFeature.State -ne "Enabled") { Warning "Feature '$vmPlatformFeatureName' not enabled."; if (Test-IsAdmin) { if (Ask-YesNo "Enable '$vmPlatformFeatureName'? (May require restart)") { Info "Enabling '$vmPlatformFeatureName'..."; Enable-WindowsOptionalFeature -Online -FeatureName $vmPlatformFeatureName -NoRestart -All; $restartNeeded = $true } else { Error-Msg "'$vmPlatformFeatureName' required. Exiting." "ExitScript" } } else { Error-Msg "Admin rights needed for '$vmPlatformFeatureName'. Re-run as Admin or enable manually. Exiting." "ExitScript" } } else { Success "Feature '$vmPlatformFeatureName' enabled." }
    if ($restartNeeded) { $wslFeatureAfter = Get-WindowsOptionalFeature -Online -FeatureName $wslFeatureName; $vmPlatformFeatureAfter = Get-WindowsOptionalFeature -Online -FeatureName $vmPlatformFeatureName; if ($wslFeatureAfter.State -eq "Enabled" -and $vmPlatformFeatureAfter.State -eq "Enabled") { Success "Windows features enabled."; Warning "SYSTEM RESTART required. After restarting, re-run this script."; exit 0 } else { Error-Msg "Failed to verify feature enabling. Check manually, restart, and re-run." "ExitScript" } }
    Write-Color "------------------------------------------------------------------------------------" "Gray"; echo ""
}
function Set-WSLDefaultVersion {
    Info "SECTION 1.1: Setting WSL default version to 2 (if WSL command is available)..."
    Write-Color "------------------------------------------------------------------------------------" "Gray"
    if (Check-CommandExists wsl) { try { Info "Attempting: wsl --set-default-version 2"; wsl --set-default-version 2; Success "WSL default version set to 2 (or already set)."; Info "Note: May require 'wsl --update' if kernel outdated." } catch { Warning "Could not set WSL default to 2. Error: $($_.Exception.Message)" } } else { Warning "WSL command not found. Cannot set default version (restart pending from feature install?)." }
    Write-Color "------------------------------------------------------------------------------------" "Gray"; echo ""
}
# End Section 1 & 1.1

# --- Section 2: Check/Install Linux Distribution for WSL2 ---
# (Identical to v1.0.12 - This function returns the exact distro name to use)
function Check-And-Install-WSLDistro {
    param([string]$TargetDistroBaseName = $DefaultWSLDistroBaseName)
    Info "SECTION 2: Checking for a Linux Distribution in WSL2 (e.g., $TargetDistroBaseName)..."; Write-Color "---..." "Gray"
    if (-not (Check-CommandExists wsl)) { Error-Msg "WSL tool not found. Restart might be pending." "ExitScript" }
    $localDistroToUse = ""; $localDistroFoundAndUsable = $false; $parsedDistros = @()
    Info "Listing installed WSL distributions (verbose)..."; $wslListOutput = $(wsl.exe --list --verbose 2>$null)
    if ($wslListOutput) {
        foreach ($line in $wslListOutput) {
            $originalLineForLog = $line.Trim([char]0x00).Trim(); if ([string]::IsNullOrWhiteSpace($originalLineForLog)) { continue }
            $cleanedLine = Clean-String -InputString $originalLineForLog
            if (($cleanedLine -ieq "NAME STATE VERSION") -or ($cleanedLine -imatch "^Windows Subsystem") -or ($cleanedLine -imatch "^There are no distributions installed")) { Info "Skipping header/info: '$cleanedLine'"; continue }
            $isDefault = $cleanedLine.StartsWith("*"); $lineToParse = if ($isDefault) { $cleanedLine.Substring(1).TrimStart() } else { $cleanedLine }
            $parts = $lineToParse -split '\s+' | Where-Object {$_ -ne ""}; if ($parts.Count -ge 3) {
                $version = Clean-String -InputString $parts[$parts.Count -1]; $state = Clean-String -InputString $parts[$parts.Count -2]; $nameParts = $parts[0..($parts.Count -3)]; $name = (Clean-String -InputString ($nameParts -join " ")).Trim()
                if ([string]::IsNullOrWhiteSpace($name)) { Warning "Parsed empty name from: '$cleanedLine'. Skipping."; continue }
                if (($version -ne "1") -and ($version -ne "2")) { Warning "Invalid version '$version' from: '$cleanedLine'. Skipping."; continue }
                if (($state -ine "Running") -and ($state -ine "Stopped")) { Warning "Invalid state '$state' from: '$cleanedLine'. Skipping."; continue }
                $parsedDistros += [PSCustomObject]@{ Name = $name; State = $state; Version = $version; IsDefault = $isDefault }; Info ("Parsed: Name='{0}', State='{1}', Version='{2}', Default='{3}'" -f $name, $state, $version, $isDefault)
            } else { Warning "Could not parse line: '$cleanedLine' (original: '$originalLineForLog')" }
        }
    } else { Info "No WSL distributions listed or WSL command error." }
    if ($parsedDistros.Count -gt 0) {
        Info "Found $($parsedDistros.Count) parsed entries. Checking suitability..."
        foreach ($distroObj in $parsedDistros) {
            $nameMatch = ($distroObj.Name -ieq $TargetDistroBaseName -or $distroObj.Name.StartsWith($TargetDistroBaseName + "-", [System.StringComparison]::InvariantCultureIgnoreCase))
            $stateOk = ($distroObj.State -ieq "Running" -or $distroObj.State -ieq "Stopped"); $versionOk = ($distroObj.Version -eq "2")
            if ($nameMatch -and $stateOk -and $versionOk) { Success "'$($distroObj.Name)' is usable."; $localDistroToUse = $distroObj.Name; $localDistroFoundAndUsable = $true; break }
            else { $reason = ""; if (-not $nameMatch) { $reason += "Name !~ '$TargetDistroBaseName'. " }; if (-not $stateOk) { $reason += "State not Running/Stopped. " }; if (-not $versionOk) { $reason += "WSL Ver != 2. " }; Warning "'$($distroObj.Name)' not optimal. Reason: $reason" }
        }
    }
    if (-not $localDistroFoundAndUsable) {
        if ($parsedDistros.Count -gt 0) { Warning "No readily usable '$TargetDistroBaseName' distro found." } else { Warning "No WSL distros appear installed." }
        Info "Install '$TargetDistroBaseName' via MS Store or 'wsl --install -d $TargetDistroBaseName'."
        if (Test-IsAdmin) { if (Ask-YesNo "Attempt install $TargetDistroBaseName now?") { Info "Installing $TargetDistroBaseName..."; try { wsl --install -d $TargetDistroBaseName; Info "Re-checking distros...";
                    $recheckParsedDistros = @(); $recheckWslListOutput = $(wsl.exe --list --verbose 2>$null)
                    if ($recheckWslListOutput) { foreach ($line_recheck in $recheckWslListOutput) { $originalLine_recheck_again = $line_recheck.Trim([char]0x00).Trim(); if ([string]::IsNullOrWhiteSpace($originalLine_recheck_again)) { continue }; $cleanedLine_recheck_again = Clean-String -InputString $originalLine_recheck_again; if (($cleanedLine_recheck_again -ieq "NAME STATE VERSION") -or ($cleanedLine_recheck_again -imatch "^Windows Subsystem") -or ($cleanedLine_recheck_again -imatch "^There are no distributions installed")) { continue }; $isDefault_recheck_again = $cleanedLine_recheck_again.StartsWith("*"); $lineToParse_recheck_again = if ($isDefault_recheck_again) { $cleanedLine_recheck_again.Substring(1).TrimStart() } else { $cleanedLine_recheck_again }; $parts_recheck_again = $lineToParse_recheck_again -split ' ' | Where-Object {$_ -ne ""}; if ($parts_recheck_again.Count -ge 3) { $version_recheck_again = Clean-String -InputString $parts_recheck_again[$parts_recheck_again.Count -1]; $state_recheck_again = Clean-String -InputString $parts_recheck_again[$parts_recheck_again.Count -2]; $name_recheck_again = (Clean-String -InputString ($parts_recheck_again[0..($parts_recheck_again.Count -3)] -join " ")).Trim(); if (-not ([string]::IsNullOrWhiteSpace($name_recheck_again)) -and (($version_recheck_again -eq "1") -or ($version_recheck_again -eq "2")) -and (($state_recheck_again -ieq "Running") -or ($state_recheck_again -ieq "Stopped")) ) { $recheckParsedDistros += [PSCustomObject]@{ Name = $name_recheck_again; State = $state_recheck_again; Version = $version_recheck_again; IsDefault = $isDefault_recheck_again } } } } }
                    $foundAfterInstall = $false; foreach($distroObjAfter in $recheckParsedDistros){ if (($distroObjAfter.Name -ieq $TargetDistroBaseName -or $distroObjAfter.Name.StartsWith($TargetDistroBaseName + "-", [System.StringComparison]::InvariantCultureIgnoreCase)) -and ($distroObjAfter.State -ieq "Running" -or $distroObjAfter.State -ieq "Stopped") -and $distroObjAfter.Version -eq "2") { $localDistroToUse = $distroObjAfter.Name; $foundAfterInstall = $true; break } }; if ($foundAfterInstall) { Success "'$localDistroToUse' installed." } else { Error-Msg "$TargetDistroBaseName install ran, but not detected. Check 'wsl -l -v'. If ERROR_ALREADY_EXISTS, unregister. Exiting." "ExitScript" } } catch { $err = $_.Exception.Message; Error-Msg "Failed to install $TargetDistroBaseName. Error: $err"; if ($err -match "ERROR_ALREADY_EXISTS") { Error-Msg "ERROR_ALREADY_EXISTS: Unregister ('wsl --unregister <Name>') then re-run." } else { Error-Msg "Install '$TargetDistroBaseName' manually." }; Error-Msg "Exiting." "ExitScript" } } else { Error-Msg "$TargetDistroBaseName required. Exiting." "ExitScript" }
        } else { Error-Msg "Admin rights required for 'wsl --install'. Exiting." "ExitScript" }
    } else { Success "Using existing WSL distro: '$localDistroToUse'." }
    Write-Color "------------------------------------------------------------------------------------" "Gray"; echo ""; return $localDistroToUse
}
# End Section 2

# --- Section 3: Check/Install VS Code ---
# (Identical to v1.0.12)
function Check-And-Install-VSCode {
    Info "SECTION 3: Checking for Visual Studio Code..."
    Write-Color "------------------------------------------------------------------------------------" "Gray"
    $vsCodeSystemPath = Join-Path $env:ProgramFiles "Microsoft VS Code\Code.exe"; $vsCodeUserPath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\Code.exe"; $vsCodeFound = $false
    if (Test-Path $vsCodeSystemPath -PathType Leaf) { $vsCodeFound = $true } elseif (Test-Path $vsCodeUserPath -PathType Leaf) { $vsCodeFound = $true } elseif (Check-CommandExists code) { $vsCodeFound = $true }
    if ($vsCodeFound) { Success "Visual Studio Code appears to be installed." }
    else { Warning "Visual Studio Code not detected."; Info "Please download and install VS Code from: https://code.visualstudio.com/"; if (-not (Ask-YesNo "Have you installed VS Code? (Script will continue, but VS Code related steps might be skipped if 'code' command is not found)")) { Warning "VS Code is highly recommended for G@FT.ai development." } }
    Write-Color "------------------------------------------------------------------------------------" "Gray"; echo ""
}
# End Section 3

# --- Section 4: Check/Install VS Code 'Remote - WSL' Extension ---
# (Identical to v1.0.12)
function Check-And-Install-VSCodeWSLExtension {
    Info "SECTION 4: Checking for VS Code 'Remote - WSL' Extension..."
    Write-Color "------------------------------------------------------------------------------------" "Gray"
    if (Check-CommandExists code) { $extId = "ms-vscode-remote.remote-wsl"; try { $installedExts = $(code --list-extensions --show-versions 2>$null); if (($installedExts -is [array] -and ($installedExts -match $extId -or $installedExts -match $extId.ToLower())) `
             -or ($installedExts -is [string] -and $installedExts -match $extId)) { Success "VS Code extension '$extId' is already installed." } else { Warning "VS Code extension '$extId' not found."; if (Ask-YesNo "Do you want to attempt to install the '$extId' extension now?") { Info "Installing VS Code extension '$extId'..."; code --install-extension $extId --force; Warning "VS Code extension '$extId' installation command issued. It might require a VS Code restart to be fully active/detected." } else { Warning "VS Code extension '$extId' is highly recommended. Please install it manually from VS Code Marketplace." } } } catch { Warning "Could not reliably check VS Code extensions (Error: $($_.Exception.Message)). Please ensure '$extId' is installed manually."} } else { Warning "VS Code CLI ('code') not found. Skipping 'Remote - WSL' extension check/install." }
    Write-Color "------------------------------------------------------------------------------------" "Gray"; echo ""
}
# End Section 4

# --- Section 5: Check/Install Docker Desktop ---
# (Identical to v1.0.12, ensure $localDistroToUse is passed via $distroForBashScript in Main)
function Check-And-Install-DockerDesktop {
    param ([string]$WSLDistroToIntegrateWith)
    Info "SECTION 5: Checking for Docker Desktop..."
    Write-Color "------------------------------------------------------------------------------------" "Gray"
    $dockerPathPF = "C:\Program Files\Docker\Docker\Docker Desktop.exe"; $dockerCli = Check-CommandExists docker
    if ((Test-Path $dockerPathPF -PathType Leaf) -or $dockerCli) { Success "Docker Desktop appears installed."; Info "Please ensure Docker Desktop uses WSL2 backend: Settings > Resources > WSL Integration > Enable for '$WSLDistroToIntegrateWith'." }
    else { Warning "Docker Desktop not detected."; Info "Download: https://www.docker.com/products/docker-desktop/"; Info "Enable WSL2 backend in Docker settings."; if (-not (Ask-YesNo "Installed Docker Desktop & configured WSL2 backend for '$WSLDistroToIntegrateWith'?")) { Warning "Docker Desktop with WSL2 important." } }
    Write-Color "------------------------------------------------------------------------------------" "Gray"; echo ""
}
# End Section 5

# --- Section 6: Prepare and Launch Bash Onboarding Script in WSL2 (CORRECTED - v1.0.13) ---
function Launch-BashOnboardingScript {
    param ([string]$WSLDistroToRunIn)
    Info "SECTION 6: Launching Bash Onboarding Script in WSL2..."
    Write-Color "------------------------------------------------------------------------------------" "Gray"

    $BashScriptHostPath = Join-Path $PSScriptRoot $BashOnboardingScriptName
    if (-not (Test-Path $BashScriptHostPath -PathType Leaf)) {
        Error-Msg "The Bash onboarding script ('$BashOnboardingScriptName') was NOT FOUND at Windows path '$BashScriptHostPath'."
        Error-Msg "Please ensure '$BashOnboardingScriptName' is in the SAME directory as this PowerShell script ('$PSScriptRoot'). Exiting." "ExitScript"
    }

    # Convert Windows path of Bash script to WSL path
    $DriveLetterBash = $BashScriptHostPath.Substring(0,1)
    $PathWithoutDriveBash = $BashScriptHostPath.Substring(2)
    $BashScriptWSLPath = "/mnt/$($DriveLetterBash.ToLower())$($PathWithoutDriveBash.Replace('\','/'))"

    # Handle .env file
    $EnvFileHostPath = Join-Path $PSScriptRoot $EnvFileName # $EnvFileName is ".env"
    if (Test-Path $EnvFileHostPath -PathType Leaf) {
        Info "Found '$EnvFileName' at Windows path: $EnvFileHostPath"
        $DriveLetterEnv = $EnvFileHostPath.Substring(0,1)
        $PathWithoutDriveEnv = $EnvFileHostPath.Substring(2)
        $EnvFileWSLSourcePath = "/mnt/$($DriveLetterEnv.ToLower())$($PathWithoutDriveEnv.Replace('\','/'))"
        # Target user's home directory in WSL, named .env, so Bash script finds it with cd ~; ./ .env
        $EnvFileWSLTargetPath = "~/$EnvFileName"

        Info "Attempting to copy '$EnvFileHostPath' to '$EnvFileWSLTargetPath' inside '$($WSLDistroToRunIn.Trim())'..."
        # Construct the full bash command for copying, including error checking
        # Ensure paths with spaces are quoted for bash -c
        $copyCommandForBash = "if [ -f `"$EnvFileWSLSourcePath`" ]; then cp -f `"$EnvFileWSLSourcePath`" `"$EnvFileWSLTargetPath`" && echo 'CP_SUCCESS'; else echo 'CP_SOURCE_NOT_FOUND'; fi"

        $copyOutput = ""
        $copyError = ""
        try {
            # Use wsl.exe directly and capture output/error streams
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "wsl.exe"
            $processInfo.Arguments = "-d $($WSLDistroToRunIn.Trim()) -e bash -c `"$copyCommandForBash`""
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            $processInfo.UseShellExecute = $false
            $processInfo.CreateNoWindow = $true
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $processInfo
            $process.Start() | Out-Null
            $copyOutput = $process.StandardOutput.ReadToEnd()
            $copyError = $process.StandardError.ReadToEnd()
            $process.WaitForExit()

            if ($process.ExitCode -eq 0 -and $copyOutput -match "CP_SUCCESS") {
                Success "'$EnvFileName' copied to '$EnvFileWSLTargetPath' in WSL distribution '$($WSLDistroToRunIn.Trim())'."
                Info "The Bash script will attempt to load this .env file from its execution directory (~/.env)."
            } elseif ($copyOutput -match "CP_SOURCE_NOT_FOUND") {
                Warning "Source .env file '$EnvFileWSLSourcePath' not found inside WSL during copy attempt. This is unexpected if Test-Path was true on Windows side."
            } else {
                Warning "Failed to copy '$EnvFileName' to WSL. Exit Code: $($process.ExitCode)"
                if (-not [string]::IsNullOrWhiteSpace($copyOutput)) { Warning "StdOut from WSL cp: $copyOutput" }
                if (-not [string]::IsNullOrWhiteSpace($copyError)) { Warning "StdErr from WSL cp: $copyError" }
                Warning "The Bash script might not find your .env configurations. You may need to copy it manually into WSL (~/.env)."
            }
        } catch {
            Warning "Exception during copy of '$EnvFileName' to WSL. Error: $($_.Exception.Message)"
            Warning "The Bash script might not find your .env configurations."
        }
    } else {
        Info "'$EnvFileName' not found at '$EnvFileHostPath' (alongside PowerShell script). The Bash script will use its defaults or prompt interactively."
    }

    Info "Bash script Windows path: $BashScriptHostPath"; Info "Bash script WSL path: $BashScriptWSLPath"
    if ([string]::IsNullOrWhiteSpace($WSLDistroToRunIn)) { Error-Msg "No usable WSL distribution identified to launch Bash script. Install one (e.g., $DefaultWSLDistroBaseName) and re-run." "ExitScript" }
    Info "Bash script will launch in '$($WSLDistroToRunIn.Trim())' WSL2 distribution."
    Info "Ensure '$BashOnboardingScriptName' has execute permissions in WSL (e.g., run 'chmod +x $BashScriptWSLPath' from within WSL if needed, or ensure it's set when copied)."

    if (Ask-YesNo "Ready to launch Bash onboarding script in WSL2?") {
        Info "Launching WSL2... Follow instructions in the WSL2 terminal."
        $wslExecCommand = "cd ~; if [ -f `"$BashScriptWSLPath`" ]; then bash `"$BashScriptWSLPath`"; else echo '[ERROR] Bash script not found at $BashScriptWSLPath inside WSL. Check path/permissions.'; fi; exec bash"
        Info "WSL Command: wsl.exe -d $($WSLDistroToRunIn.Trim()) -e bash -ic `"$wslExecCommand`""
        try { Start-Process "wsl.exe" -ArgumentList "-d $($WSLDistroToRunIn.Trim()) -e bash -ic `"$wslExecCommand`"" ; Success "Bash script launch issued. Check WSL2 terminal." }
        catch { Error-Msg "Failed to launch Bash script in WSL2. Error: $($_.Exception.Message)"; Error-Msg "Open WSL2 ($($WSLDistroToRunIn.Trim())) manually, navigate to '$BashScriptWSLPath', 'chmod +x $BashOnboardingScriptName', then './$BashOnboardingScriptName'" }
    } else { Info "Skipped launching Bash script." }
    Write-Color "------------------------------------------------------------------------------------" "Gray"; echo ""
}
# End Section 6

# --- Main Function ---
function Main {
    Info "Starting G@FT.ai Windows Developer Environment Setup Script (v$ScriptVersion)..."
    Info "This script will help prepare your Windows system for G@FT.ai development using WSL2."
    Info "The companion Bash script '$BashOnboardingScriptName' should be in the same directory as this script: '$PSScriptRoot'."
    echo ""
    if (-not (Test-IsAdmin)) { Warning "Script requires Administrator privileges for some operations. Please re-run as Administrator."; if (-not (Ask-YesNo "Continue without Admin rights (some steps may fail)?")) { Info "Setup aborted."; exit 0 } }

    Ensure-WSLFeatures
    Set-WSLDefaultVersion
    $distroForBashScript = Check-And-Install-WSLDistro
    if ([string]::IsNullOrWhiteSpace($distroForBashScript)) { Error-Msg "Failed to identify or install a suitable WSL distribution. Cannot proceed." "ExitScript" }

    # Ensure the distro name is trimmed before use
    $distroForBashScript = $distroForBashScript.Trim()

    Check-And-Install-VSCode
    Check-And-Install-VSCodeWSLExtension
    Check-And-Install-DockerDesktop -WSLDistroToIntegrateWith $distroForBashScript
    Launch-BashOnboardingScript -WSLDistroToRunIn $distroForBashScript

    Success "G@FT.ai Windows Developer Environment Setup Script (PowerShell part) has completed."
    Info "Review messages and ensure Bash script steps (if launched) were successful."
    Read-Host "Press Enter to exit this PowerShell script..."
}

# Run the main function
Main
