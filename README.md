# ScreenProtectorKit

Safe Data Leakage via Application Background Screenshot and Prevent Screenshot for iOS.

## CocoaPods

```shell
pod 'ScreenProtectorKit'
```

## Swift Package Manager

In your `Package.swift` file, add `ScreenProtectorKit` dependency to corresponding targets:

```swift
let package = Package(
  dependencies: [
    .package(url: "https://github.com/prongbang/ScreenProtectorKit.git", from: "1.1.0"),
  ],
)
```

## How to use

### Prevent Screenshot

```swift
import ScreenProtectorKit

class AppDelegate: FlutterAppDelegate {

    private lazy var screenProtectorKit = { return ScreenProtectorKit(window: window) }()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
    
        screenProtectorKit.configurePreventionScreenshot()
    
        return true
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        screenProtectorKit.enabledPreventScreenshot()
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        screenProtectorKit.disablePreventScreenshot()
    }
    
}
```

### Blur Background Screenshot

```swift
import ScreenProtectorKit

class AppDelegate: FlutterAppDelegate {

    private lazy var screenProtectorKit = { return ScreenProtectorKit(window: window) }()

    override func applicationDidBecomeActive(_ application: UIApplication) {
        screenProtectorKit.disableBlurScreen()
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        screenProtectorKit.enabledBlurScreen()
    }
    
}
```

### Image Background Screenshot

```swift
import ScreenProtectorKit

class AppDelegate: FlutterAppDelegate {

    private lazy var screenProtectorKit = { return ScreenProtectorKit(window: window) }()

    override func applicationDidBecomeActive(_ application: UIApplication) {
        screenProtectorKit.disableImageScreen()
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        screenProtectorKit.enabledImageScreen(named: "LaunchImage")
    }
    
}
```

### Color Background Screenshot

```swift
import ScreenProtectorKit

class AppDelegate: FlutterAppDelegate {

    private lazy var screenProtectorKit = { return ScreenProtectorKit(window: window) }()

    override func applicationDidBecomeActive(_ application: UIApplication) {
        screenProtectorKit.disableColorScreen()
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        screenProtectorKit.enabledColorScreen(hexColor: "#ffffff")
    }
    
}
```
