# BunnyPad for Android

Native Kotlin / Jetpack Compose port of BunnyPad. Supports Android 8.0 (API 26)
and later. Application ID: org.bunnypad.android.

## Build and run

Open this **Android** directory as a project in Android Studio, sync Gradle,
select a device, and Run. Use JDK 17 or later (Android Studio's bundled runtime
works). Install Android SDK Platform 36 and accept its SDK licenses.

From this directory:

```sh
./gradlew testDebugUnitTest lintDebug assembleDebug assembleRelease bundleRelease
```

If your terminal has no JDK configured, set JAVA_HOME to Android Studio's runtime.
On a standard macOS installation:

```sh
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
./gradlew assembleDebug
```

Outputs:
- Installable, debug-signed APK: app/build/outputs/apk/debug/app-debug.apk
- Unsigned release APK: app/build/outputs/apk/release/app-release-unsigned.apk
- Release bundle: app/build/outputs/bundle/release/app-release.aab

Release outputs require your own release signing configuration before distribution.
No release credentials are stored in this repository. The Android GitHub Actions
workflow builds these artifacts and uploads them with test/lint reports.

## Features

- New, Open, Save and Save As through the Android system document picker;
  no broad storage permission. Access to selected documents is persisted where
  the provider permits it.
- Save/Discard/Cancel before switching away from an edited note. Cancelled
  pickers and failed opens retain the current note.
- Private recovery draft, saved after a short debounce and when backgrounding.
  The current note, cursor, file association and encoding restore after restart.
  Recovery is separate from saving to the document's chosen location.
- Undo/redo (bounded history), system selection and clipboard actions,
  case-insensitive Find/Replace, Go to Line and date/time insertion.
- Word wrapping, monospace text-size preference, system/light/dark appearance.
- Line, column, character count, encoding and line-ending status.
- About with original project attribution and source link; a native vector bunny
  launcher icon created for this Android port.

UTF-8 with or without BOM, BOM-marked UTF-16LE/BE and Latin-1 are supported.
The encoding, BOM and predominant line ending are retained. Mixed line endings
are normalized to the predominant style (CRLF wins a tie). New documents use
UTF-8 and LF. Use UTF-8 converts legacy documents when inserted characters
cannot be represented; conversion can be undone. Encoding errors are detected
before opening the output for truncation.

Files above 16 MiB, documents above 4 million UTF-16 code units, malformed
BOM-marked text and detected binary files are rejected. Character counts and
columns use UTF-16 code units, matching the editor's cursor offsets.

## Verification and limitations

Debug APK, unsigned release APK and release AAB build locally. Eleven document
tests cover byte-preserving encoding round trips, line endings, empty documents,
binary/oversize rejection and unrepresentable characters. Android lint passes
with template dependency/version and unused-resource warnings.

UI tests cover editing, undo/redo, unsaved-change cancellation and activity
recreation. Compile them with:

```sh
./gradlew assembleDebugAndroidTest
```

Run them on a connected device/emulator with:

```sh
./gradlew connectedDebugAndroidTest
```

No device or emulator was available during initial verification, so UI tests
and document-picker interactions still need an on-device acceptance pass:
create/save/reopen a note; edit and cancel New/Open; undo/redo; Find/Replace;
Go to Line; long lines with wrapping off; change theme/font size; rotate;
background and restart the app; test a read-only or unavailable provider.

This first port edits one document at a time. Printing, desktop menus, multiple
windows, the Windows update checker, installers and Python session files are
not ported. Undo history persists across rotation but is not stored in the
recovery draft. An abrupt kill within the debounce interval can lose the latest
keystrokes. A provider write failure can leave a partially written external file;
the recovery draft remains available for Save As. External edits are not merged
automatically; reopen a document to load changes made elsewhere.

Drafts live in private app storage and may be included in Android's system
backup according to device policy. Export notes with Save As before clearing
app data or uninstalling.

Original BunnyPad: https://github.com/GSYT-Productions/BunnyPad-SRC
Original artwork by PBbunnypower; this port uses a new vector launcher illustration.
Apache License 2.0; see ../LICENSE and the root README for attribution and terms.
