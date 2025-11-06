//
//  ScreenProtectorKitManager.swift
//  ScreenProtectorKit
//
//  Created by INTENIQUETIC on 16/10/2568 BE.
//

import UIKit

private func onMain(_ work: @escaping () -> Void) {
    if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
}

public enum ProtectionState {
    case idle
    case on
    case off
}

public enum ListenerStatus: String, Equatable {
    case listened
    case removed
    case unsupported
}

public enum ListenerEvent: Equatable {
    case screenshot
    case screenRecording
}

public enum ListenerPayload: Equatable {
    case screenshot
    case screenRecording(Bool)
}

// Protection modes to prevent data leakage
public enum ProtectionMode: Equatable {
    case none
    case blur
    case image(name: String)
    case color(hex: String)
}

public protocol ScreenProtectorKitManaging: AnyObject {
    func applicationWillResignActive(_ application: UIApplication)
    func applicationDidBecomeActive(_ application: UIApplication)
    
    func enableScreenshotPrevention() -> Bool
    func disableScreenshotPrevention() -> Bool
    
    func isScreenRecording() -> Bool
    
    @discardableResult
    func setListener(for event: ListenerEvent, using handler: @escaping (ListenerPayload) -> Void) -> ListenerStatus
    
    @discardableResult
    func removeListener(for event: ListenerEvent) -> ListenerStatus
    
    @discardableResult
    func removeListeners() -> ListenerStatus
    
    @discardableResult
    func enableProtectionMode(_ mode: ProtectionMode) -> Bool
    
    @discardableResult
    func disableProtectionMode(_ mode: ProtectionMode) -> Bool
}

public final class ScreenProtectorKitManager: ScreenProtectorKitManaging {
    public init() {}
    
    private let syncQueue = DispatchQueue(label: "com.screenprotector.kit.manager.sync", attributes: .concurrent)
    
    private var _preventScreenshotState: ProtectionState = .idle
    private var _blurProtectionState: ProtectionState = .idle
    private var _imageProtectionState: ProtectionState = .idle
    private var _colorProtectionState: ProtectionState = .idle
    private var _imageProtectionName: String = ""
    private var _colorProtectionHex: String = ""
    
    private var preventScreenshotState: ProtectionState { syncQueue.sync { _preventScreenshotState } }
    private var blurProtectionState: ProtectionState { syncQueue.sync { _blurProtectionState } }
    private var imageProtectionState: ProtectionState { syncQueue.sync { _imageProtectionState } }
    private var colorProtectionState: ProtectionState { syncQueue.sync { _colorProtectionState } }
    private var imageProtectionName: String { syncQueue.sync { _imageProtectionName } }
    private var colorProtectionHex: String { syncQueue.sync { _colorProtectionHex } }
    
    private var _screenProtectorKit: ScreenProtectorKit?
    
    /// Safe creation of ScreenProtectorKit (guarded from early launch crash)
    private func getScreenProtectorKit() -> ScreenProtectorKit? {
        // Prevent creation before any window is visible (fix for iOS 18 recursive crash)
        guard UIApplication.shared.applicationState != .background else { return nil }
        
        // Fast path read
        if let existing = syncQueue.sync(execute: { _screenProtectorKit }) { return existing }
        
        // Slow path create (thread-safe)
        return syncQueue.sync(flags: .barrier) {
            if let existing = _screenProtectorKit { return existing }
            guard let window = safeGetKeyWindow() else { return nil }
            let instance = ScreenProtectorKit(window: window)
            onMain { instance.configurePreventionScreenshot() }
            _screenProtectorKit = instance
            return instance
        }
    }
    
