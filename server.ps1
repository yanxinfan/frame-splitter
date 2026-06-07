$folder = "C:\Users\tangjunjie\.deepseekgui\default_workspace\frame-splitter"
$port = 8765
$crlf = "`r`n"
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
$listener.Start()
Write-Host "========================================"
Write-Host "  帧动画拆帧工具"
Write-Host "  http://localhost:$port"
Write-Host "========================================"

while ($true) {
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()
    $reader = [System.IO.StreamReader]::new($stream)
    $line = $reader.ReadLine()
    
    if ($line -match 'GET /(\S*)') {
        $path = [Uri]::UnescapeDataString($Matches[1])
        if ($path -eq '' -or $path -eq 'index.html') { $path = 'index.html' }
        $fullPath = Join-Path $folder $path
        if (Test-Path $fullPath) {
            $bytes = [IO.File]::ReadAllBytes($fullPath)
            $ext = [IO.Path]::GetExtension($fullPath)
            $ct = if ($ext -eq '.html') { "text/html; charset=utf-8" }
                  elseif ($ext -eq '.js')  { "application/javascript" }
                  elseif ($ext -eq '.css') { "text/css" }
                  elseif ($ext -eq '.png') { "image/png" }
                  elseif ($ext -eq '.wasm') { "application/wasm" }
                  else { "application/octet-stream" }
            $resp = "HTTP/1.1 200 OK" + $crlf +
                    "Content-Type: $ct" + $crlf +
                    "Content-Length: $($bytes.Length)" + $crlf +
                    "Access-Control-Allow-Origin: *" + $crlf +
                    $crlf
            $respBytes = [System.Text.Encoding]::UTF8.GetBytes($resp)
            $stream.Write($respBytes, 0, $respBytes.Length)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush()
        } else {
            $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
            $resp = "HTTP/1.1 404 Not Found" + $crlf +
                    "Content-Type: text/plain" + $crlf +
                    "Content-Length: $($body.Length)" + $crlf + $crlf
            $respBytes = [System.Text.Encoding]::UTF8.GetBytes($resp)
            $stream.Write($respBytes, 0, $respBytes.Length)
            $stream.Write($body, 0, $body.Length)
            $stream.Flush()
        }
    }
    $stream.Close()
    $client.Close()
}
