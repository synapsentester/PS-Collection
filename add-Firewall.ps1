Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
$regeln = Import-Csv -Path "..\02-Data\1-testtom.csv" -Delimiter ","

foreach ($regel in $regeln) {

    # === Pflichtfelder-Mapping ===
    $RuleDir = switch ($regel.Richtung) {
        'in'  { 'in' }
        'out'  { 'out' }
        'Eingehend'  { 'in' }
        'Aus' { 'out' }
        default     { throw "❌ Ungültige Richtung: $($regel.Richtung)" }
    }

    $RuleAction = switch ($regel.Aktion) {
        #'allow'   { 'allow' }
        'block' { 'block' }
        'bypass'     { 'bypass' }
        'Zulassen'   { 'allow' }
        'Blockieren' { 'block' }
        'Sicher'     { 'bypass' }
        default { 'allow' }
    }

    $RuleProtocol = switch ($regel.Protokoll.ToUpper()) {
        'TCP'   { 'TCP' }
        'UDP'   { 'UDP' }
        'ANY'   { 'ANY' }
        'Beliebig'  { 'ANY' }
        default { throw "❌ Ungültiges Protokoll: $($regel.Protokoll)" }
    }

    $RuleActive = switch ($regel.Aktiviert) {
        'no' { 'no' }
        'Ja'   { 'yes' }
        'Nein' { 'no' }
        default { 'yes' }  # Fallback
    }

    $RuleEdge = switch ($regel.Edgeausnahme) {
        'Ja'                    { 'yes' }
        'Nein'                  { 'no' }
        'Anwendung verzögert'  { 'deferapp' }
        'Auf Benutzer zurückstellen'   { 'deferuser' }
        default                { throw "❌ Ungültiger Edgeausnahme-Wert: $($regel.Edgeausnahme)" }
    }

    $mappedProfiles = @()

    if ($regel.Profile) {
        $mappedProfiles = ($regel.Profile -split ',' | ForEach-Object {
            switch ($_.Trim()) {
                'public'     { 'public' }
                'private'    { 'private' }
                'domain'     { 'domain' }
                'Öffentlich' { 'public' }
                'Privat'     { 'private' }
                'Domäne'     { 'domain' }
                default      { $null }  # Ignorieren statt "any"
            }
        }) | Where-Object { $_ }  # Filtere $null raus
    }
    
    $RuleProfile = if ($mappedProfiles.Count -gt 0) {
        $mappedProfiles -join ','
    } else {
        'any'
    }
    


    # === "Beliebig"-Logik (=> any) ===
    $RuleLocalPort = if ($regel.'Lokaler Port' -eq 'Beliebig') {
        'any'
    } elseif ($regel.'Lokaler Port') {
        ($regel.'Lokaler Port' -split ',' | ForEach-Object { $_.Trim() }) -join ','
    }
    else {
        'any'
    }
    

    $RuleRemotePort = if ($regel.Remoteport -eq 'Beliebig') {
        'any'
    } elseif ($regel.Remoteport) {
        ($regel.Remoteport -split ',' | ForEach-Object { $_.Trim() }) -join ','
    }
    else {
        'any'
    }

    $RuleLocalIP = if ($regel.'Lokales IP' -eq 'Beliebig') {
        'any'
    } elseif ($regel.'Lokales IP') {
        ($regel.'Lokales IP' -split ',' | ForEach-Object { $_.Trim() }) -join ','
    }
    else {
        'any'
    }

    $RuleRemoteIP = if ([string]$regel.'Remote-IP' -eq 'Beliebig') {
        'any'
    } elseif ($regel.'Remote-IP') {
        ([string]$regel.'Remote-IP' -split ',' | ForEach-Object { $_.Trim() }) -join ','
    }
    else {
        'any'
    }


    # === Weitere optionale Felder ===
    $RuleName        = $regel.Regelname
    $RuleProgram     = $regel.Programm
    $RuleService     = $regel.Service
    $RuleDescription = $regel.Beschreibung
    $RuleInterface   = $regel.Interfacetype
    $RuleSecurity    = $regel.Security
    $RuleRmtGrp      = $regel.Rmtcomputergrp
    $RuleUsrGrp      = $regel.Rmtusrgrp

    # === Befehl aufbauen ===
    $command = "netsh advfirewall firewall add rule"
    if ($RuleName)        { $command += " name=`"$RuleName`"" }
    if ($RuleDir)         { $command += " dir=$RuleDir" }
    if ($RuleAction)      { $command += " action=$RuleAction" }
    if ($RuleProgram)     { $command += " program=`"$RuleProgram`"" }
    if ($RuleService)     { $command += " service=$RuleService" }
    if ($RuleDescription) { $command += " description=`"$RuleDescription`"" }
    if ($RuleActive)      { $command += " enable=$RuleActive" }
    if ($RuleProfile)     { $command += " profile=$RuleProfile" }
    if ($RuleLocalIP)     { $command += " localip=$RuleLocalIP" }
    if ($RuleRemoteIP)    { $command += " remoteip=$RuleRemoteIP" }
    # Ports nur hinzufügen, wenn das Protokoll TCP oder UDP ist
if ($RuleProtocol -in @('TCP', 'UDP')) {
    if ($RuleLocalPort)   { $command += " localport=$RuleLocalPort" }
    if ($RuleRemotePort)  { $command += " remoteport=$RuleRemotePort" }
}
#    if ($RuleLocalPort)   { $command += " localport=$RuleLocalPort" }
#    if ($RuleRemotePort)  { $command += " remoteport=$RuleRemotePort" }
#    if ($RuleProtocol)    { $command += " protocol=$RuleProtocol" }
    if ($RuleInterface)   { $command += " interfacetype=$RuleInterface" }
    if ($RuleRmtGrp)      { $command += " rmtcomputergrp=$RuleRmtGrp" }
    if ($RuleUsrGrp)      { $command += " rmtusrgrp=$RuleUsrGrp" }
    if ($RuleEdge)        { $command += " edge=$RuleEdge" }
    if ($RuleSecurity)    { $command += " security=$RuleSecurity" }

    # === Befehl anzeigen oder ausführen ===
    Write-Host "-> Regel wird ausgeführt: $command" -ForegroundColor Cyan

    # Optional ausführen:
    Invoke-Expression $command
}
