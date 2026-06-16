//
//  ScreenProtectorKit.swift
//  Runner
//
//  Created by prongbang on 19/2/2565 BE.
//

import UIKit
import ScreenPreventerKit
#if canImport(SwiftUI)
import SwiftUI
#endif

internal protocol ScreenPreventerWindowConfiguring: AnyObject {
    var window: UIWindow? { get set }
}

internal protocol ScreenPreventerViewProtecting: ScreenPreventable, ScreenPreventerWindowConfiguring {
    @discardableResult
    func disablePreventScreenshot(for view: UIView) -> Bool
    @discardableResult
    func enablePreventScreenshot(for view: UIView) -> Bool
    @discardableResult
    func enabledPreventScreenshot(for view: UIView) -> Bool
    @discardableResult
    func suspendPreventScreenshotProtection() -> Bool
    func resumePreventScreenshotProtection()
}

internal final class ScreenPreventerAdapter: ScreenPreventerViewProtecting {
    private let screenPreventer: ScreenPreventer

    init(_ screenPreventer: ScreenPreventer) {
        self.screenPreventer = screenPreventer
    }

    var window: UIWindow? {
        get { screenPreventer.window }
        set { screenPreventer.window = newValue }
    }

    func screenIsRecording() -> Bool {
        screenPreventer.screenIsRecording()
    }

    func screenRecordObserver(using onScreenRecord: @escaping (Bool) -> Void) {
        screenPreventer.screenRecordObserver(using: onScreenRecord)
    }

    func screenshotObserver(using onScreenshot: @escaping () -> Void) {
        screenPreventer.screenshotObserver(using: onScreenshot)
    }

    func removeAllObserver() {
        screenPreventer.removeAllObserver()
    }

    func removeScreenRecordObserver() {
        screenPreventer.removeScreenRecordObserver()
    }

    func removeScreenshotObserver() {
        screenPreventer.removeScreenshotObserver()
    }

    func removeObserver(observer: (any NSObjectProtocol)?) {
        screenPreventer.removeObserver(observer: observer)
    }

    func disableImageScreen() {
        screenPreventer.disableImageScreen()
    }

    func enabledImageScreen(named: String) {
        screenPreventer.enabledImageScreen(named: named)
    }

    func disableColorScreen() {
        screenPreventer.disableColorScreen()
    }

    func enabledColorScreen(hexColor: String) {
        screenPreventer.enabledColorScreen(hexColor: hexColor)
    }

    func disableBlurScreen() {
        screenPreventer.disableBlurScreen()
    }

    func enabledBlurScreen(style: UIBlurEffect.Style) {
        screenPreventer.enabledBlurScreen(style: style)
    }

    func disablePreventScreenRecording() {
        screenPreventer.disablePreventScreenRecording()
    }

    func disablePreventScreenshot() {
        screenPreventer.disablePreventScreenshot()
    }

    @discardableResult
    func disablePreventScreenshot(for view: UIView) -> Bool {
        screenPreventer.disablePreventScreenshot(for: view)
    }

    func enablePreventScreenshot() {
        screenPreventer.enablePreventScreenshot()
    }

    @discardableResult
    func enablePreventScreenshot(for view: UIView) -> Bool {
        screenPreventer.enablePreventScreenshot(for: view)
    }

    func enabledPreventScreenRecording(text: String?, image: String?) {
        screenPreventer.enabledPreventScreenRecording(text: text, image: image)
    }

    func enabledPreventScreenshot(text: String?, image: String?) {
        screenPreventer.enabledPreventScreenshot(text: text, image: image)
    }

    @discardableResult
    func enabledPreventScreenshot(for view: UIView) -> Bool {
        screenPreventer.enabledPreventScreenshot(for: view)
    }

    func enabledBlurScreen() {
        screenPreventer.enabledBlurScreen()
    }

    func enabledPreventScreenshot() {
        screenPreventer.enabledPreventScreenshot()
    }

