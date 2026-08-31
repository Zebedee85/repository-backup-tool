# repository-backup-tool

A tool to back up repos to a thumb drive on the click of a button.

Windows only (uses PowerShell and `robocopy`, both built into Windows). No installation required.

## Usage

1. Double-click `Run Repository Backup Tool.vbs` (or run `RepositoryBackupTool.ps1` directly in PowerShell).
2. Click **Browse...** to select your local source folder.
3. Click **Browse...** to select the destination folder on the thumb drive.
4. Once both are selected, **Backup to Thumb Drive** becomes enabled. Click it to mirror the source folder to the destination.

## ⚠️ This is a one-way mirror, not a merge

The backup mirrors the source folder exactly (via `robocopy /MIR`): the destination ends up byte-for-byte identical to the source. **Any file in the destination folder that doesn't also exist in the source will be deleted.** Don't point the destination at a folder containing files you want to keep that aren't also in the source. `node_modules`, `.venv`, `venv`, `__pycache__`, `dist`, and `build` folders are skipped on both sides.

## About the launcher

`Run Repository Backup Tool.vbs` starts `RepositoryBackupTool.ps1` with `powershell.exe -ExecutionPolicy Bypass`. This only relaxes the execution policy for that one process — it does not change any system-wide PowerShell setting — and is the standard way to let a script run without requiring users to first change their machine's script-execution policy.
