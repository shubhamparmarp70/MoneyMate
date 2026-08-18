# Auto Git Watcher - Auto-commit and push changes to origin/main
# Place this file in the project root and run to enable automatic commits and pushes.

$RepoPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $RepoPath

# Paths to ignore (simple contains check)
$ignore = @('.git', 'target', '.idea', '.vs')

# Create FileSystemWatcher
$fsw = New-Object System.IO.FileSystemWatcher $RepoPath
$fsw.IncludeSubdirectories = $true
$fsw.Filter = '*.*'
$fsw.EnableRaisingEvents = $true

# Thread-safe queue for changed files
Add-Type -AssemblyName System.Collections
$queue = New-Object System.Collections.Concurrent.ConcurrentQueue[System.String]

function EnqueueChange($path) {
    foreach ($i in $ignore) {
        if ($path -like "*\$i*") { return }
    }
    $queue.Enqueue($path)
}

# Register events
Register-ObjectEvent $fsw 'Changed' -Action { EnqueueChange($Event.SourceEventArgs.FullPath) } | Out-Null
Register-ObjectEvent $fsw 'Created' -Action { EnqueueChange($Event.SourceEventArgs.FullPath) } | Out-Null
Register-ObjectEvent $fsw 'Deleted' -Action { EnqueueChange($Event.SourceEventArgs.FullPath) } | Out-Null
Register-ObjectEvent $fsw 'Renamed' -Action { EnqueueChange($Event.SourceEventArgs.FullPath) } | Out-Null

# Timer to batch events every 3 seconds
$timer = New-Object System.Timers.Timer 3000
$timer.AutoReset = $true
$timer.Enabled = $true

Register-ObjectEvent $timer Elapsed -Action {
    if ($queue.IsEmpty) { return }

    $items = @()
    while ($queue.TryDequeue([ref]$item)) { $items += $item }

    # Only commit if there are git changes
    try {
        Set-Location $RepoPath
        $status = git status --porcelain 2>$null
        if ([string]::IsNullOrWhiteSpace($status)) { return }

        git add -A
        $time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $short = ($items | Get-Unique | Select-Object -First 5) -join ', '
        if ([string]::IsNullOrWhiteSpace($short)) { $short = 'changes' }
        $msg = "Auto commit: $time - $short"

        git commit -m $msg 2>$null | Out-Null
        git push origin main 2>$null
    } catch {
        # swallow errors to keep watcher running
        "Auto-git error: $_" | Out-File -FilePath "$RepoPath\auto_git_watch.log" -Append
    }
} | Out-Null

# Keep the script running
"Auto git watcher started for $RepoPath. Ignoring: $($ignore -join ', ')" | Out-File -FilePath "$RepoPath\auto_git_watch.log" -Append
while ($true) { Start-Sleep -Seconds 5 }
