# Compila UNA sola APK de BotMp3 (version con SQLite, por defecto).
# Uso: pwsh -File scripts/build-apk.ps1 -Version 1.9.102 -Code 158
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][int]$Code
)
$ErrorActionPreference = "Stop"
$ws = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$proj = $PSScriptRoot | Split-Path -Parent
$fl = Join-Path $ws "_tools\flutter"
$jdk = Join-Path $env:USERPROFILE ".jdks\jbr-21.0.11"
$git = Join-Path $ws "_tools\git\cmd\git.exe"
$sdk = "C:\Users\Julio\AppData\Local\Android\Sdk"
$env:FLUTTER_ROOT = $fl
$env:JAVA_HOME = $jdk
$env:TEMP = Join-Path $ws "_tools\tmp"; $env:TMP = $env:TEMP
$env:PUB_CACHE = Join-Path $ws "_tools\pub-cache"
$env:APPDATA = Join-Path $ws "_tools\appdata"
$env:LOCALAPPDATA = Join-Path $ws "_tools\localappdata"
$env:GRADLE_USER_HOME = Join-Path $ws "_tools\gradle-home"
$env:GRADLE_OPTS = "-Dorg.gradle.caching=false -Dorg.gradle.daemon=false"
$env:ANDROID_HOME = $sdk; $env:ANDROID_SDK_ROOT = $sdk
$env:Path = "$(Split-Path $git -Parent);$fl\bin;$jdk\bin;$env:Path"
$dart = Join-Path $fl "bin\cache\dart-sdk\bin\dart.exe"
$tool = Join-Path $fl "packages\flutter_tools\bin\flutter_tools.dart"
$pkg = Join-Path $fl "packages\flutter_tools\.dart_tool\package_config.json"

Set-Location $proj
Write-Host "Version: $Version+$Code"
$pv = [IO.File]::ReadAllText((Join-Path $proj "pubspec.yaml"))
$pv = $pv -replace "version: [0-9.+]+\+[0-9]+", "version: $Version+$Code"
[IO.File]::WriteAllText((Join-Path $proj "pubspec.yaml"), $pv, (New-Object System.Text.UTF8Encoding($false)))

Get-Process java, dart -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 4
& $dart --packages=$pkg $tool --suppress-analytics build apk --release `
    --target-platform android-arm64 --no-pub --dart-define=BOTMP3_SQLITE=true
if ($LASTEXITCODE -ne 0) { Write-Host "FALLO la compilacion"; exit 1 }

$apk = Join-Path $proj "build\app\outputs\flutter-apk\app-release.apk"
$destino = Join-Path $ws "BotMp3-$Version.apk"
Copy-Item $apk $destino -Force
New-Item -ItemType Directory -Force (Join-Path $proj "apk") | Out-Null
Get-ChildItem (Join-Path $proj "apk") -Filter "BotMp3-*.apk" | Remove-Item -Force
Copy-Item $apk (Join-Path $proj "apk\BotMp3-$Version.apk") -Force
Write-Host ("APK: " + $destino + " (" + [math]::Round((Get-Item $destino).Length / 1MB, 2) + " MB)")