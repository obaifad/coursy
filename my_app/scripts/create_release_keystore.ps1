# إنشاء مفتاح توقيع الإصدار (Google Play) + ملف android/key.properties.
#
# التشغيل من مجلد my_app:
#   powershell -ExecutionPolicy Bypass -File scripts\create_release_keystore.ps1
#
# مهم جداً: احتفظ بنسخة احتياطية من ملف المفتاح وكلمة المرور خارج هذا الجهاز.
# بدونهما لا يمكن نشر أي تحديث للتطبيق على Google Play لاحقاً.
# الملفان (upload-keystore.jks و key.properties) مستثنيان من git ولا يجب رفعهما أبداً.

$ErrorActionPreference = "Stop"
$appDir = Split-Path $PSScriptRoot -Parent
$androidDir = Join-Path $appDir "android"
$keystorePath = Join-Path $env:USERPROFILE "coursy-upload-keystore.jks"
$propertiesPath = Join-Path $androidDir "key.properties"
$alias = "upload"

if (Test-Path $keystorePath) {
  Write-Error "يوجد مفتاح مسبقاً في $keystorePath — لن يُستبدل. احذفه يدوياً إن كنت متأكداً."
}

$keytool = @(
  "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
  (Join-Path $env:JAVA_HOME "bin\keytool.exe")
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $keytool) { Write-Error "لم يُعثر على keytool (يأتي مع Android Studio)." }

$secure = Read-Host "كلمة مرور المفتاح (6 أحرف على الأقل)" -AsSecureString
$confirm = Read-Host "أعد كتابة كلمة المرور" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
$password2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirm))
if ($password -ne $password2) { Write-Error "كلمتا المرور غير متطابقتين." }
if ($password.Length -lt 6) { Write-Error "كلمة المرور قصيرة (6 أحرف على الأقل)." }

& $keytool -genkeypair -v `
  -keystore $keystorePath -alias $alias `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -storepass $password -keypass $password `
  -dname "CN=Coursy, O=Coursy, C=SY"
if ($LASTEXITCODE -ne 0) { Write-Error "فشل إنشاء المفتاح." }

$storeFile = $keystorePath.Replace('\', '/')
@"
storePassword=$password
keyPassword=$password
keyAlias=$alias
storeFile=$storeFile
"@ | Set-Content -Encoding ascii $propertiesPath

Write-Host ""
Write-Host "تم. المفتاح: $keystorePath"
Write-Host "الإعداد:  $propertiesPath"
Write-Host "انسخ ملف المفتاح وكلمة المرور إلى مكان آمن الآن (مدير كلمات مرور / تخزين خارجي)."
Write-Host "بناء نسخة النشر: flutter build appbundle"
