# setup-windows.ps1
# Run once to set up local Android dev environment (no Android Studio needed).
# Run as normal user (not Administrator).
#
# Usage:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   .\scripts\setup-windows.ps1

$ErrorActionPreference = "Stop"

function Log($msg) { Write-Host "[setup] $msg" -ForegroundColor Cyan }
function Ok($msg)  { Write-Host "[ok]    $msg" -ForegroundColor Green }
function Warn($msg){ Write-Host "[warn]  $msg" -ForegroundColor Yellow }

# ─── Paths ────────────────────────────────────────────────────────────────────
$ANDROID_HOME = "$env:USERPROFILE\android-sdk"
$CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$CMDLINE_TOOLS_ZIP = "$env:TEMP\cmdline-tools.zip"
$SDK_MANAGER = "$ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat"

# ─── 1. Rust ──────────────────────────────────────────────────────────────────
Log "Installing Rust..."
if (Get-Command rustc -ErrorAction SilentlyContinue) {
    Ok "Rust already installed: $(rustc --version)"
} else {
    winget install --id Rustlang.Rust.MSVC -e --accept-package-agreements --accept-source-agreements
    Ok "Rust installed — restart terminal after this script finishes."
}

# ─── 2. Flutter ───────────────────────────────────────────────────────────────
Log "Installing Flutter..."
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Ok "Flutter already installed: $(flutter --version --machine | ConvertFrom-Json | Select-Object -ExpandProperty frameworkVersion)"
} else {
    winget install --id Google.FlutterSDK -e --accept-package-agreements --accept-source-agreements
    Ok "Flutter installed."
}

# ─── 3. Android cmdline-tools ─────────────────────────────────────────────────
Log "Setting up Android cmdline-tools..."
if (Test-Path $SDK_MANAGER) {
    Ok "sdkmanager already present."
} else {
    New-Item -ItemType Directory -Force -Path "$ANDROID_HOME\cmdline-tools" | Out-Null
    Log "Downloading cmdline-tools (~130 MB)..."
    Invoke-WebRequest -Uri $CMDLINE_TOOLS_URL -OutFile $CMDLINE_TOOLS_ZIP
    Expand-Archive -Path $CMDLINE_TOOLS_ZIP -DestinationPath "$env:TEMP\cmdline-tools-extract" -Force
    Move-Item "$env:TEMP\cmdline-tools-extract\cmdline-tools" "$ANDROID_HOME\cmdline-tools\latest"
    Remove-Item $CMDLINE_TOOLS_ZIP -Force
    Ok "cmdline-tools installed."
}

# ─── 4. Set ANDROID_HOME permanently ──────────────────────────────────────────
Log "Setting ANDROID_HOME env var..."
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $ANDROID_HOME, "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $ANDROID_HOME, "User")

$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$additions = @(
    "$ANDROID_HOME\cmdline-tools\latest\bin",
    "$ANDROID_HOME\platform-tools"
)
foreach ($p in $additions) {
    if ($userPath -notlike "*$p*") {
        $userPath = "$userPath;$p"
    }
}
[System.Environment]::SetEnvironmentVariable("Path", $userPath, "User")
Ok "ANDROID_HOME = $ANDROID_HOME"

# ─── 5. Install Android SDK components ────────────────────────────────────────
Log "Installing Android SDK: platform-tools, SDK 34, build-tools 34, NDK 27..."
# Accept licenses non-interactively
"y`ny`ny`ny`ny`ny`n" | & $SDK_MANAGER --licenses 2>&1 | Out-Null
& $SDK_MANAGER `
    "platform-tools" `
    "platforms;android-34" `
    "build-tools;34.0.0" `
    "ndk;27.0.12077973"
Ok "Android SDK components installed."

# ─── 6. Rust Android targets ──────────────────────────────────────────────────
Log "Adding Rust Android targets..."
rustup target add aarch64-linux-android x86_64-linux-android
Ok "Rust targets added."

# ─── 7. cargo-ndk ─────────────────────────────────────────────────────────────
Log "Installing cargo-ndk..."
if (Get-Command cargo-ndk -ErrorAction SilentlyContinue) {
    Ok "cargo-ndk already installed."
} else {
    cargo install cargo-ndk
    Ok "cargo-ndk installed."
}

# ─── Done ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Setup complete! Next steps:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "1. RESTART your terminal (to pick up new PATH)"
Write-Host ""
Write-Host "2. Connect your Android phone via USB, enable USB Debugging"
Write-Host "   Settings -> Developer options -> USB Debugging"
Write-Host ""
Write-Host "3. Run:"
Write-Host "   cd core"  -ForegroundColor Yellow
Write-Host "   cargo test" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. Build + run on your phone:"
Write-Host "   cargo ndk -t arm64-v8a -o ..\app\android\app\src\main\jniLibs build --release" -ForegroundColor Yellow
Write-Host "   cd ..\app && flutter run" -ForegroundColor Yellow
Write-Host ""
