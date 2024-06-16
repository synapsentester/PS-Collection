#Beendet Software falls diese noch läuft
$CleanSWs = @{
        "setup" = "setup.exe"
        "ose00000" = "ose00000.exe"
        "msiexec" = "msiexec.exe"
            }
# Beendet den Prozess 'setup.exe' gewaltsam und stellt sicher, dass es sich um die exakte Datei handelt
foreach ($CleanSW in $CleanSWs.Keys){
    $CleanID = $CleanSWs[$CleanSW]
    Get-Process -Name $CleanSW -ErrorAction SilentlyContinue | Where-Object {$_.Path -match $CleanID} | Stop-Process -Force
    }
    

# Definition der Dienste
$CleanServices = @("BITS", "wuauserv", "CryptSvc")
#Dienste stoppen und start verhindern
write-Host "Stoppen der Update Dienste..."
foreach ($CleanService in $CleanServices) {
    write-Host "Stoppe Dienst $CleanService"
    Set-Service -Name $CleanService -StartupType Disabled
    Stop-Service -Name $CleanService
    (Get-Service -Name $CleanService).Status
}

write-Host "Löschen von catroot2..." -ForegroundColor Red
Remove-Item "$env:SystemRoot\System32\catroot2" -Recurse -Force

write-Host "Löschen von SoftwareDistribution..." -ForegroundColor Red
Remove-Item "$env:SystemRoot\SoftwareDistribution" -Recurse -Force

#Dienste starten und Und auf automatic Start setzen
write-Host "Starten der Update Dienste..."
foreach ($CleanService in $CleanServices) {
    write-Host "Starte Dienst $CleanService"
    Set-Service -Name $CleanService -StartupType Automatic
    Start-Service -Name $CleanService
    (Get-Service -Name $CleanService).Status 
    
}


$DISMarg =@("/online", "/Cleanup-Image", "/StartComponentCleanup")

Start-Process -FilePath "Dism.exe" -ArgumentList $DISMarg -NoNewWindow -Wait
