import AppKit
import SwiftUI

/// 应用入口。
@main
struct SwitchApp: App {
  /// 应用代理。
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  /// 应用场景。
  var body: some Scene {
    MenuBarExtra {
      MenuBarContentView()
        .environmentObject(appDelegate.state)
    } label: {
      Image(
        systemName: appDelegate.state.warningMessages.isEmpty
          ? "arrow.left.arrow.right"
          : "exclamationmark.arrow.triangle.2.circlepath"
      )
      .accessibilityLabel("Switch")
    }
  }
}

/// 应用代理。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  /// 当前应用代理。
  static weak var shared: AppDelegate?
  /// 全局状态。
  let state = AppState()
  /// 引导窗口。
  private var onboardingWindow: NSWindow?
  /// 设置窗口。
  private var settingsWindow: NSWindow?

  /// 应用启动完成。
  func applicationDidFinishLaunching(_ notification: Notification) {
    Self.shared = self
    state.start()
    if !state.isOnboardingCompleted {
      showOnboarding()
    }
  }

  /// 显示首次引导。
  private func showOnboarding() {
    let view = OnboardingView {
      self.state.isOnboardingCompleted = true
      self.onboardingWindow?.close()
      self.onboardingWindow = nil
      self.showSettings()
    }
    .environmentObject(state)

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 640, height: 460),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = NSLocalizedString("onboarding.title", comment: "")
    window.contentView = NSHostingView(rootView: view)
    window.center()
    window.isReleasedWhenClosed = false
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    onboardingWindow = window
  }

  /// 打开设置。
  func showSettings() {
    if let settingsWindow {
      settingsWindow.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    let view = SettingsView()
      .environmentObject(state)
      .frame(minWidth: 680, minHeight: 520)
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 720, height: 560),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = NSLocalizedString("menu.openSettings", comment: "")
    window.contentView = NSHostingView(rootView: view)
    window.center()
    window.isReleasedWhenClosed = false
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    settingsWindow = window
  }
}
