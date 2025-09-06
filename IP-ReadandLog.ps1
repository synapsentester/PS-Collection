$PathLOG = "C:\LocLogFile\"
$Stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$IPLOG = $PathLOG + "IP-$Stamp.log"

# Verzeichnis erstellen, falls nicht vorhanden
if (-not (Test-Path -Path $PathLOG)) {
    New-Item -ItemType Directory -Path $PathLOG | Out-Null
}

"==== Benutzer ====" | Out-File -FilePath $IPLOG
$env:USERNAME | Out-File -FilePath $IPLOG -Append

"`n==== Datum ====" | Out-File -FilePath $IPLOG -Append
(Get-Date) | Out-File -FilePath $IPLOG -Append

"`n==== Computername ====" | Out-File -FilePath $IPLOG -Append
$env:COMPUTERNAME | Out-File -FilePath $IPLOG -Append

"`n==== IP-Konfiguration ====" | Out-File -FilePath $IPLOG -Append
ipconfig /all | Out-File -FilePath $IPLOG -Append

Start-Process $IPLOG