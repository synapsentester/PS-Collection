# Aktuelle Zeit in UTC
$utcDateTime = (Get-Date).ToUniversalTime()

# Aktuelle Zeit in Deutschland (Berlin)
$germanTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("W. Europe Standard Time")
$germanDateTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($utcDateTime, $germanTimeZone)

# Funktion zur Berechnung der lokalen Zeit basierend auf der Zeitzone
function GetLocalTime {
    param(
        [string]$timeZoneId
    )

    $localTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($timeZoneId)
    $localDateTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($utcDateTime, $localTimeZone)
    return $localDateTime
}

# Liste aller verfügbaren Zeitzone-IDs und deren Anzeigenamen
$timeZones = [System.TimeZoneInfo]::GetSystemTimeZones() | Select-Object @{Name="ID"; Expression={$_.Id}}, DisplayName

# Ausgabe der nummerierten verfügbaren Zeitzonen zur Auswahl
Write-Host "Verfügbare Zeitzonen zur Auswahl:"
for ($i = 0; $i -lt $timeZones.Count; $i++) {
    $zoneId = ($i + 1).ToString("000")  # Dreistellige Nummerierung für die Auswahl
    Write-Host "$zoneId. $($timeZones[$i].ID) - $($timeZones[$i].DisplayName)"
}

# Auswahl der Zeitzone durch den Benutzer
$selection = Read-Host "Bitte geben Sie die dreistellige Nummer der Zeitzone aus der Liste oben ein (z.B. '001' für die erste Zeitzone):"

# Validierung der Benutzereingabe
$selectionNumber = [int]$selection
if ($selectionNumber -ge 1 -and $selectionNumber -le $timeZones.Count) {
    $selectedTimeZoneId = $timeZones[$selectionNumber - 1].ID.Trim()
} else {
    Write-Host "Ungültige Auswahl. Bitte geben Sie eine gültige dreistellige Nummer aus der Liste ein."
    exit
}

# Beispiel für lokale Zeit in der ausgewählten Zeitzone
$localDateTime = GetLocalTime -timeZoneId $selectedTimeZoneId

# Formatieren der Ausgaben im gewünschten Format
$outputUTC = "{0}{1}Z{2}{3}" -f $utcDateTime.ToString('dd'), $utcDateTime.ToString('HHmm'), $utcDateTime.ToString('MMM'), $utcDateTime.ToString('yy')
$outputGerman = "{0}{1}B{2}{3}" -f $germanDateTime.ToString('dd'), $germanDateTime.ToString('HHmm'), $germanDateTime.ToString('MMM'), $germanDateTime.ToString('yy')
$outputLocal = "{0}{1}L{2}{3}" -f $localDateTime.ToString('dd'), $localDateTime.ToString('HHmm'), $localDateTime.ToString('MMM'), $localDateTime.ToString('yy')

# Ausgabe der Ergebnisse
Write-Output $outputUTC
Write-Output $outputGerman
Write-Output $outputLocal
