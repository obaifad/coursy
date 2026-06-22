# Imports Windows Root CA certificates into a Gradle truststore to fix PKIX/SSL errors.
# Run from the project root: powershell -ExecutionPolicy Bypass -File scripts/fix_java_ssl.ps1

$javaHome = "C:\Program Files\Android\Android Studio\jbr"
$keytool = Join-Path $javaHome "bin\keytool.exe"
$srcCacerts = Join-Path $javaHome "lib\security\cacerts"
$destCacerts = Join-Path $env:USERPROFILE ".gradle\cacerts-custom"

if (-not (Test-Path $keytool)) {
    Write-Error "keytool not found in: $javaHome"
    exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $destCacerts) | Out-Null
Copy-Item -Force $srcCacerts $destCacerts

$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "CurrentUser")
$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)

$i = 0
foreach ($cert in $store.Certificates) {
    $i++
    $temp = Join-Path $env:TEMP "win-root-$i.cer"
    [System.IO.File]::WriteAllBytes($temp, $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
    & $keytool -importcert -noprompt -trustcacerts -alias "winroot$i" -file $temp -keystore $destCacerts -storepass changeit 2>$null
    Remove-Item $temp -Force -ErrorAction SilentlyContinue
}
$store.Close()

Write-Host "Imported $i certificates into: $destCacerts"
Write-Host "Restart Gradle, then run: flutter run -d <device-id>"