    func enabledPreventScreenRecording() {
        screenPreventer.enabledPreventScreenRecording()
    }

    @discardableResult
    func suspendPreventScreenshotProtection() -> Bool {
        screenPreventer.suspendPreventScreenshotProtection()
    }

    func resumePreventScreenshotProtection() {
        screenPreventer.resumePreventScreenshotProtection()
    }

    func setRootViewResolver(_ resolver: ScreenPreventerRootViewResolving) {
        screenPreventer.setRootViewResolver(resolver)
    }
}

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
    @discardableResult
    func disablePreventScreenshot(for view: UIView) -> Bool
    func enablePreventScreenshot()
    @discardableResult
    func enablePreventScreenshot(for view: UIView) -> Bool
    func enabledPreventScreenRecording(text: String?, image: String?)
    func enabledPreventScreenshot(text: String?, image: String?)
    @discardableResult
    func enabledPreventScreenshot(for view: UIView) -> Bool
    func enabledBlurScreen()
    func enabledPreventScreenshot()
    func enabledPreventScreenRecording()
    @discardableResult
    func suspendPreventScreenshotProtection() -> Bool
    func resumePreventScreenshotProtection()
    func setRootViewResolver(_ resolver: ScreenProtectorRootViewResolving)
    func setWindow(_ window: UIWindow?)
}

@objc(ScreenProtectorKit)
public class ScreenProtectorKit: NSObject, ScreenProtectable {
    public var window: UIWindow? = nil {
        didSet {
            guard !isUpdatingWindowReference else { return }
            let assignedWindow = window
            performOnMain {
                synchronizeAssignedWindow(assignedWindow, reapplyProtection: true)
            }
        }
    }

    private let screenPreventer: any ScreenPreventerViewProtecting
    private let initializeScreenPreventer: (UIView?) -> Void
    private let notificationCenter: NotificationCenter
    private let activeWindowResolver: () -> UIWindow?
    private var rootViewResolver: ScreenProtectorRootViewResolving?
    private var lifecycleObservers: [NSObjectProtocol] = []
    private var screenshotProtectionConfiguration: ScreenshotProtectionConfiguration = .disabled
    private var screenRecordingProtectionConfiguration: ScreenRecordingProtectionConfiguration = .disabled
    private var isScreenshotProtectionSuspended = false
    private var isUpdatingWindowReference = false
    private var pendingLifecycleSynchronization: DispatchWorkItem?
    private var pendingSecureTextFieldStyleRepair: DispatchWorkItem?
    private weak var initializedRootView: UIView?

    @objc
    public convenience init(window: UIWindow? = nil) {
        let screenPreventer = ScreenPreventer(window: window)
        self.init(
            window: window,
            screenPreventer: ScreenPreventerAdapter(screenPreventer),
            initializeScreenPreventer: ScreenPreventer.initial(with:),
            notificationCenter: .default,
            activeWindowResolver: ScreenProtectorKit.resolveCurrentWindow
        )
    }

    init(
        window: UIWindow? = nil,
        screenPreventer: any ScreenPreventerViewProtecting,
        initializeScreenPreventer: @escaping (UIView?) -> Void,
        notificationCenter: NotificationCenter = .default,
        activeWindowResolver: @escaping () -> UIWindow? = ScreenProtectorKit.resolveCurrentWindow
    ) {
        self.window = window
        self.screenPreventer = screenPreventer
        self.initializeScreenPreventer = initializeScreenPreventer
        self.notificationCenter = notificationCenter
        self.activeWindowResolver = activeWindowResolver
        super.init()
        registerLifecycleObservers()
        applyWindowReference(window, reapplyProtection: false)
    }

    deinit {
        pendingLifecycleSynchronization?.cancel()
        pendingSecureTextFieldStyleRepair?.cancel()
        for observer in lifecycleObservers {
            notificationCenter.removeObserver(observer)
        }
    }
    
    public static func initial(with view: UIView?) {
        performOnMain {
            ScreenPreventer.initial(with: view)
        }
    }
    
