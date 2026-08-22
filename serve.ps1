$port = 8080
$prefix = "http://localhost:$port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Local server running at $prefix"

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $rawUrl = $request.Url.LocalPath
        if ($rawUrl -eq "/" -or [string]::IsNullOrWhiteSpace($rawUrl)) { 
            $rawUrl = "/index.html" 
        }
        
        $localPath = [System.Uri]::UnescapeDataString($rawUrl).TrimStart('/').Replace('/', '\')
        $fullPath = Join-Path (Get-Location) $localPath
        
        if (Test-Path $fullPath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($fullPath)
            $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
            switch ($ext) {
                ".html" { $contentType = "text/html; charset=utf-8" }
                ".css"  { $contentType = "text/css" }
                ".js"   { $contentType = "text/javascript" }
                ".jpeg" { $contentType = "image/jpeg" }
                ".jpg"  { $contentType = "image/jpeg" }
                ".png"  { $contentType = "image/png" }
                ".svg"  { $contentType = "image/svg+xml" }
                default { $contentType = "application/octet-stream" }
            }
            $response.ContentType = $contentType
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.OutputStream.Write($msg, 0, $msg.Length)
        }
        $response.OutputStream.Close()
    } catch {
        # Keep server listening loop active
    }
}