    /// Main-thread-safe way to retrieve key window (fix for async nil issue)
    private func safeGetKeyWindow() -> UIWindow? {
        if Thread.isMainThread { return getKeyWindow() }
        var window: UIWindow?
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            window = self.getKeyWindow()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 0.2) // wait up to 0.2 s
        return window
    }
    
    private func getKeyWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: \.isKeyWindow)
        } else if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    
    // MARK: - ScreenProtectorKitManaging
    public func applicationWillResignActive(_ application: UIApplication) {
        // Protect Data Leakage - ON
        if colorProtectionState == .on {
            onMain { self.getScreenProtectorKit()?.enabledColorScreen(hexColor: self.colorProtectionHex) }
        } else if imageProtectionState == .on {
            onMain { self.getScreenProtectorKit()?.enabledImageScreen(named: self.imageProtectionName) }
        } else if blurProtectionState == .on {
            onMain { self.getScreenProtectorKit()?.enabledBlurScreen() }
        }
        
        // Prevent Screenshot - OFF
        if preventScreenshotState == .off {
            onMain { self.getScreenProtectorKit()?.disablePreventScreenshot() }
        }
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        // Protect Data Leakage - OFF
        if colorProtectionState == .on {
            onMain { self.getScreenProtectorKit()?.disableColorScreen() }
        } else if imageProtectionState == .on {
            onMain { self.getScreenProtectorKit()?.disableImageScreen() }
        } else if blurProtectionState == .on {
            onMain { self.getScreenProtectorKit()?.disableBlurScreen() }
        }
        
        // Prevent Screenshot - ON
        if preventScreenshotState == .on {
            onMain { self.getScreenProtectorKit()?.enabledPreventScreenshot() }
        }
    }
    
    public func disableAllProtection() -> Bool {
        syncQueue.async(flags: .barrier) { self._colorProtectionState = .off }
        syncQueue.async(flags: .barrier) { self._imageProtectionState = .off }
        syncQueue.async(flags: .barrier) { self._blurProtectionState = .off }
        onMain { self.getScreenProtectorKit()?.disableColorScreen() }
        onMain { self.getScreenProtectorKit()?.disableImageScreen() }
        onMain { self.getScreenProtectorKit()?.disableBlurScreen() }
        return true
    }
    
    public func enableScreenshotPrevention() -> Bool {
        syncQueue.async(flags: .barrier) { self._preventScreenshotState = .on }
        onMain { self.getScreenProtectorKit()?.enabledPreventScreenshot() }
        return true
    }
    
    public func disableScreenshotPrevention() -> Bool {
        syncQueue.async(flags: .barrier) { self._preventScreenshotState = .off }
        onMain { self.getScreenProtectorKit()?.disablePreventScreenshot() }
        return true
    }
    
    public func isScreenRecording() -> Bool {
        return getScreenProtectorKit()?.screenIsRecording() ?? false
    }
    
    @discardableResult
    public func setListener(for event: ListenerEvent, using handler: @escaping (ListenerPayload) -> Void) -> ListenerStatus {
        switch event {
        case .screenshot:
            onMain { self.getScreenProtectorKit()?.removeScreenshotObserver() }
            onMain { self.getScreenProtectorKit()?.screenshotObserver(using: { handler(.screenshot) }) }
            return .listened
        case .screenRecording:
            if #available(iOS 11.0, *) {
                onMain { self.getScreenProtectorKit()?.removeScreenRecordObserver() }
                onMain { self.getScreenProtectorKit()?.screenRecordObserver(using: { isRecording in
                    handler(.screenRecording(isRecording))
                }) }
                return .listened
            } else {
                return .unsupported
            }
        }
    }
    
    @discardableResult
    public func removeListener(for event: ListenerEvent) -> ListenerStatus {
        switch event {
        case .screenshot:
            onMain { self.getScreenProtectorKit()?.removeScreenshotObserver() }
            return .removed
        case .screenRecording:
            onMain { self.getScreenProtectorKit()?.removeScreenRecordObserver() }
            return .removed
        }
    }
    
    @discardableResult
    public func removeListeners() -> ListenerStatus {
        onMain { self.getScreenProtectorKit()?.removeAllObserver() }
        return .removed
    }
    
    @discardableResult
    public func removeAllListeners() -> ListenerStatus {
        onMain { self.getScreenProtectorKit()?.removeAllObserver() }
        return .removed
    }
    
    @discardableResult
    public func enableProtectionMode(_ mode: ProtectionMode) -> Bool {
        switch mode {
        case .none:
            return disableAllProtection()
        case .blur:
            syncQueue.async(flags: .barrier) { self._blurProtectionState = .on }
            return true
        case .image(let name):
            syncQueue.async(flags: .barrier) { self._imageProtectionName = name }
            syncQueue.async(flags: .barrier) { self._imageProtectionState = .on }
            return true
        case .color(let hex):
            syncQueue.async(flags: .barrier) { self._colorProtectionHex = hex }
            syncQueue.async(flags: .barrier) { self._colorProtectionState = .on }
            return true
        }
    }
    
    @discardableResult
    public func disableProtectionMode(_ mode: ProtectionMode) -> Bool {
        switch mode {
        case .none:
            return disableAllProtection()
        case .blur:
            syncQueue.async(flags: .barrier) { self._blurProtectionState = .off }
            onMain { self.getScreenProtectorKit()?.disableBlurScreen() }
            return true
        case .image:
            syncQueue.async(flags: .barrier) { self._imageProtectionState = .off }
            onMain { self.getScreenProtectorKit()?.disableImageScreen() }
            return true
        case .color:
            syncQueue.async(flags: .barrier) { self._colorProtectionState = .off }
            onMain { self.getScreenProtectorKit()?.disableColorScreen() }
            return true
        }
    }
}
