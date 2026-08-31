# repository-backup-tool

A tool to back up repos to a thumb drive on the click of a button.

## Usage

1. Double-click `Run Repository Backup Tool.vbs` (or run `RepositoryBackupTool.ps1` directly in PowerShell).
2. Click **Browse...** to select your local source folder.
3. Click **Browse...** to select the destination folder on the thumb drive.
4. Once both are selected, **Clone Repos to Thumb Drive** becomes enabled. Click it to mirror the source folder to the destination.

The backup mirrors the source folder exactly (via `robocopy /MIR`), so files removed from the source will also be removed from the destination. `node_modules`, `.venv`, `venv`, `__pycache__`, `dist`, and `build` folders are skipped.

No installation required — just PowerShell, which ships with Windows.
