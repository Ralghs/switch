import AppKit
import SwiftUI

/// 通用设置。
struct GeneralSettingsView: View {
  /// 全局状态。
  @EnvironmentObject private var state: AppState

  /// 设置内容。
  var body: some View {
    Form {
      Section("general.behavior") {
        Toggle("menu.automaticSwitching", isOn: $state.isSwitchingEnabled)
        Toggle(
          "general.launchAtLogin",
          isOn: Binding(
            get: { state.isLaunchAtLoginEnabled },
            set: state.setLaunchAtLogin
          )
        )
        Text("general.launchAtLogin.help")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section("general.inputSources") {
        LabeledContent("menu.currentInputSource") {
          Text(state.currentInputSource?.name ?? String(localized: "status.unavailable"))
        }
        Button("general.openKeyboardSettings") {
          openKeyboardSettings()
        }
        Button("action.refresh") {
          state.refreshInputSources()
        }
      }

      Section("general.privacy") {
        Text("general.privacy.description")
          .foregroundStyle(.secondary)
      }

      Section("general.about") {
        LabeledContent("general.version") {
          Text(version)
        }
        LabeledContent("general.bundleIdentifier") {
          Text(AppState.ownBundleIdentifier)
        }
      }
    }
    .formStyle(.grouped)
  }

  /// 版本信息。
  private var version: String {
    let version =
      Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString"
      ) as? String ?? "1.0.0"
    let build =
      Bundle.main.object(
        forInfoDictionaryKey: "CFBundleVersion"
      ) as? String ?? "1"
    return "\(version) (\(build))"
  }

  /// 打开键盘设置。
  private func openKeyboardSettings() {
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
      )
    else {
      return
    }
    NSWorkspace.shared.open(url)
  }
}
