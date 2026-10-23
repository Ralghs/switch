import AppKit
import SwiftUI

/// 规则编辑器。
struct RuleEditorView: View {
  /// 关闭窗口。
  @Environment(\.dismiss) private var dismiss
  /// 全局状态。
  @EnvironmentObject private var state: AppState
  /// 应用地址。
  let applicationURL: URL
  /// 已有规则。
  let existingRule: AppRule?
  /// 输入源标识。
  @State private var selectedInputSourceID = ""
  /// 启用状态。
  @State private var isEnabled = true
  /// 错误信息。
  @State private var errorMessage: String?

  /// 编辑内容。
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack(spacing: 12) {
        Image(nsImage: NSWorkspace.shared.icon(forFile: applicationURL.path))
          .resizable()
          .frame(width: 48, height: 48)
        VStack(alignment: .leading) {
          Text(applicationName)
            .font(.title2.bold())
          Text(Bundle(url: applicationURL)?.bundleIdentifier ?? "")
            .foregroundStyle(.secondary)
        }
      }

      Picker("editor.inputSource", selection: $selectedInputSourceID) {
        ForEach(state.inputSources) { source in
          Text(source.name).tag(source.id)
        }
      }

      Toggle("editor.ruleEnabled", isOn: $isEnabled)

      if let errorMessage {
        Text(errorMessage)
          .foregroundStyle(.red)
      }

      HStack {
        Spacer()
        Button("action.cancel") {
          dismiss()
        }
        Button("action.save") {
          save()
        }
        .keyboardShortcut(.defaultAction)
        .disabled(selectedInputSourceID.isEmpty)
      }
    }
    .padding(24)
    .frame(width: 460)
    .onAppear {
      state.refreshInputSources()
      selectedInputSourceID =
        existingRule?.inputSourceID ?? state.currentInputSource?.id ?? state.inputSources.first?.id
        ?? ""
      isEnabled = existingRule?.isEnabled ?? true
    }
  }

  /// 应用名称。
  private var applicationName: String {
    applicationURL.deletingPathExtension().lastPathComponent
  }

  /// 保存规则。
  private func save() {
    guard
      let inputSource = state.inputSources.first(where: {
        $0.id == selectedInputSourceID
      })
    else {
      return
    }
    if let existingRule {
      state.updateRule(existingRule, inputSource: inputSource, isEnabled: isEnabled)
      dismiss()
      return
    }
    do {
      try state.saveRule(
        applicationURL: applicationURL,
        inputSource: inputSource,
        isEnabled: isEnabled
      )
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
