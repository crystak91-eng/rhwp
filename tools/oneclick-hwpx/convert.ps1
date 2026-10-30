$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcRoot = Join-Path $root 'input'
$outRoot = Join-Path $root 'output'
$reviewRoot = Join-Path $root 'needs_review'
$logRoot = Join-Path $root 'logs'
foreach ($dir in @($srcRoot, $outRoot, $reviewRoot, $logRoot)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
$exe = Join-Path $root 'rhwp.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    Write-Host 'ERROR: rhwp.exe was not found next to RUN_CONVERT.bat.' -ForegroundColor Red
    exit 2
}
try {
    & $exe --version
    if ($LASTEXITCODE -ne 0) { throw 'rhwp.exe could not start.' }
} catch {
    Write-Host "ERROR: Cannot run rhwp.exe: $_" -ForegroundColor Red
    exit 2
}
$files = @(Get-ChildItem -LiteralPath $srcRoot -File -Recurse | Where-Object { $_.Extension -ieq '.hwp' } | Sort-Object FullName)
if ($files.Count -eq 0) {
    Write-Host 'No HWP files found in input.' -ForegroundColor Yellow
    exit 0
}
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$csv = Join-Path $logRoot "conversion_$stamp.csv"
$detail = Join-Path $logRoot "details_$stamp.txt"
$records = New-Object System.Collections.Generic.List[object]
$ok = 0; $fail = 0; $skip = 0
$i = 0
foreach ($f in $files) {
    $i++
    $relative = $f.FullName.Substring($srcRoot.Length).TrimStart([char]'\')
    $relativeDir = Split-Path $relative -Parent
    $base = [IO.Path]::GetFileNameWithoutExtension($relative)
    $targetDir = if ($relativeDir) { Join-Path $outRoot $relativeDir } else { $outRoot }
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    $target = Join-Path $targetDir ($base + '.hwpx')
    $status = 'FAILED'; $code = ''; $message = ''
    Write-Host "[$i/$($files.Count)] $relative"
    if (Test-Path -LiteralPath $target) {
        $status = 'SKIPPED'; $skip++
        $message = 'Output already exists; no overwrite'
    } else {
        $temporary = Join-Path $targetDir ($base + '.' + [guid]::NewGuid().ToString('N') + '.tmp.hwpx')
        try {
            $result = & $exe export-hwpx $f.FullName $temporary --verify --verify-pages 2>&1
            $code = $LASTEXITCODE
            $message = ($result | Out-String).Trim()
            if ($message) {
                Add-Content -LiteralPath $detail -Value ("=== $relative / exit $code ===" + [Environment]::NewLine + $message) -Encoding UTF8
            }
            if ($code -eq 0 -and (Test-Path -LiteralPath $temporary -PathType Leaf) -and (Get-Item -LiteralPath $temporary).Length -gt 0) {
                Move-Item -LiteralPath $temporary -Destination $target -ErrorAction Stop
                $status = 'OK'; $ok++
                Write-Host '  OK' -ForegroundColor Green
            } else {
                throw "CLI exit=$code or output missing/empty"
            }
        } catch {
            $fail++
            if (-not $message) { $message = [string]$_ } else { $message += ' | ' + [string]$_ }
            Write-Host "  FAILED: $message" -ForegroundColor Red
            if (Test-Path -LiteralPath $temporary) {
                $reviewDir = if ($relativeDir) { Join-Path $reviewRoot $relativeDir } else { $reviewRoot }
                New-Item -ItemType Directory -Path $reviewDir -Force | Out-Null
                $reviewFile = Join-Path $reviewDir ($base + '.' + [guid]::NewGuid().ToString('N') + '.hwpx')
                Move-Item -LiteralPath $temporary -Destination $reviewFile
                $message += ' | Unverified output: ' + $reviewFile
            }
        }
    }
    $records.Add([pscustomobject]@{Input=$f.FullName;Output=$target;Status=$status;ExitCode=$code;Message=$message})
}
$records | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
Write-Host "Complete: OK=$ok, Failed=$fail, Skipped=$skip"
Write-Host "CSV log: $csv"
if ($fail -gt 0) { exit 1 }
