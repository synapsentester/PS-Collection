$PathLOG = "C:\LocLogFile\"
$IPLOG = $PathLOG +"IP-$Stamp.log"
Test-Path -Path $PathLOG
#Start-Sleep -Seconds 30
$Stamp = Get-Date -Format yyyyMMdd-hhmmss

ipconfig -all | Out-File -FilePath $IPLOG
date | Out-File -FilePath $IPLOG -Append
$env:USERNAME | Out-File -FilePath $IPLOG -Append