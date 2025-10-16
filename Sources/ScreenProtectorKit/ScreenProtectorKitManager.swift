//
//  ScreenProtectorKitManager.swift
//  ScreenProtectorKit
//
//  Created by INTENIQUETIC on 16/10/2568 BE.
//

import UIKit

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
    
    private var preventScreenshotState: ProtectionState = .idle
    private var blurProtectionState: ProtectionState = .idle
    private var imageProtectionState: ProtectionState = .idle
    private var colorProtectionState: ProtectionState = .idle
    private var imageProtectionName: String = ""
    private var colorProtectionHex: String = ""
    
    private lazy var screenProtectorKit: ScreenProtectorKit? = {
        guard let window = getKeyWindow() else { return nil }
        let instance = ScreenProtectorKit(window: window)
        instance.configurePreventionScreenshot()
        return instance
    }()
    
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
            screenProtectorKit?.enabledColorScreen(hexColor: colorProtectionHex)
        } else if imageProtectionState == .on {
            screenProtectorKit?.enabledImageScreen(named: imageProtectionName)
        } else if blurProtectionState == .on {
            screenProtectorKit?.enabledBlurScreen()
        }
        
        // Prevent Screenshot - OFF
        if preventScreenshotState == .off {
            screenProtectorKit?.disablePreventScreenshot()
        }
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        // Protect Data Leakage - OFF
        if colorProtectionState == .on {
            screenProtectorKit?.disableColorScreen()
        } else if imageProtectionState == .on {
            screenProtectorKit?.disableImageScreen()
        } else if blurProtectionState == .on {
            screenProtectorKit?.disableBlurScreen()
        }
        
        // Prevent Screenshot - ON
        if preventScreenshotState == .on {
            screenProtectorKit?.enabledPreventScreenshot()
        }
    }
    
    public func disableAllProtection() -> Bool {
        colorProtectionState = .off
        imageProtectionState = .off
        blurProtectionState = .off
        screenProtectorKit?.disableColorScreen()
        screenProtectorKit?.disableImageScreen()
        screenProtectorKit?.disableBlurScreen()
        return true
    }
    
    public func enableScreenshotPrevention() -> Bool {
        preventScreenshotState = .on
        screenProtectorKit?.enabledPreventScreenshot()
        return true
    }
    
    public func disableScreenshotPrevention() -> Bool {
        preventScreenshotState = .off
        screenProtectorKit?.disablePreventScreenshot()
        return true
    }
    
    public func isScreenRecording() -> Bool {
        return screenProtectorKit?.screenIsRecording() ?? false
    }
    
    @discardableResult
    public func setListener(for event: ListenerEvent, using handler: @escaping (ListenerPayload) -> Void) -> ListenerStatus {
        switch event {
        case .screenshot:
            screenProtectorKit?.removeScreenshotObserver()
            screenProtectorKit?.screenshotObserver(using: { handler(.screenshot) })
            return .listened
        case .screenRecording:
            if #available(iOS 11.0, *) {
                screenProtectorKit?.removeScreenRecordObserver()
                screenProtectorKit?.screenRecordObserver(using: { isRecording in
                    handler(.screenRecording(isRecording))
                })
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
            screenProtectorKit?.removeScreenshotObserver()
            return .removed
        case .screenRecording:
            screenProtectorKit?.removeScreenRecordObserver()
            return .removed
        }
    }
    
    @discardableResult
    public func removeListeners() -> ListenerStatus {
        screenProtectorKit?.removeAllObserver()
        return .removed
    }
    
    @discardableResult
    public func removeAllListeners() -> ListenerStatus {
        screenProtectorKit?.removeAllObserver()
        return .removed
    }
    
    @discardableResult
    public func enableProtectionMode(_ mode: ProtectionMode) -> Bool {
        switch mode {
        case .none:
            return disableAllProtection()
        case .blur:
            blurProtectionState = .on
            return true
        case .image(let name):
            imageProtectionName = name
            imageProtectionState = .on
            return true
        case .color(let hex):
            colorProtectionHex = hex
            colorProtectionState = .on
            return true
        }
    }
    
    @discardableResult
    public func disableProtectionMode(_ mode: ProtectionMode) -> Bool {
        switch mode {
        case .none:
            return disableAllProtection()
        case .blur:
            blurProtectionState = .off
            screenProtectorKit?.disableBlurScreen()
            return true
        case .image:
            imageProtectionState = .off
            screenProtectorKit?.disableImageScreen()
            return true
        case .color:
            colorProtectionState = .off
            screenProtectorKit?.disableColorScreen()
            return true
        }
    }
}
