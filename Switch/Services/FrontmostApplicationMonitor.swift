import AppKit

/// 前台应用信息。
struct ForegroundApplication: Equatable {
  /// 应用标识。
  let bundleIdentifier: String
  /// 应用名称。
  let name: String
}

/// 前台应用监听器。
final class FrontmostApplicationMonitor {
  /// 激活回调。
  var onActivation: ((ForegroundApplication) -> Void)?

  /// 通知令牌。
  private var observer: NSObjectProtocol?

  /// 开始监听。
  func start() {
    guard observer == nil else {
      return
    }
    observer = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard
        let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
          as? NSRunningApplication,
        let foregroundApplication = Self.makeApplication(from: application)
      else {
        return
      }
      self?.onActivation?(foregroundApplication)
    }
  }

  /// 停止监听。
  func stop() {
    if let observer {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
    }
    observer = nil
  }

  /// 读取当前应用。
  func currentApplication() -> ForegroundApplication? {
    guard let application = NSWorkspace.shared.frontmostApplication else {
      return nil
    }
    return Self.makeApplication(from: application)
  }

  /// 转换应用信息。
  private static func makeApplication(
    from application: NSRunningApplication
  ) -> ForegroundApplication? {
    guard let bundleIdentifier = application.bundleIdentifier else {
      return nil
    }
    return ForegroundApplication(
      bundleIdentifier: bundleIdentifier,
      name: application.localizedName ?? bundleIdentifier
    )
  }

  deinit {
    stop()
  }
}
