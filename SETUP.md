# IPTV Flutter App — Setup & Run Guide

This guide describes how to run and verify the IPTV Flutter application across supported platforms.

---

## Prerequisites

- **Flutter SDK**: 3.10+ / Dart SDK 3.10+
- **Platform Toolchains**:
  - **Android / Android TV**: Android SDK, NDK, and Android Studio / Emulator.
  - **Windows**: Visual Studio 2022 (C++ desktop development workload).
  - **Web**: Google Chrome or Edge.

---

## Initial Setup

1. Clone or open the project root:
   ```bash
   cd d:\PROJECTS\iptv
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Generate localization and database code:
   ```bash
   flutter gen-l10n
   dart run build_runner build --delete-conflicting-outputs
   ```

---

## Running on Target Platforms

### Debug authentication preview

Flutter debug builds use a local email/OTP walkthrough by default. No Supabase
request or email is sent: enter any valid email address, then any six digits.
Release and profile builds always use the real backend.

To exercise the real backend from a debug build, disable the preview explicitly:

```bash
flutter run -d <device-id> --dart-define=DEBUG_AUTH_PREVIEW=false
```

For a local build connected to the production update service, use the ignored
`.env.local` owner configuration:

```powershell
.\scripts\run_configured.ps1 -DeviceId <device-id>
```

In VS Code, select **HOPE TV (configured)** from Run and Debug. Dart defines are
compiled into the application, so hot reload cannot configure an already-built
binary; stop and rebuild after changing `.env.local`.

### 1. Windows (Desktop)
```bash
flutter run -d windows
```

### 2. Android Phone / Tablet (Landscape)
```bash
flutter run -d <android-device-id>
```
*Note: The app will automatically lock to landscape orientation.*

### 3. Android TV / Google TV
Ensure your Android TV device is connected via ADB over Wi-Fi or USB:

**A. Run from command line or scripts:**
```bash
# Connect over Wi-Fi
adb connect <tv-ip-address>:5555

# Run directly on TV
flutter run -d <tv-device-id> --dart-define-from-file=.env.local
```

**B. Build dedicated TV APK:**
```powershell
# Standard TV APK (same package ID)
.\scripts\android\build_tv_apk.ps1

# Dedicated TV package ID (com.hopetv.iptvplayer.tv) for side-by-side installs
.\scripts\android\build_tv_apk.ps1 -SeparatePackageId

# Install directly to your connected TV:
.\scripts\android\install_tv.ps1 -DeviceIp <tv-ip-address>
```

**C. VS Code:**
Select **HOPE TV Android TV (configured)** or **HOPE TV Android TV (Focus Inspector)** from the Run & Debug menu.

*Tip: Test navigation using the TV remote D-pad (directional arrows, OK, and Back).*

### 4. Web
```bash
flutter run -d chrome
```

### Production domain, email, and Supabase

For the `hope-tv.site` Cloudflare routes, Resend sender authentication,
Supabase Auth URLs, SMTP fields, and the launch verification checklist, see
[`docs/commercial/DOMAIN_EMAIL_SUPABASE_SETUP.md`](docs/commercial/DOMAIN_EMAIL_SUPABASE_SETUP.md).

Separate operational guides:

- Owner actions: [`docs/commercial/OWNER_DOMAIN_EMAIL_BACKEND_RUNBOOK.md`](docs/commercial/OWNER_DOMAIN_EMAIL_BACKEND_RUNBOOK.md)
- LLM/code-agent instructions: [`docs/commercial/LLM_AGENT_DOMAIN_EMAIL_BACKEND_INSTRUCTIONS.md`](docs/commercial/LLM_AGENT_DOMAIN_EMAIL_BACKEND_INSTRUCTIONS.md)
- Lovable public website prompt: [`docs/commercial/LOVABLE_PUBLIC_WEBSITE_MASTER_PROMPT.md`](docs/commercial/LOVABLE_PUBLIC_WEBSITE_MASTER_PROMPT.md)

---

## Code Quality & Verification

Run static analysis and test suite:
```bash
flutter analyze
flutter test
```
