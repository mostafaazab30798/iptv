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
```bash
adb connect <tv-ip-address>:5555
flutter run -d <tv-device-id>
```
*Tip: Test navigation using the TV D-pad or keyboard arrow keys.*

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
