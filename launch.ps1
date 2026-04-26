# launch.ps1
# MineSim — Servidor local y lanzador
# Ejecutar: Right-click → "Run with PowerShell"
# O desde terminal: powershell -ExecutionPolicy Bypass -File launch.ps1

$port = 8765
$root = $PSScriptRoot
$url  = "http://localhost:$port/minesim.html"

# Verificar si el puerto ya está ocupado
$inUse = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
if ($inUse) {
    Write-Host "Puerto $port ya en uso. Abriendo browser directamente..." -ForegroundColor Yellow
    Start-Process $url
    exit
}

Write-Host ""
Write-Host "  MineSim - Servidor local" -ForegroundColor Cyan
Write-Host "  Raiz : $root" -ForegroundColor Gray
Write-Host "  URL  : $url" -ForegroundColor Green
Write-Host "  Ctrl+C para detener" -ForegroundColor Gray
Write-Host ""

# Crear listener HTTP simple en PowerShell
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

# Abrir browser despues de un momento
Start-Sleep -Milliseconds 400
Start-Process $url

# Tabla de MIME types
$mime = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript"
    ".css"  = "text/css"
    ".json" = "application/json"
    ".stl"  = "application/octet-stream"
    ".png"  = "image/png"
    ".ico"  = "image/x-icon"
    ".svg"  = "image/svg+xml"
}

Write-Host "Servidor activo. Esperando peticiones..." -ForegroundColor Green

while ($listener.IsListening) {
    try {
        $ctx  = $listener.GetContext()
        $req  = $ctx.Request
        $resp = $ctx.Response

        # Resolver ruta local
        $urlPath  = $req.Url.LocalPath.TrimStart('/')
        $filePath = Join-Path $root $urlPath

        if (Test-Path $filePath -PathType Leaf) {
            $ext         = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
            $bytes       = [System.IO.File]::ReadAllBytes($filePath)

            $resp.ContentType   = $contentType
            $resp.ContentLength64 = $bytes.Length
            $resp.AddHeader("Access-Control-Allow-Origin", "*")
            $resp.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $resp.StatusCode = 404
            $body = [System.Text.Encoding]::UTF8.GetBytes("404 - Not found: $urlPath")
            $resp.OutputStream.Write($body, 0, $body.Length)
        }

        $resp.OutputStream.Close()
        Write-Host "  $($req.HttpMethod) $($req.Url.LocalPath)" -ForegroundColor DarkGray
    }
    catch [System.Net.HttpListenerException] {
        break
    }
    catch {
        Write-Host "  Error: $_" -ForegroundColor Red
    }
}

$listener.Stop()
Write-Host "Servidor detenido." -ForegroundColor Yellow
