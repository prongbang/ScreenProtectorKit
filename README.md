# ScreenProtectorKit 🛡️

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://developer.apple.com/ios/)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/ScreenProtectorKit.svg)](https://cocoapods.org/pods/ScreenProtectorKit)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> Secure your iOS app's sensitive data by preventing screenshots and protecting background app snapshots with ease.

## ✨ Features

- 📸 **Screenshot Prevention** - Detect and handle screenshot attempts
- 🖼️ **Custom Background Protection** - Replace app preview with custom content
- 🎨 **Multiple Protection Styles**:
  - Blur effect
  - Custom image
  - Solid color
- 🎬 **Screen Recording Detection** - Know when screen is being recorded
- 🚀 **Easy Integration** - Simple API with clear documentation
- 📦 **Multiple Installation Options** - CocoaPods and Swift Package Manager support

## 📦 Installation

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'ScreenProtectorKit'
```

Then run:
```bash
pod install
```

### Swift Package Manager

Add to your `Package.swift`:

```swift
let package = Package(
  dependencies: [
    .package(url: "https://github.com/prongbang/ScreenProtectorKit.git", from: "1.5.1"),
  ],
)
```

Or via Xcode:
1. File → Add Packages...
2. Enter package URL: `https://github.com/prongbang/ScreenProtectorKit.git`
3. Select version: `1.5.1` or later

## 🚀 Quick Start

### Basic Setup

Do not attach or manipulate UIKit views/layers for screenshot protection.
Use a separate overlay window or a SwiftUI-based view instead.
This avoids conflicts with the system’s CALayer layout and prevents crashes.

- AppDelegate

```swift
import ScreenProtectorKit

class AppDelegate: UIApplicationDelegate {
    private lazy var screenProtectorKit = {
        return ScreenProtectorKit(window: window)
    }()
}
```

## 📱 Protection Methods

### 1. Screenshot Prevention

Detect and respond to screenshot attempts:

```swift
override func applicationDidBecomeActive(_ application: UIApplication) {
    screenProtectorKit.enabledPreventScreenshot()
}

override func applicationWillResignActive(_ application: UIApplication) {
    screenProtectorKit.disablePreventScreenshot()
}
```

### 2. Blur Background Protection

Apply blur effect when app goes to background:

```swift
override func applicationDidBecomeActive(_ application: UIApplication) {
    screenProtectorKit.disableBlurScreen()
}

override func applicationWillResignActive(_ application: UIApplication) {
    screenProtectorKit.enabledBlurScreen()
}
```

### 3. Image Background Protection

Show custom image when app is in background:

```swift
override func applicationDidBecomeActive(_ application: UIApplication) {
    screenProtectorKit.disableImageScreen()
}

override func applicationWillResignActive(_ application: UIApplication) {
    screenProtectorKit.enabledImageScreen(named: "LaunchImage")
}
```

### 4. Color Background Protection

Display solid color when app is in background:

```swift
override func applicationDidBecomeActive(_ application: UIApplication) {
    screenProtectorKit.disableColorScreen()
}

override func applicationWillResignActive(_ application: UIApplication) {
    screenProtectorKit.enabledColorScreen(hexColor: "#ffffff")
}
```

### 5. Screen Recording Detection

Check if screen is being recorded:

```swift
let isRecording = screenProtectorKit.screenIsRecording()
if isRecording {
    // Handle screen recording scenario
}
```

## 💡 Usage Examples

### Complete Implementation

```swift
import ScreenProtectorKit

class AppDelegate: UIApplicationDelegate {
    private lazy var screenProtectorKit = {
        return ScreenProtectorKit(window: window)
    }()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Handle screen recording if needed
        if screenProtectorKit.screenIsRecording() {
            showRecordingWarning()
        }

        return true
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        // Remove protection overlay
        screenProtectorKit.disableBlurScreen()
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        // Add protection overlay
        screenProtectorKit.enabledBlurScreen()
    }

    private func showRecordingWarning() {
        // Show alert to user about screen recording
    }
}
```

## ⚠️ Important Notes

- Screenshot prevention on iOS works by detecting attempts, not blocking them entirely
- Background protection helps prevent data leaks in app switcher
- Screen recording detection only indicates if recording is in progress
- Test thoroughly across different iOS versions and devices

## 🔧 Requirements

- iOS 11.0+
- Swift 5.5+
- Xcode 13.0+

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.


## 💖 Support the Project

If you find this package helpful, please consider supporting it:

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/prongbang)

## 🔗 Links

- [Report Issues](https://github.com/prongbang/ScreenProtectorKit/issues)

---
