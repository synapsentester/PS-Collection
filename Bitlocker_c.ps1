<#
Erweitertes Skript:
- Aktiviert BitLocker auf der automatisch ermittelten Systempartition mit TPM+PIN (140977).
- Speichert den RecoveryKey als .BEK-Datei in C:\LocLogFile\BLExport (systemharmonisch).
- Erzeugt zusätzlich eine menschenlesbare TXT.
- Schreibt die Infos auch ins Windows Eventlog (eigene Quelle "BitLocker-Setup").
- Dateiname enthält Computername, die beste verfügbare Seriennummer und Datum/Zeit.
- TXT enthält alle drei Seriennummern zur Nachvollziehbarkeit.
#> 
#gittest

#region Einstellungen
# Systemlaufwerk automatisch ermitteln
$Drive = (Get-CimInstance Win32_OperatingSystem).SystemDrive
$PinString   = "140977"
$Folder      = "C:\LocLogFile\BLExport"
$EventSource = "BitLocker-Setup"
$EventLog    = "Application"

# Seriennummern automatisch ermitteln
$BIOSSerial  = (Get-CimInstance Win32_BIOS).SerialNumber
$BoardSerial = (Get-CimInstance Win32_BaseBoard).SerialNumber
$CSPSKU      = (Get-CimInstance Win32_ComputerSystemProduct).IdentifyingNumber

# Dateiname: beste verfügbare Seriennummer auswählen
$SerialForFile = if (![string]::IsNullOrWhiteSpace($BIOSSerial) -and $BIOSSerial -notmatch 'To be filled by OEM') {
    $BIOSSerial
} elseif (![string]::IsNullOrWhiteSpace($BoardSerial) -and $BoardSerial -notmatch 'To be filled by OEM') {
    $BoardSerial
} elseif (![string]::IsNullOrWhiteSpace($CSPSKU)) {
    $CSPSKU
} else { 'UnknownSerial' }

$BaseName  = "BitLockerRecovery_${env:COMPUTERNAME}_${SerialForFile}_$(Get-Date -Format 'yyyy-MM-dd_HHmm')"
$TxtPath   = Join-Path $Folder ("$BaseName.txt")
#endregion

# Ordner vorbereiten
if (!(Test-Path $Folder)) { New-Item -ItemType Directory -Path $Folder | Out-Null }

# PIN in SecureString umwandeln
$Pin = ConvertTo-SecureString $PinString -AsPlainText -Force

# BitLocker aktivieren mit TPM+PIN und RecoveryKey
#Enable-BitLocker -MountPoint $Drive -EncryptionMethod XtsAes256 -UsedSpaceOnly `
 #   -TPMandPinProtector -Pin $Pin -RecoveryKeyPath $Folder -RecoveryKeyProtector -SkipHardwareTest

# BitLocker mit TPM und PIN aktivieren
Enable-BitLocker -MountPoint $env:SystemDrive -EncryptionMethod Aes256 -UsedSpaceOnly -Pin $Pin -TPMandPinProtector


# Warten bis KeyProtektor vorhanden
Start-Sleep -Seconds 3

# RecoveryKeyProtektor ermitteln
$keyProtector = (Get-BitLockerVolume -MountPoint $Drive).KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryKey" }

# Menschenlesbare Infos erzeugen
$vol = Get-BitLockerVolume -MountPoint $Drive
$content = @()
$content += '================ BITLOCKER WIEDERHERSTELLUNGSINFORMATIONEN =============='
$content += "Computername           : $env:COMPUTERNAME"
$content += "BIOS Seriennummer      : $BIOSSerial"
$content += "BaseBoard Seriennummer : $BoardSerial"
$content += "IdentifyingNumber      : $CSPSKU"
$content += "Benutzer               : $env:UserName"
$content += "Datum/Zeit             : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$content += "Laufwerk               : $Drive"
$content += "Status                 : $($vol.VolumeStatus)"
$content += "Verschlüsselung        : $($vol.EncryptionMethod)"
$content += ''
$content += '--- Wiederherstellungskennwort (48-stellig) ---'
$content += (& manage-bde -protectors -get $Drive | Select-String "Recovery Password").Line -replace '.*:\s*',''
$content += ''
$content += '--- Key-Protektoren ---'
$vol.KeyProtector | ForEach-Object {
    $line = "Typ=$($_.KeyProtectorType); ID=$($_.KeyProtectorId)"
    if ($_.PSObject.Properties.Match('RecoveryPassword').Count -gt 0 -and $_.RecoveryPassword) {
        $line += "; RecoveryPassword=$($_.RecoveryPassword)"
    }
    $content += $line
}
$content += '=========================================================================='

# TXT-Datei speichern
$content | Set-Content -Path $TxtPath -Encoding UTF8
Write-Host "Lesbare Schlüssel-Infos gespeichert: $TxtPath" -ForegroundColor Green

# Eventlog vorbereiten
if (-not [System.Diagnostics.EventLog]::SourceExists($EventSource)) {
    New-EventLog -LogName $EventLog -Source $EventSource
}

# Infos ins Eventlog schreiben
$eventMsg = ($content -join [Environment]::NewLine)
Write-EventLog -LogName $EventLog -Source $EventSource -EntryType Information -EventId 1001 -Message $eventMsg
Write-Host "Infos zusätzlich ins Eventlog ($EventLog) geschrieben." -ForegroundColor Green

Write-Host 'Neustart erforderlich, damit die PIN greift.' -ForegroundColor Yellow