    @objc
    public func setWindow(_ window: UIWindow?) {
        performOnMain {
            self.window = window
        }
    }
    
    @available(*, deprecated, message: "This API will be removed in a future release due to crashes on some devices.")
    public func configurePreventionScreenshot() {}
    
    @objc
    public func enabledPreventScreenshot() {
        performOnMain {
            isScreenshotProtectionSuspended = false
            screenshotProtectionConfiguration = .enabled(text: nil, image: nil)
            screenPreventer.enabledPreventScreenshot()
            preventIOS16Crash()
        }
    }
    
    @objc
    public func enabledPreventScreenshot(text: String?, image: String?) {
        performOnMain {
            isScreenshotProtectionSuspended = false
            screenshotProtectionConfiguration = .enabled(text: text, image: image)
            screenPreventer.enabledPreventScreenshot(text: text, image: image)
            preventIOS16Crash()
        }
    }

    @objc(enabledPreventScreenshotForView:)
    @discardableResult
    public func enabledPreventScreenshot(for view: UIView) -> Bool {
        performOnMain {
            isScreenshotProtectionSuspended = false
            synchronizeProtectionTargetWindow(for: view)
            let didEnable = screenPreventer.enabledPreventScreenshot(for: view)
            if didEnable {
                screenshotProtectionConfiguration = .enabledForView(WeakViewReference(view: view))
                preventIOS16Crash()
            }
            return didEnable
        }
    }
    
    @objc
    public func disablePreventScreenshot() {
        performOnMain {
            isScreenshotProtectionSuspended = false
            screenshotProtectionConfiguration = .disabled
            screenPreventer.disablePreventScreenshot()
        }
    }

