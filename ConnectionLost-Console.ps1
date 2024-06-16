function Check-InternetConnection {           
    param (
        [string]$target
    )
    
    try {
        $null = Test-Connection -ComputerName $target -Count 1 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Visual-Feedback {
    param (
        [string]$target,
        [bool]$status
    )

    if ($status) {
        Write-Host "$target connected" -ForegroundColor DarkGreen
    } else {
        Write-Host "$target lost connection!" -ForegroundColor Red
    }
}

function Audible-Feedback {
    param (
        [array]$beepPatterns
    )

    foreach ($beep in $beepPatterns) {
        [console]::beep($beep.frequency, $beep.duration)
    }
}

# Liste der Ziele, die überprüft werden sollen
$targets = @("8.8.8.8", "4.2.2.2", "www.google.com")

# Hash-Tabelle zur Zuordnung der Ziele zu den Beep-Mustern
$beepPatterns = @{
    "8.8.8.8" = @(
        @{ "frequency" = 200; "duration" = 300 },
        @{ "frequency" = 700; "duration" = 800 },
        @{ "frequency" = 700; "duration" = 800 },
        @{ "frequency" = 200; "duration" = 800 }
    )
    "4.2.2.2" = @(
        @{ "frequency" = 900; "duration" = 800 },
        @{ "frequency" = 900; "duration" = 300 },
        @{ "frequency" = 400; "duration" = 800 },
        @{ "frequency" = 400; "duration" = 800 }
    )
    "www.google.com" = @(
        @{ "frequency" = 500; "duration" = 800 },
        @{ "frequency" = 500; "duration" = 800 },
        @{ "frequency" = 100; "duration" = 300 },
        @{ "frequency" = 100; "duration" = 800 }
    )
}

while ($true) {
    foreach ($target in $targets) {
        $internetStatus = Check-InternetConnection -target $target
        Visual-Feedback -target $target -status $internetStatus
        if (-not $internetStatus) {
            $beepPattern = $beepPatterns[$target]
            Audible-Feedback -beepPatterns $beepPattern  # Akustisches Feedback nur bei fehlender Verbindung
        }
    }
    Start-Sleep -Seconds 5  # Überprüfen Sie die Verbindung alle 5 Sekunden
}
