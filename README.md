# Open PDF Reader

Open PDF Reader is a free PDF reader and tools app for Android — **free forever, no ads, no subscription, no tracking, no daily limits**. Read, merge, split, compress, convert and scan PDFs, all offline on your device.

## V2 — premium glass design

- **Dark glassmorphism UI (dark-first):** deep indigo background with violet → pink → blue gradient glow, frosted glass cards, pill buttons, glass bottom navigation — plus a light lavender-glass theme.
- **New logo:** white document with gradient lines on an indigo glass square — in the app header, Settings, and as the Android launcher icon.
- **Typography:** Poppins for headings, Inter for body. Big and readable — screen titles 24–28, section titles 18–20, body 15–16.
- **Motion:** staggered fade + slide-in lists, springy press-scale buttons, hero transition from a recent file into the viewer, floating glass pill for viewer controls.
- **Home:** logo header, big gradient "Open a PDF" button, device scan, glass search over your PDFs, quick-tools bento grid, recent files with size + date and swipe-to-remove.
- **Viewer:** pinch zoom, floating glass page controls, page jump, share.
- **Tools — all real now:** Merge PDF (reorder files, all pages in order), Split PDF (page range, or one file per page), Compress PDF (Small / Balanced / Best), Image to PDF, Scan to PDF, PDF to Image.
- **Settings:** dark mode, clear recents, "Free forever" — no ads, no payment.

One honest limit: Merge, Split and Compress re-render pages as images, so the output keeps the exact look of every page but its text is not selectable. Text search in the viewer is still coming (pdfx has no text-search API) — the search box jumps to a page number.

## Build it

```sh
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --release --split-per-abi --shrink --obfuscate --split-debug-info=build/debug-info
```

The release APKs are at `build/app/outputs/flutter-apk/app-*-release.apk` (one per ABI — arm64-v8a is the one most phones need).

Or use GitHub Actions: every push to `main` runs `.github/workflows/build-apk.yml`, which builds the release APKs, uploads them as an artifact, and attaches them to a GitHub Release (`v1.1.0-release-<run number>`).

## Tech

- Flutter 3.50.0 (Dart 3.14), package `com.manish.openpdfreader`
- PDF viewing with pdfx (Pdfium), PDF creation with the `pdf` package
- Open-source packages only: pdfx, pdf, file_picker, permission_handler, path_provider, share_plus, image_picker
- Fonts: Poppins + Inter (OFL licensed), bundled in `assets/fonts/`
