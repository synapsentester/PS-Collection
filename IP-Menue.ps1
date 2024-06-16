Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)

. ..\Function\Check-AdminRights.ps1
Start-WithElevatedPrivileges -ScriptToRun $MyInvocation.MyCommand.Path
Write-Output "Hauptskript wird mit Administratorrechten ausgeführt."



function Restart-AndWaitForAdapter {
    param (
        [string]$AdapterName
    )

    # Netzwerkadapter neu starten
    Restart-NetAdapter -Name $AdapterName

    # Funktion zum Warten auf die Verbindung des Adapters
    function WaitForAdapterConnection {
        param (
            [string]$AdapterName
        )
        
        do {
            $adapterStatus = Get-NetAdapter -Name $AdapterName
            Start-Sleep -Seconds 1
        } while ($adapterStatus.Status -ne "Up")

        # Rückgabe des Adapternamens, wenn er verbunden ist
        return $AdapterName
    }

    # Aufruf der Warte-Funktion und Ausgabe
    $connectedAdapter = WaitForAdapterConnection -AdapterName $AdapterName
    Write-Output "$connectedAdapter ist jetzt verbunden."
}

function Show-NetworkAdapterInfo {
    # Verzeichnis erstellen, falls es nicht existiert
    $directory = "Z:\test"
    if (-not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory
    }

    # CSV-Datei Pfad
    $outputPath = "$directory\test.csv"

    # Netzwerkschnittstelleninformationen auslesen
    $networkInterfaces = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -or $_.Status -eq 'Connected' }

    # Array für die gesammelten Daten
    $networkData = @()

    # Informationen zu jeder Netzwerkschnittstelle sammeln
    foreach ($adapter in $networkInterfaces) {
        $adapterDetails = Get-NetIPConfiguration -InterfaceAlias $adapter.Name

        $ipAddress = ($adapterDetails.IPv4Address | Select-Object -ExpandProperty IPAddress) -join ", "
        $subnet = ($adapterDetails.IPv4Address | Select-Object -ExpandProperty PrefixLength) -join ", "
        $gateway = ($adapterDetails.IPv4DefaultGateway | Select-Object -ExpandProperty NextHop) -join ", "
        $dnsServers = ($adapterDetails.DnsServer | Select-Object -ExpandProperty ServerAddresses) -join ", "

        # Überprüfen, ob DHCP aktiviert ist
        $dhcpEnabled = $adapterDetails.DhcpServer -ne $null

        # Informationen sammeln
        $networkData += [PSCustomObject]@{
            Name          = $adapter.Name
            Status        = $adapter.Status
            MacAddress    = $adapter.MacAddress
            LinkSpeed     = $adapter.LinkSpeed
            IPAddress     = $ipAddress
            Subnet        = $subnet
            Gateway       = $gateway
            DnsServers    = $dnsServers
            DhcpEnabled   = $dhcpEnabled
        }
    }

    # Prüfen, ob es Daten gibt
    if ($networkData) {
        # Daten in die CSV-Datei schreiben
        $networkData | Export-Csv -Path $outputPath -NoTypeInformation
        Write-Host "Die Informationen wurden erfolgreich in $outputPath gespeichert."
    } else {
        Write-Host "Keine verbundenen Netzwerkschnittstellen gefunden."
    }
}

function Set-NetworkAdapterToDhcp {
    # Netzwerkschnittstelleninformationen auslesen
    $networkInterfaces = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -or $_.Status -eq 'Connected' }

    # Menü zur Auswahl der Netzwerkschnittstelle
    $networkInterfaces | ForEach-Object {
        Write-Host "$($_.ifIndex): $($_.Name)"
    }

    $index = Read-Host "Bitte geben Sie die Indexnummer der Netzwerkkarte ein, die auf DHCP umgestellt werden soll"

# Netzwerkkarte auf DHCP umstellen
$selectedAdapter = $networkInterfaces | Where-Object { $_.ifIndex -eq $index }

    # DNS-Server zurücksetzen (beispielhaft)
    Set-DnsClientServerAddress -InterfaceAlias $selectedAdapter.Name -ServerAddresses @()
    Set-DnsClientServerAddress -InterfaceAlias $selectedAdapter.Name -ResetServerAddresses

