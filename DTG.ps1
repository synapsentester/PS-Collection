# Aktuelles Datum und Uhrzeit abrufen
$currentDateTime = (Get-Date).ToUniversalTime()
#$currentDateTime = Get-Date

# Datum im Format Tag (z.B. 16)
$datePart = '{0:D2}' -f $currentDateTime.Day

# Uhrzeit im Format HHMM (z.B. 0106)
$timePart = '{0:HHmm}' -f $currentDateTime

# Lokale Zeitzone (B für Berlin, könnte angepasst werden je nach lokaler Zeitzone, hier wurd Z für UTC gesetzt)
$timezone = 'Z'

# Monat im Format Mon (z.B. jun)
$monthPart = '{0:MMM}' -f $currentDateTime

# Jahr im Format YY (z.B. 24)
$yearPart = '{0:yy}' -f $currentDateTime

# Gesamtes Format zusammenstellen
$output = "{0}{1}{2}{3}{4}" -f $datePart, $timePart, $timezone, $monthPart, $yearPart

# Ausgabe
Write-Output $output
