# Regeln mit vollständigen Eigenschaften exportieren, inklusive Programmpfad

Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)
$exportRule = "..\02-Data\firewall_rules_$env:COMPUTERNAME.csv"

# Prüfen ob die Exportdatei schon existiert – wenn ja, löschen
if (Test-Path $exportRule) {
    Remove-Item $exportRule -Force
}


# Eingabeaufforderung für den Benutzer
$searchTerm = Read-Host "Bitte gib den Teil des DisplayName ein, nach dem du suchen möchtest (z. B. '*tom*')"

# Sicherstellen, dass der Benutzer Wildcards verwenden kann
if ([string]::IsNullOrEmpty($searchTerm)) {
    $searchTerm = "*"
}
$rules = Get-NetFirewallRule -DisplayName $searchTerm -ErrorAction SilentlyContinue

if ($rules) {


$totalRules = $rules.Count
$counter = 0


$rules | ForEach-Object {
    $rule = $_

    # Zugehörige Filter holen
    $AddrFilter    = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $rule
    $AppFilter     = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $rule
    $InterfaceType   = Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $rule
    $InterfaceTypeFilter    = Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $rule
    $PortFilter    = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule
<#  #$Profile    = Get-NetFirewallProfile -AssociatedNetFirewallRule $rule                   doppel Moppel? vielleicht später genauer schauen#>
<#    $SecFilter    = Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $rule         bei Eigenschaften prüfen ob und dann wie umzusetzen#>
    $ServiceFilter = Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $rule


    # Eigenschaften zusammensetzen
    $props = [ordered]@{
        DisplayName    = $rule.DisplayName
<#      Name           = $rule.Name  wird nicht unbedingt benötigt, da nur für das zu exportierende System richtig benamt#>
        Direction      = $rule.Direction
        Action         = $rule.Action
        Enabled        = $rule.Enabled
        Profile        = $rule.Profile
        Program        = if ($AppFilter) { $AppFilter.Program } else { "" }
        Service        = if ($ServiceFilter) {$ServiceFilter.Service }else { "" }
        Protocol       = if ($PortFilter){$PortFilter.Protocol }else { "" }
        LocalPort      = if ($PortFilter){$PortFilter.LocalPort }else { "" }
        RemotePort     = if ($PortFilter){$PortFilter.RemotePort }else { "" }
        LocalAddress   = if ($AddrFilter){($AddrFilter.LocalAddress -join ", ")}else { "" }
        RemoteAddress  = if ($AddrFilter){($AddrFilter.RemoteAddress -join ", ")}else { "" }
<#        SecurityFilter = $SecFilter.Authentication
        Authentication     : NotRequired
        Encryption         : NotRequired
        OverrideBlockRules : False
        LocalUser          : Any
        RemoteUser         : Any
        RemoteMachine      : Any
#>
        Interface      = if ($InterfaceType){$InterfaceType.InterfaceAlias }else { "" }
        InterfaceType  = if ($InterfaceType){$InterfaceTypeFilter.InterfaceType }else { "" }
        Description    = $rule.Description
    }

    # Fortschritt aktualisieren
    $counter++
    Write-Progress -PercentComplete (($counter / $totalRules) * 100) `
        -Status "Verarbeite Firewall-Regeln" `
        -Activity "$counter von $totalRules Regeln bearbeitet"

    # Objekt direkt exportieren
    [PSCustomObject]$props | Export-Csv -Path $exportRule -Append -NoTypeInformation -Encoding UTF8
    #anzeigen
    #[PSCustomObject]$props

}
} else {
    
    Write-Host "Es wurden keine Regeln mit dem DisplayName '$searchTerm' gefunden."
}