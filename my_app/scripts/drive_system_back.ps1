# يشغّل integration_test/system_back_test.dart ويرسل زر الرجوع الحقيقي (KEYCODE_BACK) كلما طبع التطبيق
# SYSBACK_READY. الاستعمال (من my_app):
#   powershell -File scripts/drive_system_back.ps1 -Device emulator-5554
param(
  [Parameter(Mandatory = $true)][string]$Device,
  [string]$Adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
)

& $Adb -s $Device logcat -c
$watcher = Start-Job -ArgumentList $Adb, $Device -ScriptBlock {
  param($adb, $device)
  $sent = @{}
  & $adb -s $device logcat -v brief 'flutter:I' '*:S' | ForEach-Object {
    if ($_ -match 'SYSBACK_READY (\d+)' -and -not $sent.ContainsKey($Matches[1])) {
      $sent[$Matches[1]] = $true
      Start-Sleep -Milliseconds 300
      & $adb -s $device shell input keyevent 4
      "sent BACK for step $($Matches[1])"
    }
  }
}

flutter drive --profile --driver=test_driver/integration_test.dart --target=integration_test/system_back_test.dart -d $Device
$code = $LASTEXITCODE
Stop-Job $watcher | Out-Null
Receive-Job $watcher
Remove-Job $watcher -Force | Out-Null
exit $code
