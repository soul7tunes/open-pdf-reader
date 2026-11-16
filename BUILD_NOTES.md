# Open PDF Reader — Build Notes

**App:** Open PDF Reader · **Package:** `com.manish.openpdfreader` ·
**Project:** `open_pdf_reader` · **Version:** 1.2.0+3 (V2.1) ·
**Folder:** `~/workspace/pdf-app/open-pdf-reader/`

Free forever: no ads, no billing/subscription, no tracking/ad SDKs, no daily
limits, works offline. Clean-room build — own code and design only; the
studied original app's code, branding, name, icons and AdMob ID were not used.

## V2.1 — 1.2.0+3 (2026-11-16, user bug report + wording request)

Six problems from the user's phone screenshots, plus one wording change.
All fixed in this version; `flutter analyze --no-fatal-infos` 0 errors /
0 warnings, `flutter test` 7/7 pass (incl. new light-mode background test
and createTextPdf/clampPage/rotation unit tests).

1. **Page number wrong (viewer showed 10 on page 1).** Root cause:
   `PdfViewPinch` computes its page as the largest visible page area
   during layout, so it could report a stale page before the user scrolled;
   `PdfControllerPinch.jumpToPage` also adds 1 (off by one); and the page
   field only showed the value as `hintText`, so a stale value stuck.
   Fix: viewer now uses pdfx `PdfView` + `PdfController` (PageView-based —
   page is a single source of truth from the centred page, `jumpToPage`
   is correctly 1-based). `onPageChanged` is the one place the indicator
   changes; `onDocumentLoaded` resets to page 1; the field holds the real
   number as text (synced unless the user is typing in it).
   Verified: unit tests for `clampPage`/`nextQuarterTurns`; on-phone check
   still needed (open 16-page PDF → 1; jump to 10 → 10; back to top → 1).
2. **Text overlap on Tools screen.** Root cause: grid
   `childAspectRatio: 0.88` made cards too short for icon + title +
   description + "Ready" badge; `GlassCard` does not clip, so text spilled
   over the border and the badge overlapped the next row. Fix: fixed
   `mainAxisExtent: 252` cells, title/description capped at 2 lines with
   ellipsis, description 13pt, badge inside the card flow. Home
   quick-tools grid got the same treatment (`mainAxisExtent: 124`,
   short titles max 2 lines). Verified: no overflow at the app's font
   sizes by construction (fixed cell height + capped lines); on-phone
   check still needed.
3. **Dark stayed on in light mode (Scan to PDF screen black).** Root
   cause: `ToolDetailScreen` used `Scaffold(backgroundColor:
   Colors.transparent)` on an opaque `MaterialPageRoute`, which paints
   black; it also had no `GlassBackground` wrapper (tabs have one in
   `MainTabs`, pushed routes do not). Fix: explicit theme background
   (`isDark ? darkBg : lightBg`) + `GlassBackground` body. Audit: the
   only other pushed screen is `PdfViewerScreen`, which already had an
   explicit background; tabs are inside `MainTabs`' `GlassBackground`.
   Verified: new widget test pumps `ToolDetailScreen` in light mode and
   asserts `Scaffold.backgroundColor == AppColors.lightBg` (and dark mode
   asserts `darkBg`).
4. **Device PDFs did not show automatically.** Root cause: Home only
   scanned on "Scan device" tap and only Download/Documents. Fix: scan
   runs automatically after Home's first frame, roots expanded to
   Download, Documents, DCIM, Pictures, WhatsApp + Telegram document
   folders and the app's own documents dir (where created PDFs are
   saved); newest first, capped at 100, deduped; "On this device (N)"
   section with count; manual Scan button + pull-to-refresh kept. Honest
   note kept: Android 13+ restricts some folders, picker is the fallback.
5. **Rotate.** New: rotate button in the viewer AppBar and bottom glass
   bar; each tap cycles 0/90/180/270 via `RotatedBox` around the `PdfView`.
   Approach stated in code (`nextQuarterTurns`, unit-tested).
6. **Create PDF (new, 7th tool).** New `PdfTool.create` (title + body
   fields, A4/Letter, Small/Medium/Large text) in `ToolDetailScreen`;
   `createTextPdf` in `pdf_tools.dart` builds a real PDF with the `pdf`
   package (title + body wrapped across pages via `MultiPage`), saved to
   the app documents dir, then Open + Share like other tools. Appears in
   the Home quick-tools grid and Tools screen automatically (enum-driven).
   Verified: unit tests generate a real PDF (`%PDF-` header, longer body
   → bigger file).
