<#.DESCRIPTION
SF Koch 20240520
#>
Push-Location $(Split-Path $Script:MyInvocation.MyCommand.Path)

#In einem Ordner File auswählen mit Filter
Add-Type -AssemblyName System.Windows.Forms

# Erstelle ein neues OpenFileDialog-Objekt
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog

# Filter festlegen, um nur CSV- und TXT-Dateien anzuzeigen
$OpenFileDialog.Filter = "CSV-Dateien (*.csv)|*.csv|TXT-Dateien (*.txt)|*.txt"

# Zeige den Dialog an und überprüfe, ob der Benutzer eine Datei ausgewählt hat
if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    # Speichere den Dateipfad in der Variable $filepath
    $filepath = $OpenFileDialog.FileName
    Write-Output "Ausgewählter Dateipfad: $filepath"
} else {
    Write-Output "Es wurde keine CSV- oder TXT-Datei ausgewählt."
}

$userFile = $filepath

# Funktion zum Überprüfen, ob ein Benutzerkonto bereits existiert
Function UserExists($username) {
    $existingUser = Get-LocalUser -Name $username -ErrorAction SilentlyContinue
    return [bool]($existingUser)
}

# Funktion zum Überprüfen, ob ein Benutzer in einer Gruppe ist
Function IsUserInGroup($username, $groupname) {
    $groupMembers = Get-LocalGroupMember -Group $groupname -ErrorAction SilentlyContinue
    return $groupMembers.Name -contains $username
}

# Funktion zum Erstellen eines Benutzerkontos
Function CreateNewUser($username, $fullname, $description, $password) {
    New-LocalUser -Name $username -FullName $fullname -Description $description -Password (ConvertTo-SecureString $password -AsPlainText -Force) -AccountNeverExpires:$false -UserMayNotChangePassword:$false | Set-LocalUser -PasswordNeverExpires:$false
    Write-Host " "
    Write-Host "Benutzerkonto '$username' wurde erfolgreich erstellt."
    
    # Erzwinge die Passwortänderung bei der ersten Anmeldung
    net user $username /logonpasswordchg:yes
    Write-Host "Benutzerkonto '$username' muss das Passwort bei der ersten Anmeldung ändern."
}

# Funktion zum Hinzufügen eines Benutzers zu einer Gruppe
Function AddUserToGroup($username, $groupname) {
    Add-LocalGroupMember -Group $groupname -Member $username
    Write-Host "Benutzerkonto '$username' wurde der Gruppe '$groupname' hinzugefügt."
}

# Funktion zum Entfernen eines Benutzers aus einer Gruppe
Function RemoveUserFromGroup($username, $groupname) {
    Remove-LocalGroupMember -Group $groupname -Member $username -ErrorAction SilentlyContinue
    Write-Host "Benutzerkonto '$username' wurde aus der Gruppe '$groupname' entfernt."
}

# Lese die Benutzerdaten aus der Datei und erstelle die Benutzerkonten
Import-Csv $userFile | ForEach-Object {
    $username = $_.Name
    $fullname = $_.FullName
    $description = $_.Description
    $password = $_.Password
    $group = $_.Group

    if (-not (UserExists $username)) {
        CreateNewUser $username $fullname $description $password
        AddUserToGroup $username $group
    } else {
        Write-Host "Benutzerkonto '$username' existiert bereits."
        if (-not (IsUserInGroup $username, $group)) {
            AddUserToGroup $username $group
            Write-Host "Benutzerkonto '$username' wurde der Gruppe '$group' hinzugefügt."
        } else {
            Write-Host "Benutzerkonto '$username' ist bereits in der Gruppe '$group'."
        }
    }

    # Wenn Benutzer der Gruppe "Administratoren" zugeordnet wird, aus der Gruppe "Benutzer" entfernen
    if ($group -eq "Administratoren" -and (IsUserInGroup $username "Benutzer")) {
        RemoveUserFromGroup $username "Benutzer"
    }
}