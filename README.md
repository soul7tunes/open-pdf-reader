# Open PDF Reader

Open PDF Reader is a free PDF reader and tools app for Android — **free forever, no ads, no subscription, no tracking, no daily limits**. Read, merge, split, compress, convert and scan PDFs, all offline on your device.

## V1 features

- **Home:** open a PDF, scan the device for PDFs, recent files (max 20)
- **PDF viewer:** pinch zoom, page indicator, previous/next, jump to a page, share
- **Tools:** Image to PDF and Scan to PDF (create real PDFs), PDF to Image (render a page to PNG)
- **Coming next:** Merge PDF, Split PDF, Compress PDF (screens are in the app, engines next)
- **Settings:** dark mode, clear recents, "Free forever" — no ads, no payment

## Build it

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is at `build/app/outputs/flutter-apk/app-debug.apk`.

Or use GitHub Actions: every push to `main` runs `.github/workflows/build-apk.yml`, which builds the debug APK, uploads it as an artifact, and attaches it to a GitHub Release (`v1.0.0-debug-<run number>`).

## Tech

- Flutter 3.50.0 (Dart 3.14), package `com.manish.openpdfreader`
- PDF viewing with pdfx (Pdfium), PDF creation with the `pdf` package
- Open-source packages only: pdfx, pdf, file_picker, permission_handler, path_provider, share_plus, image_picker
