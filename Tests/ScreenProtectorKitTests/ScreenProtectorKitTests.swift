import UIKit
import XCTest
import ScreenPreventerKit
@testable import ScreenProtectorKit

@MainActor
final class ScreenProtectorKitTests: XCTestCase {
    func testWindowMutationSynchronizesUnderlyingPreventerAndReappliesScreenshotProtection() {
        let notificationCenter = NotificationCenter()
        let screenPreventer = ScreenPreventerSpy()
        let recorder = InitialViewRecorder()
        let firstWindow = makeWindow()
        let secondWindow = makeWindow()
        let kit = ScreenProtectorKit(
            window: firstWindow,
            screenPreventer: screenPreventer,
            initializeScreenPreventer: recorder.record(view:),
            notificationCenter: notificationCenter
        )

        XCTAssertTrue(screenPreventer.window === firstWindow)
        XCTAssertTrue(recorder.lastView === firstWindow.rootViewController?.view)

        kit.enabledPreventScreenshot()
        kit.window = secondWindow

        XCTAssertTrue(screenPreventer.window === secondWindow)
        XCTAssertTrue(recorder.lastView === secondWindow.rootViewController?.view)
        XCTAssertEqual(screenPreventer.enabledPreventScreenshotCallCount, 2)
    }

    func testDidBecomeActiveReappliesConfiguredProtectionWithResolverView() {
        let notificationCenter = NotificationCenter()
        let screenPreventer = ScreenPreventerSpy()
        let recorder = InitialViewRecorder()
        let window = makeWindow()
        let resolverView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let kit = ScreenProtectorKit(
            window: window,
            screenPreventer: screenPreventer,
            initializeScreenPreventer: recorder.record(view:),
            notificationCenter: notificationCenter
        )

        kit.setRootViewResolver(TestRootViewResolver(view: resolverView))
        kit.enablePreventScreenshot()
        kit.enabledPreventScreenRecording(text: "Sensitive", image: "shield")

        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        waitForLifecycleSynchronization()

        XCTAssertTrue(recorder.lastView === resolverView)
        XCTAssertEqual(screenPreventer.enablePreventScreenshotCallCount, 2)
        XCTAssertEqual(screenPreventer.enabledPreventScreenRecordingWithContentCallCount, 2)
        XCTAssertEqual(screenPreventer.lastScreenRecordingText, "Sensitive")
        XCTAssertEqual(screenPreventer.lastScreenRecordingImage, "shield")
    }

    func testEnabledPreventScreenshotForViewDelegatesToScreenPreventerViewAPI() {
        let notificationCenter = NotificationCenter()
        let screenPreventer = ScreenPreventerSpy()
        let recorder = InitialViewRecorder()
        let window = makeWindow()
        let sensitiveView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        window.rootViewController?.view.addSubview(sensitiveView)
        let kit = ScreenProtectorKit(
            window: window,
            screenPreventer: screenPreventer,
            initializeScreenPreventer: recorder.record(view:),
            notificationCenter: notificationCenter
        )

        XCTAssertTrue(kit.enabledPreventScreenshot(for: sensitiveView))
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        waitForLifecycleSynchronization()

        XCTAssertTrue(screenPreventer.window === window)
        XCTAssertTrue(recorder.lastView === sensitiveView)
        XCTAssertTrue(screenPreventer.lastEnabledPreventScreenshotView === sensitiveView)
        XCTAssertNil(screenPreventer.rootViewResolver)
        XCTAssertEqual(screenPreventer.enabledPreventScreenshotForViewCallCount, 2)
        XCTAssertEqual(screenPreventer.enabledPreventScreenshotCallCount, 0)
    }

