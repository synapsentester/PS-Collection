Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)

. ..\Function\Check-AdminRights.ps1
Start-WithElevatedPrivileges -ScriptToRun $MyInvocation.MyCommand.Path
Write-Output "Hauptskript wird mit Administratorrechten ausgeführt."



#$Computers=Get-Content c:\PATHTOFILE.txt
$Computers="127.0.0.1"
Foreach($Computer in $Computers){

Write-Host
# Retrieve the network adapter that you want to configure
$adapter = Get-NetAdapter -Physical | ? {$_.Status -eq "up"}
$IPType = "IPv4"

$interface = $adapter | Get-NetIPInterface -AddressFamily $IPType
$IPold = Get-NetIPAddress -InterfaceIndex (($adapter).ifIndex) -AddressFamily $IPType
Write-Output $IPold
If ($interface.Dhcp -eq "Disabled") {
    # Remove existing gateway
    Write-Host "Removing existing gateway" -ForegroundColor Red
    If (($interface | Get-NetIPConfiguration).Ipv4DefaultGateway) {
        $interface | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
    }
    # Enable DHCP
    Write-Host "Enabling DHCP on interface" -ForegroundColor Yellow
    $interface | Set-NetIPInterface -DHCP Enabled
    # Configure the  DNS Servers automatically
    Write-Host "Enabling automatic DNS" -ForegroundColor Yellow
    $interface | Set-DnsClientServerAddress -ResetServerAddresses
}Else {Write-host "Already set to DHCP" -ForegroundColor Green;Exit}

Write-Host "Restarting adapter"
Write-Host

$adapter | Restart-NetAdapter

    do {
        $AdapterStatus = Get-NetAdapter -InterfaceIndex (($adapter).ifIndex) | Select-Object -ExpandProperty Status
        Start-Sleep -Seconds 1
    } while ($AdapterStatus -ne "Up")

$IPnew = Get-NetIPAddress -InterfaceIndex (($adapter).ifIndex) -AddressFamily $IPType
Write-Output $IPnew 
Write-Host "set to DHCP" -ForegroundColor Green
}