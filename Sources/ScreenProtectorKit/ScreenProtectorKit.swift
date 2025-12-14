//
//  ScreenProtectorKit.swift
//  Runner
//
//  Created by prongbang on 19/2/2565 BE.
//

import UIKit
import ScreenPreventerKit

public protocol ScreenProtectorRootViewResolving {
    func resolveRootView() -> UIView?
}

public enum ScreenProtectorMode: Equatable {
    case none
    case blur
    case image(name: String)
    case color(hex: String)
}

public protocol ScreenProtectable {
    func screenIsRecording() -> Bool
    func screenRecordObserver(using onScreenRecord: @escaping (Bool) -> Void)
    func screenshotObserver(using onScreenshot: @escaping () -> Void)
    func removeAllObserver()
    func removeScreenRecordObserver()
    func removeScreenshotObserver()
    func removeObserver(observer: (any NSObjectProtocol)?)
    func disableImageScreen()
    func enabledImageScreen(named: String)
    func disableColorScreen()
    func enabledColorScreen(hexColor: String)
    func disableBlurScreen()
    func enabledBlurScreen(style: UIBlurEffect.Style)
    func disablePreventScreenRecording()
    func disablePreventScreenshot()
    func enablePreventScreenshot()
    func enabledPreventScreenRecording(text: String?, image: String?)
    func enabledPreventScreenshot(text: String?, image: String?)
    func enabledBlurScreen()
    func enabledPreventScreenshot()
    func enabledPreventScreenRecording()
    func setRootViewResolver(_ resolver: ScreenProtectorRootViewResolving)
    func setWindow(_ window: UIWindow?)
}

public class ScreenProtectorKit: ScreenProtectable {
    public var window: UIWindow? = nil
    private let screenPreventer: ScreenPreventer
    
    public init(window: UIWindow? = nil) {
        self.window = window
        screenPreventer = ScreenPreventer(window: window)
    }
    
    public static func initial(with view: UIView?) {
        ScreenPreventer.initial(with: view)
    }
    
    public func setWindow(_ window: UIWindow?) {
        self.window = window
    }
    
    @available(*, deprecated, message: "This API will be removed in a future release due to crashes on some devices.")
    public func configurePreventionScreenshot() {}
    
    public func enabledPreventScreenshot() {
        screenPreventer.enabledPreventScreenshot()
    }
    
    public func enabledPreventScreenshot(text: String?, image: String?) {
        screenPreventer.enabledPreventScreenshot(text: text, image: image)
    }
    
    public func disablePreventScreenshot() {
        screenPreventer.disablePreventScreenshot()
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledBlurScreen()
    // }
    public func enabledBlurScreen() {
        screenPreventer.enabledBlurScreen()
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledBlurScreen(style: UIBlurEffect.Style.light)
    // }
    public func enabledBlurScreen(style: UIBlurEffect.Style) {
        screenPreventer.enabledBlurScreen(style: UIBlurEffect.Style.light)
    }
    
    // How to used:
    //
    // override func applicationDidBecomeActive(_ application: UIApplication) {
    //     screenProtectorKit.disableBlurScreen()
    // }
    public func disableBlurScreen() {
        screenPreventer.disableBlurScreen()
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledColorScreen(hexColor: "#ffffff")
    // }
    public func enabledColorScreen(hexColor: String) {
        screenPreventer.enabledColorScreen(hexColor: hexColor)
    }
    
    // How to used:
    //
    // override func applicationDidBecomeActive(_ application: UIApplication) {
    //     screenProtectorKit.disableColorScreen()
    // }
    public func disableColorScreen() {
        screenPreventer.disableColorScreen()
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledImageScreen(named: "LaunchImage")
    // }
    public func enabledImageScreen(named: String) {
        screenPreventer.enabledImageScreen(named: named)
    }
    
    // How to used:
    //
    // override func applicationDidBecomeActive(_ application: UIApplication) {
    //     screenProtectorKit.disableImageScreen()
    // }
    public func disableImageScreen() {
        screenPreventer.disableImageScreen()
    }
    
    // How to used:
    //
    // screenProtectorKit.removeObserver(observer: screenRecordObserve)
    public func removeObserver(observer: NSObjectProtocol?) {
        screenPreventer.removeObserver(observer: observer)
    }
    
    // How to used:
    //
    // screenProtectorKit.removeScreenshotObserver()
    public func removeScreenshotObserver() {
        screenPreventer.removeScreenshotObserver()
    }
    
    // How to used:
    //
    // screenProtectorKit.removeScreenRecordObserver()
    public func removeScreenRecordObserver() {
        screenPreventer.removeScreenRecordObserver()
    }
    
    // How to used:
    //
    // screenProtectorKit.removeAllObserver()
    public func removeAllObserver() {
        screenPreventer.removeAllObserver()
    }
    
    // How to used:
    //
    // screenProtectorKit.screenshotObserver {
    //      // Callback on Screenshot
    // }
    public func screenshotObserver(using onScreenshot: @escaping () -> Void) {
        screenPreventer.screenshotObserver(using: onScreenshot)
    }
    
    // How to used:
    //
    // if #available(iOS 11.0, *) {
    //     screenProtectorKit.screenRecordObserver { isCaptured in
    //         // Callback on Screen Record
    //     }
    // }
    @available(iOS 11.0, *)
    public func screenRecordObserver(using onScreenRecord: @escaping (Bool) -> Void) {
        screenPreventer.screenRecordObserver(using: onScreenRecord)
    }
    
    @available(iOS 11.0, *)
    public func screenIsRecording() -> Bool {
        return screenPreventer.screenIsRecording()
    }
    
    public func disablePreventScreenRecording() {
        screenPreventer.disablePreventScreenRecording()
    }
    
    public func enablePreventScreenshot() {
        screenPreventer.enablePreventScreenshot()
    }
    
    public func enabledPreventScreenRecording() {
        screenPreventer.enabledPreventScreenRecording()
    }
    
    public func enabledPreventScreenRecording(text: String?, image: String?) {
        screenPreventer.enabledPreventScreenRecording(text: text, image: image)
    }
    
    public func setRootViewResolver(_ resolver: ScreenProtectorRootViewResolving) {
        screenPreventer.setRootViewResolver(
            ClosureRootViewResolver(resolver)
        )
    }
}

internal struct ClosureRootViewResolver: ScreenPreventerRootViewResolving {
    let resolver: ScreenProtectorRootViewResolving
    
    init(_ resolver:  ScreenProtectorRootViewResolving) {
        self.resolver = resolver
    }
    
    func resolveRootView() -> UIView? {
        return resolver.resolveRootView()
    }
}
