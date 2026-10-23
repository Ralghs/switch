import SwiftUI

/// 设置窗口。
struct SettingsView: View {
  /// 全局状态。
  @EnvironmentObject private var state: AppState

  /// 设置内容。
  var body: some View {
    TabView {
      RulesView()
        .tabItem {
          Label("settings.rules", systemImage: "list.bullet.rectangle")
        }
      GeneralSettingsView()
        .tabItem {
          Label("settings.general", systemImage: "gearshape")
        }
      DiagnosticsView()
        .tabItem {
          Label("settings.diagnostics", systemImage: "stethoscope")
        }
    }
    .padding()
    .onAppear {
      state.refreshInputSources()
    }
  }
}
