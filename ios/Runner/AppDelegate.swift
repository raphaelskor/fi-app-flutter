import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var securityView: UIView?
  private var screenshotChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up method channel for screenshot protection
    let controller = window?.rootViewController as! FlutterViewController
    screenshotChannel = FlutterMethodChannel(
      name: "com.skorcard.fiapp/screenshot",
      binaryMessenger: controller.binaryMessenger
    )
    
    screenshotChannel?.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "disableScreenshot" {
        self?.setupScreenshotProtection()
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Setup screenshot protection immediately
    setupScreenshotProtection()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupScreenshotProtection() {
    // Detect when user takes screenshot
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenshotTaken),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
    
    // Hide content when app goes to background (prevents app switcher preview)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(hideContent),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
    
    // Show content when app becomes active
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(showContent),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    
    // Prevent screen recording detection (iOS 11+)
    if #available(iOS 11.0, *) {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(screenRecordingChanged),
        name: UIScreen.capturedDidChangeNotification,
        object: nil
      )
    }
  }
  
  @objc private func screenshotTaken() {
    // Show alert when screenshot is detected
    print("⚠️ Screenshot detected!")
    
    // Optional: Show warning to user
    DispatchQueue.main.async { [weak self] in
      guard let window = self?.window,
            let rootViewController = window.rootViewController else { return }
      
      let alert = UIAlertController(
        title: "Security Alert",
        message: "Screenshots are not allowed for security reasons. The screenshot has been detected.",
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      rootViewController.present(alert, animated: true)
    }
  }
  
  @objc private func hideContent() {
    // Create a blur/security view to hide sensitive content
    guard let window = window else { return }
    
    if securityView == nil {
      securityView = UIView(frame: window.bounds)
      securityView?.backgroundColor = .white
      
      // Add app logo or message
      let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
      imageView.center = CGPoint(x: window.bounds.width / 2, y: window.bounds.height / 2)
      imageView.contentMode = .scaleAspectFit
      
      // Try to load app icon
      if let appIcon = UIImage(named: "AppIcon") {
        imageView.image = appIcon
      } else {
        // Fallback: Show app name
        let label = UILabel(frame: window.bounds)
        label.text = "Field Investigator"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .systemBlue
        securityView?.addSubview(label)
      }
      
      securityView?.addSubview(imageView)
    }
    
    if let securityView = securityView {
      window.addSubview(securityView)
      window.bringSubviewToFront(securityView)
    }
  }
  
  @objc private func showContent() {
    // Remove security view when app becomes active
    securityView?.removeFromSuperview()
  }
  
  @objc private func screenRecordingChanged() {
    if #available(iOS 11.0, *) {
      if UIScreen.main.isCaptured {
        print("⚠️ Screen recording detected!")
        
        // Show warning to user
        DispatchQueue.main.async { [weak self] in
          guard let window = self?.window,
                let rootViewController = window.rootViewController else { return }
          
          let alert = UIAlertController(
            title: "Security Alert",
            message: "Screen recording is not allowed for security reasons. Please stop recording.",
            preferredStyle: .alert
          )
          alert.addAction(UIAlertAction(title: "OK", style: .default))
          rootViewController.present(alert, animated: true)
        }
        
        // Optionally hide content while recording
        hideContent()
      } else {
        // Show content when recording stops
        showContent()
      }
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
