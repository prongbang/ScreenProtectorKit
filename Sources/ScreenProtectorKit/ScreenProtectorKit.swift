//
//  ScreenProtectorKit.swift
//  Runner
//
//  Created by prongbang on 19/2/2565 BE.
//

import UIKit

//  How to used:
//
//  @UIApplicationMain
//  @objc class AppDelegate: FlutterAppDelegate {
//
//      private lazy var screenProtectorKit = { return ScreenProtectorKit(window: window) }()
//
//  }
public class ScreenProtectorKit {
    
    private var window: UIWindow? = nil
    private var screenImage: UIImageView? = nil
    private var screenBlur: UIView? = nil
    private var screenColor: UIView? = nil
    private var screenPrevent = UITextField()
    
    public init(window: UIWindow?) {
        self.window = window
    }
    
    //  How to used:
    //
    //  override func application(
    //      _ application: UIApplication,
    //      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    //  ) -> Bool {
    //
    //      screenProtectorKit.configurePreventionScreenshot()
    //
    //      return true
    //  }
    public func configurePreventionScreenshot() {
        guard let w = window else { return }
        
        if (!w.subviews.contains(screenPrevent)) {
            w.addSubview(screenPrevent)
            screenPrevent.centerYAnchor.constraint(equalTo: w.centerYAnchor).isActive = true
            screenPrevent.centerXAnchor.constraint(equalTo: w.centerXAnchor).isActive = true
            w.layer.superlayer?.addSublayer(screenPrevent.layer)
            screenPrevent.layer.sublayers?.first?.addSublayer(w.layer)
        }
    }
    
    // How to used:
    //
    // override func applicationDidBecomeActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledPreventScreenshot()
    // }
    public func enabledPreventScreenshot() {
        screenPrevent.isSecureTextEntry = true
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.disablePreventScreenshot()
    // }
    public func disablePreventScreenshot() {
        screenPrevent.isSecureTextEntry = false
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledBlurScreen()
    // }
    public func enabledBlurScreen(style: UIBlurEffect.Style = UIBlurEffect.Style.light) {
        screenBlur = UIScreen.main.snapshotView(afterScreenUpdates: false)
        let blurEffect = UIBlurEffect(style: style)
        let blurBackground = UIVisualEffectView(effect: blurEffect)
        screenBlur?.addSubview(blurBackground)
        blurBackground.frame = (screenBlur?.frame)!
        window?.addSubview(screenBlur!)
    }
    
    // How to used:
    //
    // override func applicationDidBecomeActive(_ application: UIApplication) {
    //     screenProtectorKit.disableBlurScreen()
    // }
    public func disableBlurScreen() {
        screenBlur?.removeFromSuperview()
        screenBlur = nil
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledColorScreen(hexColor: "#ffffff")
    // }
    public func enabledColorScreen(hexColor: String) {
        guard let w = window else { return }
        screenColor = UIView(frame: w.bounds)
        guard let view = screenColor else { return }
        view.backgroundColor = UIColor(hexString: hexColor)
        w.addSubview(view)
    }
    
    // How to used:
    //
    // override func applicationDidBecomeActive(_ application: UIApplication) {
    //     screenProtectorKit.disableColorScreen()
    // }
    public func disableColorScreen() {
        screenColor?.removeFromSuperview()
        screenColor = nil
    }
    
    // How to used:
    //
    // override func applicationWillResignActive(_ application: UIApplication) {
    //     screenProtectorKit.enabledImageScreen(named: "LaunchImage")
    // }
    public func enabledImageScreen(named: String) {
        screenImage = UIImageView(frame: UIScreen.main.bounds)
        screenImage?.image = UIImage(named: named)
        screenImage?.isUserInteractionEnabled = false
        screenImage?.contentMode = .scaleAspectFill;
        screenImage?.clipsToBounds = true;
        window?.addSubview(screenImage!)
    }
    
    // How to used:
    //
    // override func applicationDidBecomeActive(_ application: UIApplication) {
    //     screenProtectorKit.disableImageScreen()
    // }
    public func disableImageScreen() {
        screenImage?.removeFromSuperview()
        screenImage = nil
    }
}