    func testDisablePreventScreenshotForViewDelegatesToScreenPreventerViewAPI() {
        let notificationCenter = NotificationCenter()
        let screenPreventer = ScreenPreventerSpy()
        let recorder = InitialViewRecorder()
        let window = makeWindow()
        let sensitiveView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        let otherView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        window.rootViewController?.view.addSubview(sensitiveView)
        window.rootViewController?.view.addSubview(otherView)
        let kit = ScreenProtectorKit(
            window: window,
            screenPreventer: screenPreventer,
            initializeScreenPreventer: recorder.record(view:),
            notificationCenter: notificationCenter
        )

        XCTAssertTrue(kit.enabledPreventScreenshot(for: sensitiveView))
        XCTAssertFalse(kit.disablePreventScreenshot(for: otherView))

        XCTAssertEqual(screenPreventer.disablePreventScreenshotForViewCallCount, 1)
        XCTAssertEqual(screenPreventer.disablePreventScreenshotCallCount, 0)

        XCTAssertTrue(kit.disablePreventScreenshot(for: sensitiveView))
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        waitForLifecycleSynchronization()

        XCTAssertEqual(screenPreventer.disablePreventScreenshotForViewCallCount, 2)
        XCTAssertEqual(screenPreventer.disablePreventScreenshotCallCount, 0)
        XCTAssertEqual(screenPreventer.enabledPreventScreenshotForViewCallCount, 1)
    }

    func testDidBecomeActiveKeepsAssignedWindowWhenGlobalResolverReturnsDifferentWindow() {
        let notificationCenter = NotificationCenter()
        let screenPreventer = ScreenPreventerSpy()
        let recorder = InitialViewRecorder()
        let assignedWindow = makeWindow()
        let otherActiveWindow = makeWindow()
        let kit = ScreenProtectorKit(
            window: assignedWindow,
            screenPreventer: screenPreventer,
            initializeScreenPreventer: recorder.record(view:),
            notificationCenter: notificationCenter,
            activeWindowResolver: { otherActiveWindow }
        )

        kit.enabledPreventScreenshot()
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        waitForLifecycleSynchronization()

        XCTAssertTrue(kit.window === assignedWindow)
        XCTAssertTrue(screenPreventer.window === assignedWindow)
        XCTAssertTrue(recorder.lastView === assignedWindow.rootViewController?.view)
        XCTAssertEqual(screenPreventer.enabledPreventScreenshotCallCount, 2)
    }

    func testContentSizeCategoryChangeAndDidBecomeActiveAreCoalescedBeforeReapplyingProtection() {
        let notificationCenter = NotificationCenter()
        let screenPreventer = ScreenPreventerSpy()
        let recorder = InitialViewRecorder()
        let window = makeWindow()
        let kit = ScreenProtectorKit(
            window: window,
            screenPreventer: screenPreventer,
            initializeScreenPreventer: recorder.record(view:),
            notificationCenter: notificationCenter
        )

        kit.enabledPreventScreenshot()
        notificationCenter.post(name: UIContentSizeCategory.didChangeNotification, object: nil)
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        waitForLifecycleSynchronization()

        XCTAssertTrue(screenPreventer.window === window)
        XCTAssertTrue(recorder.lastView === window.rootViewController?.view)
        XCTAssertEqual(screenPreventer.enabledPreventScreenshotCallCount, 2)
    }

    func testRepeatedWindowSynchronizationDoesNotInitializeSameRootViewAgain() {
        let notificationCenter = NotificationCenter()
        let screenPreventer = ScreenPreventerSpy()
        let recorder = InitialViewRecorder()
        let window = makeWindow()
        let kit = ScreenProtectorKit(
            window: window,
            screenPreventer: screenPreventer,
            initializeScreenPreventer: recorder.record(view:),
            notificationCenter: notificationCenter
        )

        XCTAssertEqual(recorder.callCount, 1)

        kit.setWindow(window)
        kit.enabledPreventScreenshot()
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        waitForLifecycleSynchronization()

        XCTAssertTrue(recorder.lastView === window.rootViewController?.view)
        XCTAssertEqual(recorder.callCount, 1)
        XCTAssertEqual(screenPreventer.enabledPreventScreenshotCallCount, 2)
    }

