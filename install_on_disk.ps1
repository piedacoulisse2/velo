#Start-Process powershell -Verb RunAs -ArgumentList "-Command iex (iwr 'https://raw.githubusercontent.com/piedacoulisse2/velo/refs/heads/main/install_on_disk.ps1' -UseBasicParsing).Content"
#iex (iwr 'https://raw.githubusercontent.com/piedacoulisse2/velo/refs/heads/main/install_on_disk.ps1' -UseBasicParsing).Content
$url = "https://github.com/piedacoulisse2/velo/releases/download/v1.0/velociraptor-v0.73.3-windows-amd64.msi"

try {
    # Création d'un espace tampon dans %TEMP% qui sera automatiquement nettoyé
    $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName() + ".msi")
    
    Write-Host "Téléchargement du MSI..."
    
    # Utilisation de System.Net.WebClient pour le téléchargement
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $tempFile)
    
    Write-Host "Installation du MSI..."
    
    # Paramètres d'installation silencieuse
    $arguments = @(
        "/i"
        $tempFile
        "/qn"        # Installation silencieuse
        "/norestart" # Pas de redémarrage
        "/L*v"       # Logging détaillé
        "$env:TEMP\msi_install.log" # Fichier de log
    )
    
    # Installation via Windows Installer
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
    
    # Vérification du statut
    if ($process.ExitCode -eq 0) {
        Write-Host "Installation terminée avec succès."
    } else {
        Write-Host "Erreur lors de l'installation. Code de sortie : $($process.ExitCode)"
        Write-Host "Consultez le fichier log pour plus de détails : $env:TEMP\msi_install.log"
    }
}
catch {
    Write-Host "Erreur : $_"
}
finally {
    # Nettoyage
    if (Test-Path $tempFile) {
        Remove-Item -Force $tempFile
    }
    if ($webClient) {
        $webClient.Dispose()
    }
}