if ($selectedAdapter) {
    Write-Host "Stelle $($selectedAdapter.Name) auf DHCP um..."

    # Umstellung auf DHCP
    Set-NetIPInterface -InterfaceAlias $selectedAdapter.Name -Dhcp Enabled

    # Default Gateway entfernen
    $ErrorActionPreference = "SilentlyContinue"
    $routes = Get-NetRoute -InterfaceAlias $selectedAdapter.Name -ErrorAction SilentlyContinue | Where-Object -FilterScript {$_.NextHop -ne "0.0.0.0"}
    foreach ($route in $routes) {
        if ($route.DestinationPrefix -eq "0.0.0.0/0" -and $route.NextHop -ne "0.0.0.0") {
            Remove-NetRoute -DestinationPrefix $route.DestinationPrefix -InterfaceAlias $selectedAdapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        }
        
    }
    $ErrorActionPreference = "Continue"
    Write-Host "$($selectedAdapter.Name) wurde erfolgreich auf DHCP umgestellt."

    # Netzwerkadapter neu starten und auf Verbindung warten (beispielhaft)
    Restart-AndWaitForAdapter -AdapterName $selectedAdapter.Name
} else {
    Write-Host "Ungültige Indexnummer. Bitte erneut versuchen."
}
}


function Set-NetworkAdapterManual {
    # Netzwerkschnittstelleninformationen auslesen
    $networkInterfaces = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -or $_.Status -eq 'Connected' }

    # Menü zur Auswahl der Netzwerkschnittstelle
    $networkInterfaces | ForEach-Object {
        Write-Host "$($_.ifIndex): $($_.Name)"
    }


$index = Read-Host "Bitte geben Sie die Indexnummer der Netzwerkkarte ein, die manuell konfiguriert werden soll"

    # Netzwerkkarte manuell konfigurieren
    $selectedAdapter = $networkInterfaces | Where-Object { $_.ifIndex -eq $index }
    if ($selectedAdapter) {
        #$adapterName = $selectedAdapter.Name

        # Benutzereingaben für die Netzwerkkonfiguration
        $ipAddress = Read-Host "Bitte geben Sie die IP-Adresse ein"
        $subnet = Read-Host "Bitte geben Sie die Subnetzmaske (CIDR) ein, z.B. 24"
        $gateway = Read-Host "Bitte geben Sie das Standard-Gateway ein"
        $dns1 = Read-Host "Bitte geben Sie den ersten DNS-Server ein"
        $dns2 = Read-Host "Bitte geben Sie den zweiten DNS-Server ein"

        Write-Host "Konfiguriere "$selectedAdapter.Name" manuell..."
        New-NetIPAddress -InterfaceAlias $selectedAdapter.Name -IPAddress $ipAddress -PrefixLength $subnet -DefaultGateway $gateway
        Set-DnsClientServerAddress -InterfaceAlias $selectedAdapter.Name -ServerAddresses ($dns1, $dns2)
        Write-Host $selectedAdapter.Name" wurde erfolgreich manuell konfiguriert."
        # Netzwerkadapter neu starten und auf Verbindung warten
        Restart-AndWaitForAdapter -AdapterName $selectedAdapter.Name
    } else {
        Write-Host "Ungültige Indexnummer. Bitte erneut versuchen."
    }
}

function MainMenu {
    Write-Host "1: Netzwerkschnittstelleninformationen anzeigen"
    Write-Host "2: Netzwerkkarte auf DHCP umstellen"
    Write-Host "3: Netzwerkkarte manuell konfigurieren"
    $choice = Read-Host "Bitte wählen Sie eine Option (1, 2 oder 3)"

    switch ($choice) {
        1 {
            Show-NetworkAdapterInfo
        }
        2 {
            Set-NetworkAdapterToDhcp
        }
        3 {
            Set-NetworkAdapterManual
        }
        default {
            Write-Host "Ungültige Auswahl. Bitte erneut versuchen."
        }
    }
}

# Hauptmenü aufrufen
MainMenu