    func testPublicProtectionAPIsCalledFromBackgroundQueueRunOnMainThread() {
        let notificationCenter = NotificationCenter()
        let screenPreventer = ScreenPreventerSpy()
        let recorder = InitialViewRecorder()
        let window = makeWindow()
        let sensitiveView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        window.rootViewController?.view.addSubview(sensitiveView)
        let kit = ScreenProtectorKit(
            window: window,
            screenPreventer: screenPreventer,
            initializeScreenPreventer: recorder.record(view:),
            notificationCenter: notificationCenter
        )
        let expectation = expectation(description: "background API call completed")
        var didEnable = false

        DispatchQueue.global(qos: .userInitiated).async {
            let backgroundEnableResult = kit.enablePreventScreenshot(for: sensitiveView)
            kit.enabledPreventScreenRecording()
            DispatchQueue.main.async {
                didEnable = backgroundEnableResult
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(didEnable)
        XCTAssertTrue(screenPreventer.enablePreventScreenshotForViewCalledOnMainThread)
        XCTAssertTrue(screenPreventer.enabledPreventScreenRecordingCalledOnMainThread)
    }

    func testEnablePreventScreenshotForViewDelegatesToScreenPreventerViewAPI() {
        let notificationCenter = NotificationCenter()
        let screenPreventer = ScreenPreventerSpy()
        let recorder = InitialViewRecorder()
        let window = makeWindow()
        let sensitiveView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        window.rootViewController?.view.addSubview(sensitiveView)
        let kit = ScreenProtectorKit(
            window: window,
            screenPreventer: screenPreventer,
            initializeScreenPreventer: recorder.record(view:),
            notificationCenter: notificationCenter
        )

        XCTAssertTrue(kit.enablePreventScreenshot(for: sensitiveView))
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        waitForLifecycleSynchronization()

        XCTAssertTrue(recorder.lastView === sensitiveView)
        XCTAssertTrue(screenPreventer.lastEnablePreventScreenshotView === sensitiveView)
        XCTAssertEqual(screenPreventer.enablePreventScreenshotForViewCallCount, 2)
        XCTAssertEqual(screenPreventer.enablePreventScreenshotCallCount, 0)
    }

    func testSuspendAndResumeScreenshotProtectionDelegateToScreenPreventer() {
        let notificationCenter = NotificationCenter()
        let screenPreventer = ScreenPreventerSpy()
        let recorder = InitialViewRecorder()
        let window = makeWindow()
        let kit = ScreenProtectorKit(
            window: window,
            screenPreventer: screenPreventer,
            initializeScreenPreventer: recorder.record(view:),
            notificationCenter: notificationCenter
        )

        kit.enabledPreventScreenshot()
        XCTAssertTrue(kit.suspendPreventScreenshotProtection())
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        waitForLifecycleSynchronization()

        XCTAssertEqual(screenPreventer.suspendPreventScreenshotProtectionCallCount, 1)
        XCTAssertEqual(screenPreventer.disablePreventScreenshotCallCount, 0)
        XCTAssertEqual(screenPreventer.enabledPreventScreenshotCallCount, 1)

        kit.resumePreventScreenshotProtection()

        XCTAssertEqual(screenPreventer.resumePreventScreenshotProtectionCallCount, 1)
        XCTAssertEqual(screenPreventer.enabledPreventScreenshotCallCount, 1)
    }

    private func makeWindow() -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let viewController = UIViewController()
        viewController.view = UIView(frame: window.bounds)
        window.rootViewController = viewController
        window.isHidden = false
        return window
    }

    private func waitForMainQueue() {
        let expectation = expectation(description: "main queue drained")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    private func waitForLifecycleSynchronization() {
        let expectation = expectation(description: "lifecycle synchronization completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

private final class InitialViewRecorder {
    private(set) var lastView: UIView?
    private(set) var callCount = 0

    func record(view: UIView?) {
        callCount += 1
        lastView = view
    }
}

private final class TestRootViewResolver: ScreenProtectorRootViewResolving {
    private let view: UIView

    init(view: UIView) {
        self.view = view
    }

    func resolveRootView() -> UIView? {
        view
    }
}

private final class ScreenPreventerSpy: ScreenPreventerViewProtecting {
    var window: UIWindow?
    private(set) var enabledPreventScreenshotCallCount = 0
    private(set) var enablePreventScreenshotCallCount = 0
    private(set) var disablePreventScreenshotCallCount = 0
    private(set) var enabledPreventScreenshotForViewCallCount = 0
    private(set) var enablePreventScreenshotForViewCallCount = 0
    private(set) var disablePreventScreenshotForViewCallCount = 0
    private(set) var suspendPreventScreenshotProtectionCallCount = 0
    private(set) var resumePreventScreenshotProtectionCallCount = 0
    private(set) var enabledPreventScreenRecordingWithContentCallCount = 0
    private(set) var lastScreenRecordingText: String?
    private(set) var lastScreenRecordingImage: String?
    private(set) var rootViewResolver: ScreenPreventerRootViewResolving?
    private(set) weak var lastEnabledPreventScreenshotView: UIView?
    private(set) weak var lastEnablePreventScreenshotView: UIView?
    private(set) var enablePreventScreenshotForViewCalledOnMainThread = false
    private(set) var enabledPreventScreenRecordingCalledOnMainThread = false
    private weak var protectedView: UIView?

    func screenIsRecording() -> Bool { false }
    func screenRecordObserver(using onScreenRecord: @escaping (Bool) -> Void) {}
    func screenshotObserver(using onScreenshot: @escaping () -> Void) {}
    func removeAllObserver() {}
    func removeScreenRecordObserver() {}
    func removeScreenshotObserver() {}
    func removeObserver(observer: (any NSObjectProtocol)?) {}
    func disableImageScreen() {}
    func enabledImageScreen(named: String) {}
    func disableColorScreen() {}
    func enabledColorScreen(hexColor: String) {}
    func disableBlurScreen() {}
    func enabledBlurScreen(style: UIBlurEffect.Style) {}
    func disablePreventScreenRecording() {}

    func disablePreventScreenshot() {
        disablePreventScreenshotCallCount += 1
    }

    func enablePreventScreenshot() {
        enablePreventScreenshotCallCount += 1
    }

    func enablePreventScreenshot(for view: UIView) -> Bool {
        enablePreventScreenshotForViewCallCount += 1
        enablePreventScreenshotForViewCalledOnMainThread = Thread.isMainThread
        lastEnablePreventScreenshotView = view
        protectedView = view
        return view.window != nil
    }

    func enabledPreventScreenshot(for view: UIView) -> Bool {
        enabledPreventScreenshotForViewCallCount += 1
        lastEnabledPreventScreenshotView = view
        protectedView = view
        return view.window != nil
    }

    func disablePreventScreenshot(for view: UIView) -> Bool {
        disablePreventScreenshotForViewCallCount += 1
        guard protectedView === view else { return false }
        protectedView = nil
        return true
    }

    func enabledPreventScreenRecording(text: String?, image: String?) {
        enabledPreventScreenRecordingWithContentCallCount += 1
        enabledPreventScreenRecordingCalledOnMainThread = Thread.isMainThread
        lastScreenRecordingText = text
        lastScreenRecordingImage = image
    }

    func enabledPreventScreenshot(text: String?, image: String?) {}
    func enabledBlurScreen() {}

    func enabledPreventScreenshot() {
        enabledPreventScreenshotCallCount += 1
    }

    func enabledPreventScreenRecording() {
        enabledPreventScreenRecordingCalledOnMainThread = Thread.isMainThread
    }

    func suspendPreventScreenshotProtection() -> Bool {
        suspendPreventScreenshotProtectionCallCount += 1
        return true
    }

    func resumePreventScreenshotProtection() {
        resumePreventScreenshotProtectionCallCount += 1
    }

    func setRootViewResolver(_ resolver: ScreenPreventerRootViewResolving) {
        rootViewResolver = resolver
    }
}
