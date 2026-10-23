import SwiftUI

/// 菜单栏内容。
struct MenuBarContentView: View {
  /// 全局状态。
  @EnvironmentObject private var state: AppState

  /// 菜单内容。
  var body: some View {
    Toggle(
      "menu.automaticSwitching",
      isOn: $state.isSwitchingEnabled
    )

    Divider()

    LabeledContent("menu.currentApplication") {
      Text(state.foregroundApplication?.name ?? "status.unavailable")
    }
    LabeledContent("menu.currentInputSource") {
      Text(state.currentInputSource?.name ?? "status.unavailable")
    }
    if let rule = state.rule(for: state.foregroundApplication?.bundleIdentifier) {
      LabeledContent("menu.matchedRule") {
        Text(rule.isEnabled ? rule.inputSourceName : String(localized: "status.disabled"))
      }
    }

    if !state.warningMessages.isEmpty {
      Divider()
      ForEach(state.warningMessages, id: \.self) { message in
        Label(message, systemImage: "exclamationmark.triangle.fill")
      }
    }

    Divider()

    Button("menu.openSettings") {
      AppDelegate.shared?.showSettings()
    }
    Button("menu.quit") {
      NSApp.terminate(nil)
    }
  }
}
