# BunnyPad — iOS 6 Legacy Edition 🐰📱

A native, authentic Objective-C & UIKit implementation of **BunnyPad** built specifically for legacy **iOS 6** (compatible with iOS 5.1.1 through iOS 6.1.6).

---

## 🎯 Target Devices & Architectures

| Architecture | Target Devices |
| :--- | :--- |
| **armv7** | iPhone 3GS, iPhone 4, iPhone 4S, iPod touch (3rd, 4th, 5th gen), iPad (1st, 2nd, 3rd gen), iPad mini (1st gen) |
| **armv7s** | iPhone 5, iPad (4th gen) |
| **i386** | iOS Simulator (legacy OS X / macOS running Xcode 4.x / 5.x) |

---

## ✨ Features

- **Classic BunnyPad Interface**:
  - Landing screen with the official BunnyPad logo, gold action buttons, and saved notes browser.
  - Full-screen text editor with word wrapping, font scaling, and dynamic character/word/line counter.
- **Classic iOS 6 Theme Support**:
  - **Bunny Gradient**: Authentic purple-violet gradient.
  - **Classic Dark**: Sleek midnight theme.
  - **Classic Light**: Clean paper-like aesthetic.
- **Productivity & Note Tools**:
  - **New Note** & **Quick Note** scratchpad.
  - **Find in Note**: Search text with highlighting.
  - **Date & Time insertion**: Quick stamp at cursor position.
  - **Full Undo / Redo**: Integrated with iOS 6 `NSUndoManager`.
  - **Native Share Sheet**: Uses iOS 6 `UIActivityViewController` (Email, Message, Copy, Print).
- **File Management & Syncing**:
  - Saves standard `.txt` plain-text files directly into the sandbox Documents directory.
  - **iTunes File Sharing enabled**: Drop text files into BunnyPad directly through iTunes or Finder.

---

## 🛠 Project Structure

```
Bunnypad/iOS6/
├── Bunnypad-iOS6-Info.plist    # iOS 6 App metadata & bundle definitions
├── Makefile                     # Theos build file for modern macOS compilation
├── build.sh                     # Automated build & package script
├── main.m                       # App entry point
├── BPAppDelegate.h / .m         # Application lifecycle & URL opening
├── BPHomeViewController.h / .m  # Home landing screen & notes list
├── BPEditorViewController.h / .m# Full-screen text editor & toolbar
├── BPSettingsViewController.h / .m # Liquid glass style Settings modal
├── BPAboutViewController.h / .m # About BunnyPad modal
├── BPNoteManager.h / .m         # Document file management
├── BPTheme.h / .m               # Multi-theme styling system
└── Resources/                   # App icons (57, 72, 114, 144px) & BunnyPad logo
```

---

## 🚀 How to Build & Install

### Method 1: Using Theos (Recommended for Modern macOS / Linux)

1. Install [Theos](https://theos.dev):
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
   ```
2. Place an iOS 6.1 SDK in `$THEOS/sdks/`.
3. In this directory, run:
   ```bash
   make package FINALPACKAGE=1
   ```
4. The generated `.deb` or `.ipa` in `packages/` can be installed on your jailbroken or sideloaded iOS 6 device.

### Method 2: Using Legacy Xcode (Xcode 4.5 – 5.1 on OS X Mountain Lion / Mavericks)

1. Open Xcode 4 or 5 on a vintage Mac or virtual machine.
2. Create an **Empty Application** or **Single View Application** project targeting iOS 6.0+.
3. Drag all files from `Bunnypad/iOS6/` into your project.
4. Set **Architectures** to `Standard (armv7, armv7s)` and **Deployment Target** to `6.0`.
5. Connect your device and click **Run** or **Archive**.

### Method 3: Sideloading onto iOS 6 Device

- **AppSync Unified (Jailbroken)**: Copy `Bunnypad.app` to `/Applications/` on the device and run `uicache`.
- **Sideloadly / Cydia Impactor**: Sideload the generated `.ipa` using your Apple ID.
