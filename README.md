# ScreenProtectorKit

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://developer.apple.com/ios/)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/ScreenProtectorKit.svg)](https://cocoapods.org/pods/ScreenProtectorKit)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-Apache2.0-blue.svg)](LICENSE)

`ScreenProtectorKit` helps protect sensitive iOS screens from screenshots, screen recording, and app-switcher snapshots. It supports UIKit, SwiftUI, and Objective-C integrations.

## Features

- Screenshot protection for a whole app window or a specific `UIView`
- SwiftUI `protectedView(isProtected:)` helper for protecting one view tree
- Screen-recording protection and screen-recording state observer
- Screenshot observer
- App-switcher background protection using blur, image, or solid color
- Lifecycle-aware reapply behavior when the app returns to foreground, a scene activates, or Dynamic Type changes
- CocoaPods and Swift Package Manager support

## Installation

### CocoaPods

Add the pod to your `Podfile`:

```ruby
pod 'ScreenProtectorKit'
```

Then install it:

```bash
pod install
```

### Swift Package Manager

In Xcode, open `File > Add Package Dependencies...`, then use:

```text
https://github.com/prongbang/ScreenProtectorKit.git
```

Or add it to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/prongbang/ScreenProtectorKit.git", from: "1.5.2"),
]
```

The package already includes `ScreenPreventerKit.xcframework`, so no extra binary setup is required.

## Usage

Keep one `ScreenProtectorKit` instance for the lifetime of the protected app, scene, or screen. For app-wide protection, pass the active `UIWindow`. For per-view protection, enable protection only after the target view is already attached to a window, usually in `viewDidAppear`.

### UIKit App-Wide Protection

Use this when the whole app or the current scene should be protected.

```swift
import UIKit
import ScreenProtectorKit

final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private lazy var screenProtectorKit = ScreenProtectorKit(window: window)

    func applicationDidBecomeActive(_ application: UIApplication) {
        screenProtectorKit.setWindow(window)
        screenProtectorKit.enabledPreventScreenshot()
        screenProtectorKit.disableBlurScreen()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        screenProtectorKit.enabledBlurScreen()
    }
}
```

For multi-scene apps, bind the protector to the scene's own window.

```swift
import UIKit
import ScreenProtectorKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private let screenProtectorKit = ScreenProtectorKit()

    func sceneDidBecomeActive(_ scene: UIScene) {
        screenProtectorKit.setWindow(window)
        screenProtectorKit.enabledPreventScreenshot()
        screenProtectorKit.disableBlurScreen()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        screenProtectorKit.enabledBlurScreen()
    }
}
```

### SwiftUI App-Wide Protection

Resolve the active `UIWindow` from SwiftUI, then pass it to `ScreenProtectorKit`. This keeps protection tied to the correct scene instead of relying on a global key-window lookup.

```swift
import SwiftUI
import ScreenProtectorKit

@main
struct DemoApp: App {
    @StateObject private var protector = AppScreenProtector()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowReader { window in
                    protector.configure(window: window)
                })
        }
    }
}

@MainActor
final class AppScreenProtector: ObservableObject {
    private let screenProtectorKit = ScreenProtectorKit()

    func configure(window: UIWindow?) {
        guard let window else { return }

        screenProtectorKit.setWindow(window)
        screenProtectorKit.setRootViewResolver(WindowRootViewResolver(window: window))
        screenProtectorKit.enabledPreventScreenshot()
    }
}

private struct WindowReader: UIViewRepresentable {
    let onResolve: (UIWindow?) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            onResolve(view.window)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            onResolve(uiView.window)
        }
    }
}

private final class WindowRootViewResolver: ScreenProtectorRootViewResolving {
    weak var window: UIWindow?

    init(window: UIWindow?) {
        self.window = window
    }

    func resolveRootView() -> UIView? {
        return window?.rootViewController?.view
    }
}
```

### Protect A Specific UIKit View

Use `enabledPreventScreenshot(for:)` when only one screen or one sensitive view should be protected. Enable in `viewDidAppear` and disable in `viewDidDisappear` so protection does not leak into other screens.

```swift
import UIKit
import ScreenProtectorKit

final class PaymentViewController: UIViewController {
    @IBOutlet private weak var sensitiveView: UIView!

    private let screenProtectorKit = ScreenProtectorKit()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        screenProtectorKit.enabledPreventScreenshot(for: sensitiveView)
        screenProtectorKit.enabledPreventScreenRecording()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        screenProtectorKit.disablePreventScreenshot(for: sensitiveView)
        screenProtectorKit.disablePreventScreenRecording()
    }
}
```

### Protect A Specific SwiftUI View

On iOS 13+, wrap the sensitive SwiftUI content with `protectedView(isProtected:)`.

```swift
import SwiftUI
import ScreenProtectorKit

