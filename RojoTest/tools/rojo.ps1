param([ValidateSet('Start','Stop')][string]$Action = 'Start')
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$projectFile = Join-Path $projectRoot 'default.project.json'
$logs = Join-Path $projectRoot '.tools'
$record = Join-Path $logs 'rojo-process.json'
$port = 34872
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$mutex = [Threading.Mutex]::new($false, 'Local\BallRojo34872')
if (-not $mutex.WaitOne(10000)) { throw 'Another ball launcher is busy.' }
try {
    if ($Action -eq 'Stop') {
        if (Test-Path -LiteralPath $record) {
            $saved = Get-Content -LiteralPath $record -Raw | ConvertFrom-Json
            foreach ($identity in $saved.processes) {
                $candidate = Get-Process -Id $identity.id -ErrorAction SilentlyContinue
                if ($candidate -and $candidate.Path -eq $identity.path -and $candidate.StartTime.ToUniversalTime().Ticks.ToString() -eq $identity.ticks) {
                    $info = Get-CimInstance Win32_Process -Filter "ProcessId = $($candidate.Id)"
                    if ($info -and $info.CommandLine -and $info.CommandLine.Contains($projectFile)) { Stop-Process -Id $candidate.Id -Force }
                }
            }
            Remove-Item -LiteralPath $record -Force
        }
        return
    }
    $listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    $wrapper = $null
    if ($listener) {
        $info = Get-CimInstance Win32_Process -Filter "ProcessId = $($listener.OwningProcess)"
        if ($info.Name -ne 'rojo.exe' -or -not $info.CommandLine.Contains($projectFile)) { throw "Port $port belongs to another project. No process was stopped." }
    } else {
        $exe = Join-Path $env:USERPROFILE '.rokit\bin\rojo.exe'
        if (-not (Test-Path -LiteralPath $exe)) { $exe = (Get-Command rojo.exe).Source }
        $arguments = 'serve "' + $projectFile + '" --address 127.0.0.1 --port ' + $port
        $wrapper = Start-Process -FilePath $exe -ArgumentList $arguments -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $logs 'rojo.stdout.log') -RedirectStandardError (Join-Path $logs 'rojo.stderr.log')
        for ($attempt = 0; $attempt -lt 30; $attempt++) {
            Start-Sleep -Milliseconds 200
            $listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($listener) { break }
            if ($wrapper.HasExited) { throw 'Rojo exited. Inspect .tools/rojo.stderr.log.' }
        }
        if (-not $listener) { throw 'Rojo did not open port 34872 within 6 seconds.' }
    }
    $identities = @()
    $serverInfo = Get-CimInstance Win32_Process -Filter "ProcessId = $($listener.OwningProcess)"
    if ($serverInfo.Name -ne 'rojo.exe' -or -not $serverInfo.CommandLine.Contains($projectFile)) { throw 'Unexpected listener identity.' }
    foreach ($processId in @($listener.OwningProcess, $serverInfo.ParentProcessId)) {
        $candidate = Get-Process -Id $processId -ErrorAction SilentlyContinue
        $info = Get-CimInstance Win32_Process -Filter "ProcessId = $processId"
        if ($candidate -and $info.Name -eq 'rojo.exe' -and $info.CommandLine.Contains($projectFile)) {
            $identities += @{ id = $candidate.Id; path = $candidate.Path; ticks = $candidate.StartTime.ToUniversalTime().Ticks.ToString() }
        }
    }
    @{ processes = $identities; port = $port; project = $projectFile } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $record
    $response = Invoke-WebRequest "http://127.0.0.1:$port/" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -ne 200) { throw 'Rojo HTTP verification failed.' }
    Write-Output "Ball Rojo is ready on localhost:$port (PID $($listener.OwningProcess))."
} finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
