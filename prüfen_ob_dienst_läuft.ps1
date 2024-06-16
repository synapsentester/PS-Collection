Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-ServiceStatus {
    param (
        [string[]]$serviceNames
    )

    # Erstellen des Formulars
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Dienststatus"
    $form.StartPosition = "CenterScreen"
    $form.Size = New-Object System.Drawing.Size(400, 600)

    # Erstellen des Panels
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 0)
    $panel.Size = New-Object System.Drawing.Size(400, 500)
    $panel.AutoScroll = $true
    $form.Controls.Add($panel)

    # Erstellen des Exit-Buttons
    $exitButton = New-Object System.Windows.Forms.Button
    $exitButton.Text = "Exit"
    $exitButton.Size = New-Object System.Drawing.Size(75, 30)
    $exitButton.Location = New-Object System.Drawing.Point(10, 510)
    $exitButton.Add_Click({
        $form.Close()
    })
    $form.Controls.Add($exitButton)

    # Erstellen des Timers
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 2000 # Timer-Intervall in Millisekunden (hier: 2 Sekunden)
    
    $timer.Add_Tick({
        try {
            # Leeren des Panels, um die aktualisierten Dienststatus anzuzeigen
            $panel.Controls.Clear()

            $y = 10

            foreach ($serviceName in $serviceNames) {
                $services = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($services) {
                    foreach ($service in $services) {
                        if ($service.Status -ne $null) {
                            # Erstellen eines Labels für den Dienststatus
                            $label = New-Object System.Windows.Forms.Label
                            $label.Text = "$($service.Status): $($service.Name)"
                            $label.Location = New-Object System.Drawing.Point(10, $y)
                            $label.AutoSize = $true
                            
                            # Setzen der Schriftfarbe basierend auf dem Dienststatus
                            switch ($service.Status) {
                                'Running' { $label.ForeColor = [System.Drawing.Color]::Green }
                                'Stopped' { $label.ForeColor = [System.Drawing.Color]::Red }
                                default { $label.ForeColor = [System.Drawing.Color]::Black }
                            }

                            # Hinzufügen des Labels zum Panel
                            $panel.Controls.Add($label)
                            $y += 25
                        }
                    }
                } else {
                    # Dienst nicht gefunden oder Fehler bei der Abfrage
                    $label = New-Object System.Windows.Forms.Label
                    $label.Text = "Dienst $serviceName nicht gefunden oder Fehler bei der Abfrage."
                    $label.Location = New-Object System.Drawing.Point(10, $y)
                    $label.AutoSize = $true
                    $label.ForeColor = [System.Drawing.Color]::Black
                    $panel.Controls.Add($label)
                    $y += 25
                }
            }
        } catch {
            # Fehlerbehandlung
            $label = New-Object System.Windows.Forms.Label
            $label.Text = "Fehler: $_"
            $label.Location = New-Object System.Drawing.Point(10, $y)
            $label.AutoSize = $true
            $label.ForeColor = [System.Drawing.Color]::Red
            $panel.Controls.Add($label)
        }
    })
    
    # Starten des Timers, um die Aktualisierung regelmäßig auszuführen
    $timer.Start()

    # Anzeigen des Formulars
    $form.ShowDialog()
}

# Beispielaufruf der Funktion mit einer Liste von Dienstnamen
$serviceNames = @("vm*", "vmcompute", "WSearch")
Get-ServiceStatus -serviceNames $serviceNames