struct PaymentView: View {
    @StateObject private var protector = PaymentScreenProtector()

    var body: some View {
        protector.screenProtectorKit.protectedView(isProtected: protector.isProtected) {
            PaymentContent()
        }
        .onAppear {
            protector.enable()
        }
        .onDisappear {
            protector.disable()
        }
    }
}

@MainActor
final class PaymentScreenProtector: ObservableObject {
    let screenProtectorKit = ScreenProtectorKit()
    @Published var isProtected = false

    func enable() {
        isProtected = true
        screenProtectorKit.enabledPreventScreenRecording()
    }

    func disable() {
        isProtected = false
        screenProtectorKit.disablePreventScreenRecording()
    }
}
```

### Objective-C

`ScreenProtectorKit` is exposed to Objective-C. Keep one strong instance for the app delegate or scene delegate lifetime.

```objc
@import ScreenProtectorKit;

@interface AppDelegate ()
@property (nonatomic, strong) ScreenProtectorKit *screenProtectorKit;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.screenProtectorKit = [[ScreenProtectorKit alloc] initWithWindow:self.window];
    [self.screenProtectorKit enabledPreventScreenshot];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.screenProtectorKit setWindow:self.window];
    [self.screenProtectorKit enabledPreventScreenshot];
    [self.screenProtectorKit disableBlurScreen];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self.screenProtectorKit enabledBlurScreen];
}

@end
```

## API Examples

### Screenshot Protection

```swift
screenProtectorKit.enabledPreventScreenshot()
screenProtectorKit.enabledPreventScreenshot(text: "Protected", image: "ShieldImage")
screenProtectorKit.disablePreventScreenshot()
```

For one view:

```swift
let didEnable = screenProtectorKit.enabledPreventScreenshot(for: sensitiveView)
let didDisable = screenProtectorKit.disablePreventScreenshot(for: sensitiveView)
```

### Screenshot Observer

```swift
screenProtectorKit.screenshotObserver {
    // Called after the user takes a screenshot.
}
```

Remove observers when they are no longer needed:

```swift
screenProtectorKit.removeScreenshotObserver()
screenProtectorKit.removeAllObserver()
```

### Screen Recording Protection

```swift
if screenProtectorKit.screenIsRecording() {
    // Show a warning, hide data, or block the sensitive workflow.
}

screenProtectorKit.screenRecordObserver { isRecording in
    if isRecording {
        screenProtectorKit.enabledPreventScreenRecording()
    } else {
        screenProtectorKit.disablePreventScreenRecording()
    }
}
```

You can also provide protected content while recording is active:

```swift
screenProtectorKit.enabledPreventScreenRecording(text: "Recording is blocked", image: "ShieldImage")
```

### Background Snapshot Protection

Use one of these before the app or scene resigns active, then disable it when the app becomes active again.

```swift
screenProtectorKit.enabledBlurScreen()
screenProtectorKit.enabledBlurScreen(style: .light)
screenProtectorKit.enabledImageScreen(named: "LaunchImage")
screenProtectorKit.enabledColorScreen(hexColor: "#FFFFFF")

screenProtectorKit.disableBlurScreen()
screenProtectorKit.disableImageScreen()
screenProtectorKit.disableColorScreen()
```

### Temporarily Suspend Screenshot Protection

Some flows, such as opening Settings, showing a camera, presenting a document picker, or launching an external URL, may need protection to pause briefly. Suspend before leaving the protected UI and resume from an app or scene lifecycle callback.

```swift
func openAppSettings() {
    screenProtectorKit.suspendPreventScreenshotProtection()

    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
}

func sceneDidBecomeActive(_ scene: UIScene) {
    screenProtectorKit.resumePreventScreenshotProtection()
    screenProtectorKit.enabledPreventScreenshot()
}
```

## Notes

- Keep the `ScreenProtectorKit` instance alive. Do not create it as a temporary local variable.
- For per-view protection, call `enabledPreventScreenshot(for:)` after the view has a `window`.
- In multi-scene apps, call `setWindow(_:)` with the scene's current `UIWindow`.
- The package reapplies configured protection after foreground, scene activation, and Dynamic Type changes.
- Screenshot and recording protection rely on iOS view behavior and should be tested on the iOS versions and devices you support.
- Background blur/image/color protection is for app-switcher snapshots, not for live screenshot blocking.

## Requirements

- iOS 12.0+
- Swift 5.5+
- Xcode 13.0+
- SwiftUI helper: iOS 13.0+

## Contributing

Contributions are welcome. Please feel free to submit a pull request.

## License

This project is licensed under the Apache 2.0 License. See [LICENSE](LICENSE) for details.

## Support The Project

If you find this package helpful, please consider supporting it:

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/prongbang)

## Links

- [Report Issues](https://github.com/prongbang/ScreenProtectorKit/issues)
