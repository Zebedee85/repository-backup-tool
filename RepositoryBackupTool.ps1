Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ExcludeDirs = @("node_modules", ".venv", "venv", "__pycache__", "dist", "build")
$LogFile     = Join-Path $env:TEMP "repository-backup-tool-log.txt"

$form = New-Object System.Windows.Forms.Form
$form.Text = "Repository Backup Tool"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# --- Source folder row ---
$lblSource = New-Object System.Windows.Forms.Label
$lblSource.Text = "Local source folder:"
$lblSource.Location = New-Object System.Drawing.Point(15, 15)
$lblSource.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($lblSource)

$txtSource = New-Object System.Windows.Forms.TextBox
$txtSource.ReadOnly = $true
$txtSource.Location = New-Object System.Drawing.Point(15, 38)
$txtSource.Size = New-Object System.Drawing.Size(440, 24)
$form.Controls.Add($txtSource)

$btnBrowseSource = New-Object System.Windows.Forms.Button
$btnBrowseSource.Text = "Browse..."
$btnBrowseSource.Location = New-Object System.Drawing.Point(465, 37)
$btnBrowseSource.Size = New-Object System.Drawing.Size(105, 26)
$form.Controls.Add($btnBrowseSource)

# --- Destination folder row ---
$lblDest = New-Object System.Windows.Forms.Label
$lblDest.Text = "Thumb drive destination folder:"
$lblDest.Location = New-Object System.Drawing.Point(15, 75)
$lblDest.Size = New-Object System.Drawing.Size(300, 20)
$form.Controls.Add($lblDest)

$txtDest = New-Object System.Windows.Forms.TextBox
$txtDest.ReadOnly = $true
$txtDest.Location = New-Object System.Drawing.Point(15, 98)
$txtDest.Size = New-Object System.Drawing.Size(440, 24)
$form.Controls.Add($txtDest)

$btnBrowseDest = New-Object System.Windows.Forms.Button
$btnBrowseDest.Text = "Browse..."
$btnBrowseDest.Location = New-Object System.Drawing.Point(465, 97)
$btnBrowseDest.Size = New-Object System.Drawing.Size(105, 26)
$form.Controls.Add($btnBrowseDest)

# --- Action buttons ---
$btnSync = New-Object System.Windows.Forms.Button
$btnSync.Text = "Backup to Thumb Drive"
$btnSync.Location = New-Object System.Drawing.Point(15, 140)
$btnSync.Size = New-Object System.Drawing.Size(440, 40)
$btnSync.Font = New-Object System.Drawing.Font($btnSync.Font, [System.Drawing.FontStyle]::Bold)
$btnSync.Enabled = $false
$form.Controls.Add($btnSync)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "Close"
$btnClose.Location = New-Object System.Drawing.Point(465, 140)
$btnClose.Size = New-Object System.Drawing.Size(105, 40)
$form.Controls.Add($btnClose)

# --- Status + log ---
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Select a source folder and a destination folder to continue."
$lblStatus.Location = New-Object System.Drawing.Point(15, 190)
$lblStatus.Size = New-Object System.Drawing.Size(555, 20)
$form.Controls.Add($lblStatus)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.Location = New-Object System.Drawing.Point(15, 215)
$txtLog.Size = New-Object System.Drawing.Size(555, 225)
$form.Controls.Add($txtLog)

function Update-SyncButtonState {
    $btnSync.Enabled = (-not [string]::IsNullOrWhiteSpace($txtSource.Text)) -and
                        (-not [string]::IsNullOrWhiteSpace($txtDest.Text)) -and
                        (Test-Path -LiteralPath $txtSource.Text) -and
                        (Test-Path -LiteralPath $txtDest.Text)
}

$btnBrowseSource.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select the local source folder"
    if ($txtSource.Text) { $dlg.SelectedPath = $txtSource.Text }
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtSource.Text = $dlg.SelectedPath
        Update-SyncButtonState
    }
})

$btnBrowseDest.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select the destination folder on the thumb drive"
    if ($txtDest.Text) { $dlg.SelectedPath = $txtDest.Text }
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtDest.Text = $dlg.SelectedPath
        Update-SyncButtonState
    }
})

$btnSync.Add_Click({
    $sourceDir = $txtSource.Text
    $destDir   = $txtDest.Text

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "This will mirror:`n$sourceDir`n`nto:`n$destDir`n`nAny files in the destination that no longer exist in the source will be DELETED.`n`nContinue?",
        "Confirm Backup",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $btnSync.Enabled = $false
    $btnBrowseSource.Enabled = $false
    $btnBrowseDest.Enabled = $false
    $txtLog.Clear()
    $lblStatus.Text = "Syncing to $destDir ..."
    [System.Windows.Forms.Application]::DoEvents()

    $arguments = @("`"$sourceDir`"", "`"$destDir`"", "/MIR", "/XD") + $ExcludeDirs + @("/R:2", "/W:2", "/NFL", "/NDL", "/NP", "/LOG:`"$LogFile`"")

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "robocopy.exe"
    $psi.Arguments = [string]::Join(" ", $arguments)
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($psi)
    $start = Get-Date
    while (-not $proc.HasExited) {
        Start-Sleep -Milliseconds 200
        $lblStatus.Text = "Syncing to $destDir ... ({0:0}s)" -f ((Get-Date) - $start).TotalSeconds
        [System.Windows.Forms.Application]::DoEvents()
    }

    if (Test-Path $LogFile) {
        $txtLog.Text = (Get-Content $LogFile -Raw)
        $txtLog.SelectionStart = $txtLog.Text.Length
        $txtLog.ScrollToCaret()
    }

    if ($proc.ExitCode -lt 8) {
        $lblStatus.Text = "Backup complete (exit code $($proc.ExitCode))."
    } else {
        $lblStatus.Text = "Backup FAILED (exit code $($proc.ExitCode)) - see log below."
    }

    $btnSync.Enabled = $true
    $btnBrowseSource.Enabled = $true
    $btnBrowseDest.Enabled = $true
    Update-SyncButtonState
})

$btnClose.Add_Click({
    $form.Close()
})

[void]$form.ShowDialog()
$form.Dispose()
