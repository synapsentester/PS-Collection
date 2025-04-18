Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)

. ..\Function\Check-AdminRights.ps1
Start-WithElevatedPrivileges -ScriptToRun $MyInvocation.MyCommand.Path
Write-Output "Hauptskript wird mit Administratorrechten ausgeführt."



$IP = Read-Host "Neu IP eingeben"
$MaskBits = 24 # This means subnet mask = 255.255.255.0
$Gateway = Read-Host "Gateway eingeben"
$Dns = @("xxx.xxx.xxx.xxx", "xxx.xxx.xxx.xxx")

Write-Output $IP
Write-Output $Gateway

$IPType = "IPv4"
# Retrieve the network adapter that you want to configure
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
# Remove any existing IP, gateway from our IPv4 adapter
if (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
    $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
}
if (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
    $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
}
# Configure the IP address and default gateway
$adapter | New-NetIPAddress `
    -AddressFamily $IPType `
    -IPAddress $IP `
    -PrefixLength $MaskBits `
    -DefaultGateway $Gateway
# Configure the DNS client server IP addresses
$adapter | Set-DnsClientServerAddress -ServerAddresses $Dns

$adapter | Restart-NetAdapter
