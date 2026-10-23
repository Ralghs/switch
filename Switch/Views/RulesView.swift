import AppKit
import SwiftUI

/// 编辑上下文。
private struct RuleEditorContext: Identifiable {
  /// 上下文标识。
  let id = UUID()
  /// 应用地址。
  let applicationURL: URL
  /// 已有规则。
  let rule: AppRule?
}

/// 规则列表。
struct RulesView: View {
  /// 全局状态。
  @EnvironmentObject private var state: AppState
  /// 搜索文本。
  @State private var searchText = ""
  /// 编辑上下文。
  @State private var editorContext: RuleEditorContext?

  /// 过滤规则。
  private var visibleRules: [AppRule] {
    guard !searchText.isEmpty else {
      return state.rules
    }
    return state.rules.filter {
      $0.applicationName.localizedCaseInsensitiveContains(searchText)
        || $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
    }
  }

  /// 规则内容。
  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Toggle("menu.automaticSwitching", isOn: $state.isSwitchingEnabled)
          .toggleStyle(.switch)
        Spacer()
        TextField("rules.search", text: $searchText)
          .textFieldStyle(.roundedBorder)
          .frame(width: 240)
      }

      if state.rules.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "keyboard")
            .font(.system(size: 44))
            .foregroundStyle(.secondary)
          Text("rules.empty.title")
            .font(.title2.bold())
          Text("rules.empty.description")
            .foregroundStyle(.secondary)
          Button("rules.add") {
            addApplication()
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List {
          ForEach(visibleRules) { rule in
            RuleRowView(
              rule: rule,
              applicationAvailable: state.isApplicationAvailable(rule),
              inputSourceAvailable: state.isInputSourceAvailable(rule),
              onToggle: { enabled in
                state.setRuleEnabled(rule, enabled: enabled)
              }
            )
            .contentShape(Rectangle())
            .onTapGesture {
              edit(rule)
            }
            .contextMenu {
              Button("action.edit") {
                edit(rule)
              }
            }
          }
          .onDelete {
            state.deleteRules(at: $0, from: visibleRules)
          }
        }
      }

      HStack {
        Button {
          addApplication()
        } label: {
          Label("rules.add", systemImage: "plus")
        }
        Button("action.refresh") {
          state.refreshInputSources()
        }
        Spacer()
        Menu("rules.configuration") {
          Button("action.import") {
            state.importConfiguration()
          }
          Button("action.export") {
            state.exportConfiguration()
          }
        }
      }
    }
    .sheet(item: $editorContext) { context in
      RuleEditorView(
        applicationURL: context.applicationURL,
        existingRule: context.rule
      )
      .environmentObject(state)
    }
  }

  /// 添加应用。
  private func addApplication() {
    guard let url = state.chooseApplication(),
      let identifier = Bundle(url: url)?.bundleIdentifier,
      identifier != AppState.ownBundleIdentifier
    else {
      return
    }
    editorContext = RuleEditorContext(
      applicationURL: url,
      rule: state.rule(for: identifier)
    )
  }

  /// 编辑规则。
  private func edit(_ rule: AppRule) {
    let locatedURL = NSWorkspace.shared.urlForApplication(
      withBundleIdentifier: rule.bundleIdentifier
    )
    let storedURL = rule.applicationPath.map(URL.init(fileURLWithPath:))
    guard let url = locatedURL ?? storedURL else {
      return
    }
    editorContext = RuleEditorContext(applicationURL: url, rule: rule)
  }
}

/// 规则行。
private struct RuleRowView: View {
  /// 规则。
  let rule: AppRule
  /// 应用可用状态。
  let applicationAvailable: Bool
  /// 输入源可用状态。
  let inputSourceAvailable: Bool
  /// 开关回调。
  let onToggle: (Bool) -> Void

  /// 行内容。
  var body: some View {
    HStack(spacing: 12) {
      Image(nsImage: applicationIcon)
        .resizable()
        .frame(width: 36, height: 36)

      VStack(alignment: .leading, spacing: 3) {
        Text(rule.applicationName)
          .font(.headline)
        Text(rule.bundleIdentifier)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 3) {
        Text(rule.inputSourceName)
        if !applicationAvailable {
          Label("status.applicationUnavailable", systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(.orange)
        } else if !inputSourceAvailable {
          Label("status.inputSourceUnavailable", systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(.orange)
        }
      }

      Toggle(
        "",
        isOn: Binding(
          get: { rule.isEnabled },
          set: onToggle
        )
      )
      .labelsHidden()
      .toggleStyle(.switch)
    }
    .padding(.vertical, 4)
  }

  /// 应用图标。
  private var applicationIcon: NSImage {
    if let path = rule.applicationPath {
      return NSWorkspace.shared.icon(forFile: path)
    }
    return NSWorkspace.shared.icon(for: .application)
  }
}
