# Flutter clean helper for Windows
# Save as: clean_flutter.ps1

$projectPath = "C:\Users\kcsva\OneDrive\Desktop\CS Elective2\Vallespin-CS-Elective-2"

if (-not (Test-Path $projectPath)) {
    Write-Error "Project folder not found: $projectPath"
    exit 1
}

Set-Location $projectPath

Write-Host "Stopping common Flutter-related processes..."
Get-Process dart, flutter, adb, Code, msedge -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Removing stale build artifacts..."
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ios\Flutter\ephemeral -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force linux\flutter\ephemeral -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force macos\Flutter\ephemeral -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force windows\flutter\ephemeral -ErrorAction SilentlyContinue

Write-Host "Running flutter clean..."
flutter clean

Write-Host "Running flutter pub get..."
flutter pub get

Write-Host "Done. You can now run: flutter run"
