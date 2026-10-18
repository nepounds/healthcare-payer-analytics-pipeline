# Healthcare Payer Analytics Pipeline - local Python bootstrap
# Run from the repository root in PowerShell.

if (-not (Test-Path ".venv")) {
    py -m venv .venv
}

Write-Host ""
Write-Host "Virtual environment is ready."
Write-Host ""
Write-Host "Next commands:"
Write-Host "  .\.venv\Scripts\Activate.ps1"
Write-Host "  python -m pip install --upgrade pip"
Write-Host "  pip install -r requirements.txt"
Write-Host ""
Write-Host "Then copy .env.example to .env and confirm local SQL Server values."