    @objc(disablePreventScreenshotForView:)
    @discardableResult
    public func disablePreventScreenshot(for view: UIView) -> Bool {
        performOnMain {
            let didDisable = screenPreventer.disablePreventScreenshot(for: view)
            if didDisable {
                isScreenshotProtectionSuspended = false
                screenshotProtectionConfiguration = .disabled
            }
            return didDisable
        }
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledBlurScreen()
    // }
    @objc
    public func enabledBlurScreen() {
        performOnMain {
            screenPreventer.enabledBlurScreen()
        }
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledBlurScreen(style: UIBlurEffect.Style.light)
    // }
    @objc
    public func enabledBlurScreen(style: UIBlurEffect.Style) {
        performOnMain {
            screenPreventer.enabledBlurScreen(style: style)
        }
    }
    
    // How to used:
    //
    // override func applicationDidBecomeActive(_ application: UIApplication) {
    //     screenProtectorKit.disableBlurScreen()
    // }
    @objc
    public func disableBlurScreen() {
        performOnMain {
            screenPreventer.disableBlurScreen()
        }
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledColorScreen(hexColor: "#ffffff")
    // }
    @objc
    public func enabledColorScreen(hexColor: String) {
        performOnMain {
            screenPreventer.enabledColorScreen(hexColor: hexColor)
        }
    }
    
    // How to used:
    //
    // override func applicationDidBecomeActive(_ application: UIApplication) {
    //     screenProtectorKit.disableColorScreen()
    // }
    @objc
    public func disableColorScreen() {
        performOnMain {
            screenPreventer.disableColorScreen()
        }
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledImageScreen(named: "LaunchImage")
    // }
    @objc
    public func enabledImageScreen(named: String) {
        performOnMain {
            screenPreventer.enabledImageScreen(named: named)
        }
    }
    
    // How to used:
    //
    // override func applicationDidBecomeActive(_ application: UIApplication) {
    //     screenProtectorKit.disableImageScreen()
    // }
    @objc
    public func disableImageScreen() {
        performOnMain {
            screenPreventer.disableImageScreen()
        }
    }
    
    // How to used:
    //
    // screenProtectorKit.removeObserver(observer: screenRecordObserve)
    @objc
    public func removeObserver(observer: NSObjectProtocol?) {
        performOnMain {
            screenPreventer.removeObserver(observer: observer)
        }
    }
    
    // How to used:
    //
    // screenProtectorKit.removeScreenshotObserver()
    @objc
    public func removeScreenshotObserver() {
        performOnMain {
            screenPreventer.removeScreenshotObserver()
        }
    }
    
    // How to used:
    //
    // screenProtectorKit.removeScreenRecordObserver()
    @objc
    public func removeScreenRecordObserver() {
        performOnMain {
            screenPreventer.removeScreenRecordObserver()
        }
    }
    
    // How to used:
    //
    // screenProtectorKit.removeAllObserver()
    @objc
    public func removeAllObserver() {
        performOnMain {
            screenPreventer.removeAllObserver()
        }
    }
    
    // How to used:
    //
    // screenProtectorKit.screenshotObserver {
    //      // Callback on Screenshot
    // }
    @objc
    public func screenshotObserver(using onScreenshot: @escaping () -> Void) {
        performOnMain {
            screenPreventer.screenshotObserver(using: onScreenshot)
        }
    }
    
    // How to used:
    //
    // if #available(iOS 11.0, *) {
    //     screenProtectorKit.screenRecordObserver { isCaptured in
    //         // Callback on Screen Record
    //     }
    // }
    @available(iOS 11.0, *)
    @objc
    public func screenRecordObserver(using onScreenRecord: @escaping (Bool) -> Void) {
        performOnMain {
            screenPreventer.screenRecordObserver(using: onScreenRecord)
        }
    }
    
    @available(iOS 11.0, *)
    @objc
    public func screenIsRecording() -> Bool {
        return performOnMain {
            screenPreventer.screenIsRecording()
        }
    }
    
    @objc
    public func disablePreventScreenRecording() {
        performOnMain {
            screenRecordingProtectionConfiguration = .disabled
            screenPreventer.disablePreventScreenRecording()
        }
    }
    
    @objc
    public func enablePreventScreenshot() {
        performOnMain {
            isScreenshotProtectionSuspended = false
            screenshotProtectionConfiguration = .enableOnly
            screenPreventer.enablePreventScreenshot()
            preventIOS16Crash()
        }
    }

    @objc(enablePreventScreenshotForView:)
    @discardableResult
    public func enablePreventScreenshot(for view: UIView) -> Bool {
        performOnMain {
            isScreenshotProtectionSuspended = false
            synchronizeProtectionTargetWindow(for: view)
            let didEnable = screenPreventer.enablePreventScreenshot(for: view)
            if didEnable {
                screenshotProtectionConfiguration = .enableOnlyForView(WeakViewReference(view: view))
                preventIOS16Crash()
            }
            return didEnable
        }
    }
    
    @objc
    public func enabledPreventScreenRecording() {
        performOnMain {
            screenRecordingProtectionConfiguration = .enabled(text: nil, image: nil)
            screenPreventer.enabledPreventScreenRecording()
            preventIOS16Crash()
        }
    }
    
    @objc
    public func enabledPreventScreenRecording(text: String?, image: String?) {
        performOnMain {
            screenRecordingProtectionConfiguration = .enabled(text: text, image: image)
            screenPreventer.enabledPreventScreenRecording(text: text, image: image)
            preventIOS16Crash()
        }
    }
    
    public func setRootViewResolver(_ resolver: ScreenProtectorRootViewResolving) {
        performOnMain {
            rootViewResolver = resolver
            screenPreventer.setRootViewResolver(
                ClosureRootViewResolver(resolver)
            )
            refreshProtectedRootView(reapplyProtection: true)
        }
    }

    @objc
    @discardableResult
    public func suspendPreventScreenshotProtection() -> Bool {
        performOnMain {
            let didSuspend = screenPreventer.suspendPreventScreenshotProtection()
            if didSuspend {
                isScreenshotProtectionSuspended = true
            }
            return didSuspend
        }
    }

    @objc
    public func resumePreventScreenshotProtection() {
        performOnMain {
            screenPreventer.resumePreventScreenshotProtection()
            isScreenshotProtectionSuspended = false
        }
    }

    private func synchronizeProtectionTargetWindow(for view: UIView) {
        guard let targetWindow = view.window else { return }

        if targetWindow !== window {
            setWindowSilently(targetWindow)
        }
        screenPreventer.window = targetWindow
    }

    private func preventIOS16Crash() {
        if #available(iOS 16.0, *) {
            pendingSecureTextFieldStyleRepair?.cancel()
            let repairWorkItem = DispatchWorkItem {
                for window in ScreenProtectorKit.resolveAllWindows() {
                    ScreenProtectorKit.applyOverrideUserInterfaceStyle(to: window)
                }
            }
            pendingSecureTextFieldStyleRepair = repairWorkItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: repairWorkItem)
        }
    }
    
    @available(iOS 13.0, *)
    private static func applyOverrideUserInterfaceStyle(to view: UIView) {
        if let textField = view as? UITextField, textField.isSecureTextEntry {
            textField.overrideUserInterfaceStyle = .light
        }
        for subview in view.subviews {
            applyOverrideUserInterfaceStyle(to: subview)
        }
    }

    private func registerLifecycleObservers() {
        lifecycleObservers.append(
            notificationCenter.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.scheduleActiveWindowSynchronization()
            }
        )
        lifecycleObservers.append(
            notificationCenter.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.scheduleActiveWindowSynchronization()
            }
        )
        lifecycleObservers.append(
            notificationCenter.addObserver(
                forName: UIContentSizeCategory.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.scheduleActiveWindowSynchronization()
            }
        )
        if #available(iOS 13.0, *) {
            lifecycleObservers.append(
                notificationCenter.addObserver(
                    forName: UIScene.didActivateNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    self?.scheduleActiveWindowSynchronization()
                }
            )
        }
    }

    private func scheduleActiveWindowSynchronization() {
        pendingLifecycleSynchronization?.cancel()
        let synchronizationWorkItem = DispatchWorkItem { [weak self] in
            self?.pendingLifecycleSynchronization = nil
            self?.synchronizeActiveWindow()
        }
        pendingLifecycleSynchronization = synchronizationWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: synchronizationWorkItem)
    }

    private func synchronizeAssignedWindow(_ window: UIWindow?, reapplyProtection: Bool) {
        if Thread.isMainThread {
            applyWindowReference(window, reapplyProtection: reapplyProtection)
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.applyWindowReference(window, reapplyProtection: reapplyProtection)
        }
    }

    private func synchronizeActiveWindow() {
        let resolvedWindow = resolveWindowForLifecycleSync()
        if resolvedWindow !== window {
            setWindowSilently(resolvedWindow)
        }
        applyWindowReference(resolvedWindow, reapplyProtection: true)
    }

    private func resolveWindowForLifecycleSync() -> UIWindow? {
        if Self.isUsableProtectionWindow(window) {
            return window
        }

        return activeWindowResolver() ?? window
    }

    private static func performOnMain<T>(_ work: () -> T) -> T {
        if Thread.isMainThread {
            return work()
        }

        return DispatchQueue.main.sync(execute: work)
    }

    private func performOnMain<T>(_ work: () -> T) -> T {
        Self.performOnMain(work)
    }

    private func setWindowSilently(_ window: UIWindow?) {
        isUpdatingWindowReference = true
        self.window = window
        isUpdatingWindowReference = false
    }

    private func applyWindowReference(_ window: UIWindow?, reapplyProtection: Bool) {
        screenPreventer.window = window
        refreshProtectedRootView(reapplyProtection: reapplyProtection)
    }

    private func refreshProtectedRootView(reapplyProtection: Bool) {
        initializeScreenPreventerIfNeeded(with: resolveRootView())
        if reapplyProtection {
            reapplyProtectionIfNeeded()
        }
    }

    private func initializeScreenPreventerIfNeeded(with rootView: UIView?) {
        guard let rootView else { return }
        guard initializedRootView !== rootView else { return }

        initializedRootView = rootView
        initializeScreenPreventer(rootView)
    }

    private func resolveRootView() -> UIView? {
        if let protectedView = screenshotProtectionConfiguration.protectedView {
            return protectedView
        }
        if let rootViewResolver {
            return rootViewResolver.resolveRootView()
        }
        return window?.rootViewController?.view ?? Self.resolveCurrentWindow()?.rootViewController?.view
    }

    private func reapplyProtectionIfNeeded() {
        if !isScreenshotProtectionSuspended {
            switch screenshotProtectionConfiguration {
            case .disabled:
                break
            case .enableOnly:
                screenPreventer.enablePreventScreenshot()
                preventIOS16Crash()
            case let .enableOnlyForView(viewReference):
                if let view = viewReference.view {
                    screenPreventer.enablePreventScreenshot(for: view)
                    preventIOS16Crash()
                }
            case let .enabled(text, image):
                if text != nil || image != nil {
                    screenPreventer.enabledPreventScreenshot(text: text, image: image)
                } else {
                    screenPreventer.enabledPreventScreenshot()
                }
                preventIOS16Crash()
            case let .enabledForView(viewReference):
                if let view = viewReference.view {
                    screenPreventer.enabledPreventScreenshot(for: view)
                    preventIOS16Crash()
                }
            }
        }

        switch screenRecordingProtectionConfiguration {
        case .disabled:
            break
        case let .enabled(text, image):
            if text != nil || image != nil {
                screenPreventer.enabledPreventScreenRecording(text: text, image: image)
            } else {
                screenPreventer.enabledPreventScreenRecording()
            }
            preventIOS16Crash()
        }
    }

    private static func resolveCurrentWindow() -> UIWindow? {
        let activeWindows = resolveAllWindows()

        if let keyWindow = activeWindows.first(where: \.isKeyWindow) {
            return keyWindow
        }

        return activeWindows.first(where: { !$0.isHidden && $0.rootViewController != nil })
    }

    private static func resolveAllWindows() -> [UIWindow] {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
                .flatMap(\.windows)
        }

        if #available(iOS 15.0, *) {
            return []
        } else {
            return UIApplication.shared.windows
        }
    }

    private static func isUsableProtectionWindow(_ window: UIWindow?) -> Bool {
        guard let window, !window.isHidden, window.rootViewController != nil else {
            return false
        }

        if #available(iOS 13.0, *) {
            guard let windowScene = window.windowScene else {
                return true
            }

            return windowScene.activationState == .foregroundActive || windowScene.activationState == .foregroundInactive
        }

        return true
    }
}

internal enum ScreenshotProtectionConfiguration {
    case disabled
    case enableOnly
    case enableOnlyForView(WeakViewReference)
    case enabled(text: String?, image: String?)
    case enabledForView(WeakViewReference)

    var protectedView: UIView? {
        switch self {
        case let .enableOnlyForView(viewReference), let .enabledForView(viewReference):
            return viewReference.view
        case .disabled, .enableOnly, .enabled:
            return nil
        }
    }
}

internal enum ScreenRecordingProtectionConfiguration: Equatable {
    case disabled
    case enabled(text: String?, image: String?)
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

internal final class WeakViewReference {
    weak var view: UIView?

    init(view: UIView?) {
        self.view = view
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, *)
public extension ScreenProtectorKit {
    func protectedView<Content: View>(
        isProtected: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ScreenPreventerProtectedHostingView(
            isProtected: isProtected,
            protectionOwner: self,
            setWindow: { [weak self] window in
                self?.setWindow(window)
            },
            enableProtection: { [weak self] view in
                self?.enabledPreventScreenshot(for: view) ?? false
            },
            disableProtection: { [weak self] view in
                self?.disablePreventScreenshot(for: view) ?? false
            },
            content: content
        )
    }
}
#endif
