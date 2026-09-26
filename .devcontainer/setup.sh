#!/usr/bin/env bash
# .devcontainer/setup.sh
# One-shot post-create setup: Flutter SDK, Android SDK + NDK, Rust Android targets, cargo-ndk.
# Runs as the 'vscode' user (non-root). Safe to re-run — every step checks before acting.
set -euo pipefail

ANDROID_HOME="${ANDROID_HOME:-/home/vscode/android-sdk}"
FLUTTER_HOME="${FLUTTER_ROOT:-/home/vscode/flutter}"

# ─── Helpers ─────────────────────────────────────────────────────────────────
log() { echo -e "\033[1;36m[setup]\033[0m $*"; }

# ─── 1. Flutter SDK ───────────────────────────────────────────────────────────
log "Flutter SDK..."
if [ ! -d "$FLUTTER_HOME/.git" ]; then
  git clone --depth 1 --branch stable \
    https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --version --machine > /dev/null   # triggers dart/engine download
flutter config --no-analytics --no-cli-animations
flutter precache --android                # pre-download Android artifacts

# ─── 2. Android command-line tools ────────────────────────────────────────────
log "Android cmdline-tools..."
CMDLINE_TOOLS_ZIP="/tmp/cmdline-tools.zip"
# Version 11076708 = cmdline-tools 11.0 (latest stable as of 2025-Q1).
# Update this URL when a newer version is available.
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

if [ ! -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  curl -sSL "$CMDLINE_TOOLS_URL" -o "$CMDLINE_TOOLS_ZIP"
  unzip -q "$CMDLINE_TOOLS_ZIP" -d /tmp/cmdline-tools-extract
  mv /tmp/cmdline-tools-extract/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
  rm -rf "$CMDLINE_TOOLS_ZIP" /tmp/cmdline-tools-extract
fi
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# ─── 3. Android SDK components ────────────────────────────────────────────────
log "Android SDK: platform-tools, SDK 34, build-tools 34, NDK 27..."
# Accept all licenses non-interactively.
yes | sdkmanager --licenses > /dev/null 2>&1 || true
sdkmanager --install \
  "platform-tools" \
  "platforms;android-34" \
  "build-tools;34.0.0" \
  "ndk;27.0.12077973"

# ─── 4. Rust Android targets ──────────────────────────────────────────────────
log "Rust targets: aarch64-linux-android x86_64-linux-android..."
rustup target add aarch64-linux-android x86_64-linux-android

# ─── 5. cargo-ndk ─────────────────────────────────────────────────────────────
log "cargo-ndk..."
if ! command -v cargo-ndk &> /dev/null; then
  cargo install cargo-ndk
fi

# ─── 6. Persist PATH in .bashrc ───────────────────────────────────────────────
PROFILE_BLOCK='
# vn-address-widget devcontainer PATH (added by setup.sh)
export ANDROID_HOME="/home/vscode/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export FLUTTER_ROOT="/home/vscode/flutter"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$FLUTTER_ROOT/bin:$PATH"
'
if ! grep -q "vn-address-widget devcontainer PATH" ~/.bashrc 2>/dev/null; then
  echo "$PROFILE_BLOCK" >> ~/.bashrc
fi

# ─── 7. Verify ────────────────────────────────────────────────────────────────
log "Verifying installs..."
flutter --version
rustc --version
cargo ndk --version
sdkmanager --list_installed | grep -E "ndk|build-tools|platforms;android"

log "Setup complete ✓ — open a new terminal to pick up PATH changes."
