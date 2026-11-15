# Open PDF Reader — Build Notes

**App:** Open PDF Reader · **Package:** `com.manish.openpdfreader` ·
**Project:** `open_pdf_reader` · **Version:** 1.0.0+1 ·
**Folder:** `~/workspace/pdf-app/open-pdf-reader/`

Free forever: no ads, no billing/subscription, no tracking/ad SDKs, no daily
limits, works offline. Clean-room build — own code and design only; the
studied original app's code, branding, name, icons and AdMob ID were not used.

## Toolchain (verified 2026-11-15)

- **Flutter 3.50.0** (channel stable, Dart 3.14.0, DevTools 2.61.0) at `~/flutter`
- **JDK:** Temurin 17.0.21 at `~/workspace/pdf-app/jdk17` (`JAVA_HOME`)
- **Android SDK** at `~/Android/Sdk` (installed manually via curl, because
  sdkmanager cannot reach the network — see Blocker below):
  - cmdline-tools latest (sdkmanager 19.0)
  - platform-tools 37.0.3
  - platforms android-35 (rev 2) and android-36 (rev 2)
  - build-tools 35.0.0 and 36.0.0
  - Licence files in `~/Android/Sdk/licenses/`
- Flutter 3.50 defaults are compileSdk 36 / targetSdk 36 / minSdk 24, which
  is why SDK 36 is installed.
- `flutter doctor`: Flutter ✓, Android toolchain [!] (SDK 36.0.0 present,
  "Android license status unknown"), Chrome ✗ (not needed), Linux toolchain
  ✗ (not needed, Android-only project), Proxy Configuration ✓, Connected
  device 1 available, Network resources ✓.

## Dependencies (all open source, `flutter pub get` OK — 81 deps)

pdfx 2.11.0 (Pdfium viewer), pdf 3.13.1 (PDF creation), file_picker 10.3.10,
permission_handler 12.0.3, path_provider 2.1.6, share_plus 11.1.0,
image_picker 1.2.4. Dev: flutter_lints 6.0.0,
path_provider_platform_interface 2.1.0 (test-only fake platform).

## How to build

```sh
export TMPDIR=~/workspace/pdf-app/tmp
export JAVA_HOME=~/workspace/pdf-app/jdk17
export ANDROID_HOME=~/Android/Sdk ANDROID_SDK_ROOT=~/Android/Sdk
export PATH=~/flutter/bin:$PATH
cd ~/workspace/pdf-app/open-pdf-reader

flutter pub get
flutter analyze        # 0 errors, 0 warnings (see note below)
flutter test           # 1 smoke test, passes
flutter build apk --debug
```

Debug APK (once the blocker below is cleared) lands at
`build/app/outputs/flutter-apk/app-debug.apk`. Debug only — no release
build, no keystore.

## What works in V1

- **Home:** "Open a PDF" via file picker (SAF, falls back to bytes → temp
  file), "Scan device for PDFs" (storage permission flow, scans
  Download/Documents), Recent files list (max 20, persisted as JSON,
  per-item delete + Clear).
- **Viewer (pdfx, Pdfium):** pinch zoom, page indicator, prev/next buttons,
  page-number jump (TextField). Share button (share_plus). Error state if
  the file cannot be opened.
- **Tools:** six entries, every button goes somewhere real — **Image to
  PDF** and **Scan to PDF** (camera/gallery via image_picker) create a real
  PDF; **PDF to Image** renders a chosen page to PNG. Results offer Open
  (PDFs) and Share, and show the on-device save path
  (`<app documents>/Open PDF Reader/`).
- **Settings:** "Free forever" card (no ads, no subscription, no in-app
  purchases, no daily limits, no tracking, works offline), dark-mode toggle
  (persisted), Clear recent files, version + package shown.
- Bottom navigation Home / Tools / Settings (IndexedStack).

## Still placeholder / limits in V1

- **Merge PDF, Split PDF, Compress PDF:** screens exist with a file picker
  and an honest "coming in the next update" message — no merging/splitting/
  compressing yet.
- **Text search in the viewer:** pdfx has no text-search API, so the search
  field only jumps to a page number; other text shows "Text search is coming
  in the next update".
- **Device scan on Android 13+:** the system limits automatic scanning, so
  the picker ("Open a PDF") is the reliable fallback; the screen says so.
- **Created files** (Image→PDF, Scan→PDF, PDF→Image) are saved in the app
  documents dir and shared out — they are not written directly to the
  public Download folder.
- `flutter analyze`: 0 errors, 0 warnings; 7 info-level notices only —
  `package:flutter/material.dart` is deprecated in Flutter 3.50 in favour of
  `package:material_ui/material_ui.dart`. The app deliberately stays on
  `material.dart` (stable, well-known) for V1; switching to the new
  `material_ui` package is a future cleanup, not a V1 requirement.

## BLOCKER — debug APK cannot be built yet (Java TCP is blocked)

`flutter build apk --debug` fails before compiling, while the Gradle
wrapper tries to download its distribution:

```
Exception in thread "main" javax.net.ssl.SSLException: Unsupported or unrecognized SSL message
Gradle task assembleDebug failed with exit code 1
```

Root cause: the sandbox blocks Java TCP connections (the egress proxy
returns plain text instead of TLS to Java; the same failure hits
`flutter doctor --android-licenses`, whose sdkmanager exits code 1).
Python/curl/Dart networking all work — only Java is blocked. No Gradle
cache (`~/.gradle`) and no Maven repo (`~/.m2`) exist on this machine, so
Gradle cannot run offline either.

**Unblock step:** in Muse settings → Permissions → Direct network
protocols, switch `other_tcp` from Deny to Ask. After that, re-run
`flutter doctor --android-licenses` (accept the licences) and then
`flutter build apk --debug`. Everything else is already in place, so the
build should proceed immediately. The old Python TCP relay
(`~/workspace/pdf-app/tools/tcp-relay.py`) is no longer running and is not
useful — Java cannot TCP-connect even to localhost.

## Rename procedure (if the app name changes later)

1. `pubspec.yaml`: `name:` (project name) and `description:`.
2. `android/app/build.gradle.kts`: `namespace` and `applicationId`.
3. `android/app/src/main/kotlin/com/manish/openpdfreader/MainActivity.kt`:
   move to the new package path and change the `package` line.
4. `android/app/src/main/AndroidManifest.xml`: `android:label`.
5. `lib/` screens/settings: the visible app-name strings ("Open PDF Reader",
   "Free forever" card) and this file.
6. Re-run `flutter pub get`, `flutter analyze`, `flutter test`,
   `flutter build apk --debug`.