7. **"Free forever / no ads / no subscription" wording removed from the
   app UI** (user request). Removed: Home subtitle ("Free forever •
   No ads" → "Read, edit and share PDFs"), Home footer (→ "Open PDF
   Reader • Version 1.2.0"), Home "All free" (→ "7 tools"), Tools heading
   ("All tools are free — no limits, no subscription." → "Everything you
   need for your PDFs."), Settings "Free forever" card (→ plain app-info
   card: "Open PDF Reader — Read, edit and share your PDFs. Everything
   works offline, on your device."). Verified by grep: no such phrases
   remain in `lib/` (docs/README/BUILD_NOTES may still describe the app
   factually). Functionality unchanged.

Release: tag `v1.2.0-release-<run>`, arm64 APK at
`build/app/outputs/flutter-apk/app-release-arm64-v8a.apk`, delivery copy
`~/workspace/pdf-app/open-pdf-reader-v2.1-arm64.apk`. Rebuild: push to
`main` or `workflow_dispatch` (PAT helper `github.py push-tree`).
Release APKs are still signed with debug keys — a Play Store release
will need a proper keystore later.

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

## GitHub Actions build — DONE (2026-11-15)

Local Gradle builds are impossible in this VM: Java loopback TCP is
blocked (a Java server on 127.0.0.1 never receives its own client's
bytes), so the Gradle daemon can never talk to its client. The APK is
built in the cloud instead.

- **Repo:** https://github.com/soul7tunes/open-pdf-reader (public, created
  2026-11-15 via the stored GitHub PAT, connector `custom.github` —
  helper `~/workspace/custom-connectors/custom.github/bin/github.py`)
- **Workflow:** `.github/workflows/build-apk.yml` — push to main or
  `workflow_dispatch`, ubuntu-latest, Java 17 (Temurin), Flutter 3.50.0,
  `flutter pub get` / `flutter analyze --no-fatal-infos` / `flutter test` /
  `flutter build apk --debug`, upload-artifact + GitHub Release with the APK
- **Successful run:** https://github.com/soul7tunes/open-pdf-reader/actions/runs/43734794384 (run 3)
- **Release:** https://github.com/soul7tunes/open-pdf-reader/releases/tag/v1.0.0-debug-3
  ("Open PDF Reader v1.0.0 debug build 3")
- **APK:** `build/app/outputs/flutter-apk/app-debug.apk`, 155 MB,
  sha256 `d41a7b80af54325abb15b70f84543f9fde3793c2d49cf02868789f21d2da8a0b`
  (copy at `~/workspace/pdf-app/open-pdf-reader-app-debug.apk`).
  Verified with `aapt2 dump badging`: package `com.manish.openpdfreader`,
  versionCode 1, versionName 1.0.0, minSdk 24, targetSdk 36.

Two failures happened on the way there, both fixed in the workflow:
1. Run 1 (43733265036) failed at `flutter analyze` — Flutter 3.50 treats
   the 7 info-level `deprecated_member_use` notices (material.dart is
   deprecated) as fatal, so the step now runs
   `flutter analyze --no-fatal-infos`. (Local `flutter analyze` reports
   the same 7 infos; the app deliberately stays on material.dart for V1.)
2. Run 2 (43733643969) built the APK fine but the Release step failed
   403 "Resource not accessible by integration" — the default
   `GITHUB_TOKEN` could not create a release. The workflow now declares
   `permissions: contents: write` at the top level. (The run-2 APK was
   still recovered from the uploaded artifact, 83,450,242-byte zip,
   artifact ID 14170020663, sha256
   `4ddcccb82e509e926e195d20cf60a59949cf09f9df9ed045ddf6d4f9109dadf4` —
   superseded by the run-3 release APK above.)

To rebuild: push to `main` (or trigger `workflow_dispatch`); the new
release appears at
`https://github.com/soul7tunes/open-pdf-reader/releases/latest`.
Do NOT use the system GitHub MCP connector for this repo — its App is
not installed and every call 403s. Use only the `custom.github` helper
with the stored PAT.

## V2 — 1.1.0 (2026-11-15)

V2 is a full redesign + real Merge/Split/Compress, built as a release APK
in GitHub Actions (local Gradle build is still impossible in this VM).

### Design system — glassmorphism

- **Style:** dark glassmorphism / liquid glass, inspired by the user's
  starred Drive folder "Design all" → "Website ui design": deep indigo
  background, frosted-glass cards, violet→pink→blue gradient glow, big
  bold type, pill buttons, glass bottom nav.
- **Theme:** `lib/theme/app_theme.dart` (dark-first + light glass theme).
- **Logo:** `assets/images/media-generation-open-pdf-reader-logo-0-58ab363c-35be-4eac-8392-cf66afd8768a.webp`
  (white document, folded corner, gradient lines, indigo glass square).
  Used in-app and as the launcher icon
  (`android/app/src/main/res/mipmap-*/ic_launcher.png`).
- **Fonts (OFL licensed):** Poppins for headings (Bold/SemiBold/Medium),
  Inter for body (Regular) — `assets/fonts/`, declared in `pubspec.yaml`.

### Real Merge / Split / Compress

`lib/services/pdf_tools.dart` — all three tools now work for real (V1 had
placeholder screens):

- **Merge:** pick 2+ PDFs, pages are combined in order into one PDF.
- **Split:** pick a PDF and a page range, output is a new PDF with just
  those pages.
- **Compress:** re-renders every page at lower resolution/JPEG quality
  for a smaller file.
- **Honest limitation:** all three work by re-rendering pages as images
  (pdfx `page.render` → JPEG) and composing them with the `pdf` package,
  so **output text is NOT selectable and is not searchable** — the pages
  are pictures of the original pages. Quality is kept reasonable
  (merge: maxWidth 1240, JPEG 85). This is a known trade-off, not a bug;
  true vector-preserving merge would need a different PDF library.

### Release build

- **Command (in the workflow):**
  `flutter build apk --release --split-per-abi --shrink --obfuscate --split-debug-info=build/debug-info`
- **Workflow:** `.github/workflows/build-apk.yml` (same file as V1, build
  step changed from `--debug` to the release command above; release tag
  is now `v1.1.0-release-${{ github.run_number }}`).
- **Signing:** release builds are still signed with the debug keys
  (`signingConfig = signingConfigs.getByName("debug")` in
  `android/app/build.gradle.kts`) — no release keystore exists yet.
- **Successful run:** https://github.com/soul7tunes/open-pdf-reader/actions/runs/43739021112 (run 5)
- **Release:** https://github.com/soul7tunes/open-pdf-reader/releases/tag/v1.1.0-release-5
  ("Open PDF Reader v1.1.0 build 5")
- **APK sizes (all three split APKs from the release):**

  | APK | Size (bytes) | Size |
  | --- | --- | --- |
  | `app-arm64-v8a-release.apk` | 18,675,422 | ~17.8 MB |
  | `app-armeabi-v7a-release.apk` | 16,442,840 | ~15.7 MB |
  | `app-x86_64-release.apk` | 20,041,909 | ~19.1 MB |

  Total ~55.2 MB for all three — a huge drop from the 155 MB V1 debug
  APK (release shrink + split-per-abi + obfuscation).
- **arm64 APK (delivery):**
  `build/app/outputs/flutter-apk/app-release-arm64-v8a.apk`,
  copy at `~/workspace/pdf-app/open-pdf-reader-v2-arm64.apk`,
  sha256 `44537b3923063f3b501698194cbaee571ab66e21b819beb5bdac0b7ccb5bd9a3`.
  Verified with `file` (Android package (APK)) and
  `aapt2 dump badging`: package `com.manish.openpdfreader`,
  versionCode 2002, versionName 1.1.0, minSdk 24, targetSdk 36.

One failure happened on the way there, fixed once:
- Run 4 (43738200531) failed at the release build step —
  `Execution failed for task ':image_picker_android:lintVitalAnalyzeRelease'`
  (AGP lint `NoSuchMethodError` in `JavaDocParser` inside the
  `image_picker_android` dependency — a plugin/AGP incompatibility, not
  our code). Fix: `android/app/build.gradle.kts` now has
  `lint { checkReleaseBuilds = false; abortOnError = false }`.
  Lint still runs via `flutter analyze` in the workflow; it is only
  skipped for release builds. Run 5 then succeeded.

To rebuild: push to `main` (or trigger `workflow_dispatch`); the new
release appears at
`https://github.com/soul7tunes/open-pdf-reader/releases/latest`.
Do NOT use the system GitHub MCP connector for this repo — its App is
not installed and every call 403s. Use only the `custom.github` helper
with the stored PAT.

## BLOCKER (historical) — local debug APK build does not work in this VM

`flutter build apk --debug` fails while the Gradle daemon starts but
cannot be connected to ("first result from the daemon was empty").
Root cause: Java loopback TCP is blocked in this VM (proven by
`~/workspace/pdf-app/tmp/looptest/LoopTest.java`). The `other_tcp`
permission is already ON and licences are accepted, but that does not
fix loopback. Build in GitHub Actions instead (see above). The old
Python TCP relay (`~/workspace/pdf-app/tools/tcp-relay.py`) is no longer
running and is not useful — Java cannot TCP-connect even to localhost.

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
