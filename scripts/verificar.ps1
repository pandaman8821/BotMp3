# Verificacion automatica de BotMp3 (ejecutar antes de entregar cada version)
# Uso: pwsh -File scripts/verificar.ps1 [-Build]
param([switch]$Build)
$ErrorActionPreference = "Continue"
$ws = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$proj = $PSScriptRoot | Split-Path -Parent
$fl = Join-Path $ws "_tools\flutter"
$jdk = Join-Path $env:USERPROFILE ".jdks\jbr-21.0.11"
$git = Join-Path $ws "_tools\git\cmd\git.exe"
$py = "C:\Users\Julio\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe"
Set-Location $proj
$env:FLUTTER_ROOT = $fl; $env:JAVA_HOME = $jdk
$env:TEMP = Join-Path $ws "_tools\tmp"; $env:TMP = $env:TEMP
$env:PUB_CACHE = Join-Path $ws "_tools\pub-cache"
$env:APPDATA = Join-Path $ws "_tools\appdata"; $env:LOCALAPPDATA = Join-Path $ws "_tools\localappdata"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\..\..\..\AppData\Local\Android\Sdk"
$env:ANDROID_HOME = "C:\Users\Julio\AppData\Local\Android\Sdk"; $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:Path = "$(Split-Path $git -Parent);$fl\bin;$jdk\bin;$env:Path"
$dart = "$fl\bin\cache\dart-sdk\bin\dart.exe"
$tool = "$fl\packages\flutter_tools\bin\flutter_tools.dart"
$pkg = "$fl\packages\flutter_tools\.dart_tool\package_config.json"
$fail = 0
function Seccion($t) { Write-Host ""; Write-Host "=== $t ===" }
function Ok($m) { Write-Host ("  [OK]   " + $m) }
function Fallo($m) { Write-Host ("  [FALLO] " + $m); $global:fail++ }

Seccion "1. Dependencias (offline)"
& $dart pub get --offline 2>&1 | Select-Object -Last 1 | ForEach-Object { Ok $_ }

Seccion "2. Analisis estatico"
$an = & $dart analyze 2>&1
$errores = ($an | Select-String -Pattern "^\s*error").Count
if ($errores -eq 0) { Ok "dart analyze sin errores" } else { Fallo "$errores errores de analisis" }

Seccion "3. Pruebas unitarias / widget"
$testOut = & $dart --packages=$pkg $tool --suppress-analytics test 2>&1
$resumen = ($testOut | Select-String -Pattern "\+\d+.*(Some tests failed|All tests passed)") | Select-Object -Last 1
if ($resumen -and $resumen.Line -match "All tests passed") { Ok $resumen.Line.Trim() } else { Fallo ("tests: " + ((if ($resumen) { $resumen.Line } else { "sin resultado" }))) }

Seccion "4. Localizacion (claves usadas vs definidas)"
$l10n = & $py (Join-Path $ws "_tools\l10ncheck.py") 2>&1
$usadasSinDefinir = 0; $lineaSin = ($l10n | Select-String -Pattern "usadas sin definir: (\[.*\])" | Select-Object -First 1); if ($lineaSin) { $lista = $lineaSin.Matches[0].Groups[1].Value; if ($lista -ne "[]") { $usadasSinDefinir = 1 } }
$l10n | Select-Object -First 4 | ForEach-Object { Write-Host ("  " + $_) }
if ($usadasSinDefinir -eq 0) { Ok "sin claves usadas sin definir" } else { Fallo "hay claves usadas sin definir" }

Seccion "5. Texto espanol en la interfaz"
$ui = & $py (Join-Path $ws "_tools\uies.py") 2>&1
$total = ($ui | Select-String -Pattern "textos de UI en espanol: (\d+)").Matches
$n = if ($total.Count -gt 0) { [int]($ui | Select-String -Pattern "textos de UI en espanol: (\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value } | Select-Object -First 1) } else { -1 }
Write-Host ("  textos de UI en espanol: " + $n)
if ($n -eq 0) { Ok "interfaz sin textos en espanol" } elseif ($n -gt 0) { Fallo "$n textos de UI siguen en espanol" }

if ($Build) {
  Seccion "6. Compilacion APK (arm64)"
  & $dart --packages=$pkg $tool --suppress-analytics build apk --release --target-platform android-arm64 --no-pub 2>&1 | Out-File -Encoding utf8 (Join-Path $ws "_tools\verify-build.log")
  $apk = "build\app\outputs\flutter-apk\app-release.apk"
  if (Test-Path $apk) { Ok ("APK generada: " + [math]::Round((Get-Item $apk).Length/1MB,1) + " MB") } else { Fallo "APK no generada" }
}

Write-Host ""
if ($fail -eq 0) { Write-Host "RESULTADO: TODO OK" } else { Write-Host ("RESULTADO: " + $global:fail + " FALLOS") }
exit $global:fail