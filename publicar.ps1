# =====================================================================
#  BotMp3 - Publicación automática en GitLab + apertura de la petición
#  a F-Droid.  Ejecuta:  .\publicar.ps1
# ---------------------------------------------------------------------
#  Hace TODO lo que se puede automatizar:
#    1. Comprueba que Git esté disponible.
#    2. Crea el repositorio en tu GitLab (público) si aún no existe.
#    3. Sube el código (rama main) y la etiqueta v1.4.3.
#    4. Borra el token del remoto (no queda guardado).
#    5. Copia el texto de la petición al portapapeles y abre la web.
#
#  Solo necesitas un token de GitLab con permiso "api" (o "write_repository"):
#    GitLab > tu avatar > Edit profile > Access tokens > Add new token
#    Name: botmp3  |  Scopes: api  |  Expiration: 1-7 días
#  Cuando termine, REVOCA el token (o déjalo caducar).
# =====================================================================

param(
    [string]$Usuario = "pandamanlab",
    [string]$Proyecto = "BotMp3",
    [string]$Token = "",
    [string]$Nombre = "pandamanlab",
    [string]$Correo = "pandamanrd@gmail.com"
)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $raiz

function Info($texto) { Write-Host "  $texto" -ForegroundColor Gray }
function Ok($texto) { Write-Host "  [OK] $texto" -ForegroundColor Green }
function Aviso($texto) { Write-Host "  [!] $texto" -ForegroundColor Yellow }

Write-Host ""
Write-Host "=== BotMp3: publicar en GitLab y preparar la peticion a F-Droid ===" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------- 1. Git
$git = "git"
try { & $git --version 2>$null | Out-Null } catch { $git = $null }
if (-not $git) {
    $candidatos = @(
        "$raiz\..\_tools\git\cmd\git.exe",
        "C:\Program Files\Git\cmd\git.exe",
        "C:\Program Files (x86)\Git\cmd\git.exe"
    )
    foreach ($c in $candidatos) { if (Test-Path $c) { $git = (Resolve-Path $c).Path; break } }
}
if (-not $git) { Aviso "No encuentro Git. Instalalo desde https://git-scm.com/download/win y vuelve a ejecutar."; exit 1 }
Ok "Git: $git"

if (-not (Test-Path "$raiz\.git")) { Aviso "Esta carpeta no es un repositorio git."; exit 1 }
& $git -C $raiz config user.name $Nombre | Out-Null
& $git -C $raiz config user.email $Correo | Out-Null
Ok "Identidad configurada: $Nombre <$Correo>"

# ---------------------------------------------------------------- 2. Token
if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Host ""
    Info "Pega tu token de GitLab (no se verá al escribir) y pulsa Enter:"
    $seguro = Read-Host -AsSecureString
    $Token = [System.Net.NetworkCredential]::new("", $seguro).Password
}
if ([string]::IsNullOrWhiteSpace($Token)) { Aviso "Sin token no se puede publicar. Abortando."; exit 1 }
Ok "Token recibido ($($Token.Length) caracteres)"

$api = "https://gitlab.com/api/v4"
$cabeceras = @{ "PRIVATE-TOKEN" = $Token }

# ---------------------------------------------------------------- 3. Proyecto
Write-Host ""
Info "Comprobando el repositorio $Usuario/$Proyecto ..."
$existe = $false
try {
    Invoke-RestMethod -Method Get -Uri "$api/projects/$Usuario%2F$Proyecto" -Headers $cabeceras | Out-Null
    $existe = $true
    Ok "El repositorio ya existe; se subirá el codigo en él."
} catch {
    Info "No existe todavía: se crea ahora."
}

if (-not $existe) {
    $cuerpo = @{
        name        = $Proyecto
        path        = $Proyecto
        visibility  = "public"
        description = "Reproductor de musica offline con IA, listas, editor de caratulas, ranking y tendencias."
    } | ConvertTo-Json
    try {
        Invoke-RestMethod -Method Post -Uri "$api/projects" -Headers $cabeceras `
            -Body $cuerpo -ContentType "application/json" | Out-Null
        Ok "Repositorio creado (público): https://gitlab.com/$Usuario/$Proyecto"
        Start-Sleep -Seconds 3
    } catch {
        Aviso "No se pudo crear automáticamente: $($_.Exception.Message)"
        Aviso "Créalo a mano (vacío) en https://gitlab.com/projects/new y vuelve a ejecutar."
        exit 1
    }
}

# ---------------------------------------------------------------- 4. Push
Write-Host ""
Info "Subiendo el código (rama main) y la etiqueta v1.4.3 ..."
$urlConToken = "https://oauth2:$Token@gitlab.com/$Usuario/$Proyecto.git"
& $git -C $raiz remote remove origin 2>$null | Out-Null
& $git -C $raiz remote add origin $urlConToken | Out-Null

& $git -C $raiz push -u origin main
if ($LASTEXITCODE -ne 0) { Aviso "El push de main falló (revisa el token y sus permisos)."; exit 1 }
Ok "Rama main subida"

& $git -C $raiz push origin v1.4.3
if ($LASTEXITCODE -ne 0) { Aviso "La etiqueta v1.4.3 no se pudo subir." } else { Ok "Etiqueta v1.4.3 subida" }

# El token NO se queda guardado en el remoto
& $git -C $raiz remote set-url origin "https://gitlab.com/$Usuario/$Proyecto.git" | Out-Null
Ok "Token eliminado del remoto (configurado como https://gitlab.com/$Usuario/$Proyecto.git)"

# ---------------------------------------------------------------- 5. RFP
Write-Host ""
$rfp = Join-Path $raiz "RFP.md"
if (Test-Path $rfp) {
    $texto = [System.IO.File]::ReadAllText($rfp)
    # Se copia todo el documento; el título y el cuerpo están listos para pegar.
    Set-Clipboard -Value $texto
    Ok "Texto de la petición copiado al portapapeles (RFP.md)"
}

Write-Host ""
Write-Host "=== Todo listo ===" -ForegroundColor Green
Write-Host "  Repositorio: https://gitlab.com/$Usuario/$Proyecto" -ForegroundColor White
Write-Host "  Etiqueta:    v1.4.3" -ForegroundColor White
Write-Host ""
Write-Host "  Último paso (manual, 30 segundos):" -ForegroundColor Yellow
Write-Host "   1) Se va a abrir la página de peticiones de F-Droid." -ForegroundColor Yellow
Write-Host "   2) Pega el portapapeles (Ctrl+V) y envía." -ForegroundColor Yellow
Write-Host ""
Info "Recuerda: revoca el token en GitLab cuando termines."
Write-Host ""

try { Start-Process "https://gitlab.com/fdroid/rfp/-/work_items/new" } catch { Info "Abre a mano: https://gitlab.com/fdroid/rfp/-/work_items/new" }
