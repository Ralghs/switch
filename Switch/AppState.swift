import AppKit
import Combine
import UniformTypeIdentifiers

/// 应用全局状态。
@MainActor
final class AppState: ObservableObject {
  /// 自身应用标识。
  static let ownBundleIdentifier = "com.ralghs.switch"

  /// 应用规则。
  @Published private(set) var rules: [AppRule]
  /// 可用输入源。
  @Published private(set) var inputSources: [InputSourceDescriptor] = []
  /// 诊断记录。
  @Published private(set) var diagnostics: [DiagnosticEvent]
  /// 当前前台应用。
  @Published private(set) var foregroundApplication: ForegroundApplication?
  /// 当前输入源。
  @Published private(set) var currentInputSource: InputSourceDescriptor?
  /// 待处理警告。
  @Published private(set) var warningMessages: [String] = []
  /// 自动切换状态。
  @Published var isSwitchingEnabled: Bool {
    didSet {
      ruleStore.switchingEnabled = isSwitchingEnabled
      if isSwitchingEnabled {
        applyRuleForRelevantApplication()
      }
    }
  }
  /// 登录启动状态。
  @Published private(set) var isLaunchAtLoginEnabled: Bool
  /// 引导完成状态。
  @Published var isOnboardingCompleted: Bool {
    didSet {
      ruleStore.onboardingCompleted = isOnboardingCompleted
    }
  }

  /// 输入源服务。
  private let inputSourceService: InputSourceServing
  /// 前台应用监听器。
  private let applicationMonitor: FrontmostApplicationMonitor
  /// 规则存储。
  private let ruleStore: RuleStore
  /// 诊断存储。
  private let diagnosticStore: DiagnosticStore
  /// 登录项服务。
  private let loginItemService: LoginItemService
  /// 最近外部应用。
  private var lastExternalApplication: ForegroundApplication?
  /// 已提示失败项。
  private var warnedFailures: Set<String>

  /// 创建全局状态。
  init(
    inputSourceService: InputSourceServing = InputSourceService(),
    applicationMonitor: FrontmostApplicationMonitor = FrontmostApplicationMonitor(),
    ruleStore: RuleStore = RuleStore(),
    diagnosticStore: DiagnosticStore = DiagnosticStore(),
    loginItemService: LoginItemService = LoginItemService()
  ) {
    self.inputSourceService = inputSourceService
    self.applicationMonitor = applicationMonitor
    self.ruleStore = ruleStore
    self.diagnosticStore = diagnosticStore
    self.loginItemService = loginItemService
    self.rules = ruleStore.loadRules()
    self.diagnostics = diagnosticStore.load()
    self.isSwitchingEnabled = ruleStore.switchingEnabled
    self.isLaunchAtLoginEnabled = loginItemService.isEnabled
    self.isOnboardingCompleted = ruleStore.onboardingCompleted
    self.warnedFailures = ruleStore.warnedFailures

    applicationMonitor.onActivation = { [weak self] application in
      Task { @MainActor in
        self?.handleActivation(application)
      }
    }
  }

  /// 启动核心服务。
  func start() {
    refreshInputSources()
    refreshCurrentInputSource()
    applicationMonitor.start()
    guard let application = applicationMonitor.currentApplication() else {
      return
    }
    handleActivation(application)
  }

  /// 刷新输入源。
  func refreshInputSources() {
    inputSources = inputSourceService.availableInputSources()
    refreshCurrentInputSource()
    refreshWarnings()
  }

  /// 获取匹配规则。
  func rule(for bundleIdentifier: String?) -> AppRule? {
    guard let bundleIdentifier else {
      return nil
    }
    return rules.first { $0.bundleIdentifier == bundleIdentifier }
  }

  /// 判断应用是否可用。
  func isApplicationAvailable(_ rule: AppRule) -> Bool {
    NSWorkspace.shared.urlForApplication(
      withBundleIdentifier: rule.bundleIdentifier
    ) != nil
  }

  /// 判断输入源是否可用。
  func isInputSourceAvailable(_ rule: AppRule) -> Bool {
    inputSources.contains { $0.id == rule.inputSourceID }
  }

  /// 添加或更新规则。
  func saveRule(
    applicationURL: URL,
    inputSource: InputSourceDescriptor,
    isEnabled: Bool = true
  ) throws {
    guard
      let bundle = Bundle(url: applicationURL),
      let bundleIdentifier = bundle.bundleIdentifier,
      bundleIdentifier != Self.ownBundleIdentifier
    else {
      throw AppStateError.invalidApplication
    }
    let name = applicationURL.deletingPathExtension().lastPathComponent
    let rule = AppRule(
      bundleIdentifier: bundleIdentifier,
      applicationName: name,
      applicationPath: applicationURL.path,
      inputSourceID: inputSource.id,
      inputSourceName: inputSource.name,
      isEnabled: isEnabled
    )
    mergeRule(rule)
    applyRuleIfRelevant(rule)
  }

  /// 更新已有规则。
  func updateRule(_ rule: AppRule, inputSource: InputSourceDescriptor, isEnabled: Bool) {
    guard let index = rules.firstIndex(where: { $0.id == rule.id }) else {
      return
    }
    rules[index].inputSourceID = inputSource.id
    rules[index].inputSourceName = inputSource.name
    rules[index].isEnabled = isEnabled
    persistRules()
    applyRuleIfRelevant(rules[index])
  }

  /// 切换单条规则。
  func setRuleEnabled(_ rule: AppRule, enabled: Bool) {
    guard let index = rules.firstIndex(where: { $0.id == rule.id }) else {
      return
    }
    rules[index].isEnabled = enabled
    persistRules()
    if enabled {
      applyRuleIfRelevant(rules[index])
    }
  }

  /// 删除规则。
  func deleteRules(at offsets: IndexSet, from visibleRules: [AppRule]) {
    let ids = Set(offsets.map { visibleRules[$0].id })
    rules.removeAll { ids.contains($0.id) }
    persistRules()
    refreshWarnings()
  }

  /// 选择应用。
  func chooseApplication() -> URL? {
    let panel = NSOpenPanel()
    panel.title = NSLocalizedString("picker.application.title", comment: "")
    panel.prompt = NSLocalizedString("action.choose", comment: "")
    panel.allowedContentTypes = [.application]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.directoryURL = URL(fileURLWithPath: "/Applications")
    return panel.runModal() == .OK ? panel.url : nil
  }

  /// 设置登录启动。
  func setLaunchAtLogin(_ enabled: Bool) {
    do {
      try loginItemService.setEnabled(enabled)
      isLaunchAtLoginEnabled = loginItemService.isEnabled
    } catch {
      warningMessages.append(error.localizedDescription)
      isLaunchAtLoginEnabled = loginItemService.isEnabled
    }
  }

  /// 导出配置。
  func exportConfiguration() {
    let panel = NSSavePanel()
    panel.title = NSLocalizedString("export.title", comment: "")
    panel.nameFieldStringValue = "Switch-Configuration.json"
    panel.allowedContentTypes = [.json]
    guard panel.runModal() == .OK, let url = panel.url else {
      return
    }
    let configuration = ExportConfiguration(
      formatVersion: 1,
      exportedAt: Date(),
      automaticSwitchingEnabled: isSwitchingEnabled,
      launchAtLoginEnabled: isLaunchAtLoginEnabled,
      rules: rules
    )
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      encoder.dateEncodingStrategy = .iso8601
      try encoder.encode(configuration).write(to: url, options: .atomic)
    } catch {
      warningMessages.append(error.localizedDescription)
    }
  }

  /// 导入并合并配置。
  func importConfiguration() {
    let panel = NSOpenPanel()
    panel.title = NSLocalizedString("import.title", comment: "")
    panel.allowedContentTypes = [.json]
    panel.allowsMultipleSelection = false
    guard panel.runModal() == .OK, let url = panel.url else {
      return
    }

    do {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      let configuration = try decoder.decode(
        ExportConfiguration.self,
        from: Data(contentsOf: url)
      )
      guard configuration.formatVersion == 1 else {
        throw AppStateError.unsupportedConfiguration
      }
      let importableRules = configuration.rules.filter {
        $0.bundleIdentifier != Self.ownBundleIdentifier
      }
      let overwriteCount = importableRules.filter { imported in
        rules.contains { $0.bundleIdentifier == imported.bundleIdentifier }
      }.count
      let newCount = importableRules.count - overwriteCount
      guard confirmImport(newCount: newCount, overwriteCount: overwriteCount) else {
        return
      }
      importableRules.forEach(mergeRule)
      persistRules()
      refreshWarnings()
    } catch {
      warningMessages.append(error.localizedDescription)
    }
  }

  /// 清空诊断。
  func clearDiagnostics() {
    diagnosticStore.clear()
    diagnostics = []
  }

  /// 复制诊断。
  func copyDiagnostics() {
    let formatter = ISO8601DateFormatter()
    let text = diagnostics.map {
      "\(formatter.string(from: $0.date))\t\($0.applicationName)\t"
        + "\($0.inputSourceName)\t\($0.succeeded ? "OK" : "FAILED")\t\($0.message)"
    }.joined(separator: "\n")
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
  }

  /// 清除警告。
  func clearWarnings() {
    warningMessages = []
  }

  /// 处理应用激活。
  private func handleActivation(_ application: ForegroundApplication) {
    guard application.bundleIdentifier != Self.ownBundleIdentifier else {
      return
    }
    foregroundApplication = application
    lastExternalApplication = application
    refreshCurrentInputSource()
    applyRule(to: application)
  }

  /// 应用相关规则。
  private func applyRuleForRelevantApplication() {
    if let current = applicationMonitor.currentApplication(),
      current.bundleIdentifier != Self.ownBundleIdentifier
    {
      handleActivation(current)
    } else if let lastExternalApplication {
      applyRule(to: lastExternalApplication)
    }
  }

  /// 规则相关时立即应用。
  private func applyRuleIfRelevant(_ rule: AppRule) {
    guard rule.isEnabled,
      isSwitchingEnabled,
      rule.bundleIdentifier == lastExternalApplication?.bundleIdentifier
    else {
      return
    }
    applyRule(to: lastExternalApplication)
  }

  /// 执行规则。
  private func applyRule(to application: ForegroundApplication?) {
    guard
      isSwitchingEnabled,
      let application,
      let rule = rule(for: application.bundleIdentifier),
      rule.isEnabled
    else {
      return
    }
    guard isInputSourceAvailable(rule) else {
      recordFailure(
        rule: rule, message: InputSourceError.unavailable(rule.inputSourceName).localizedDescription
      )
      return
    }

    do {
      try inputSourceService.selectInputSource(id: rule.inputSourceID)
      currentInputSource = inputSourceService.currentInputSource()
      warnedFailures.remove(rule.bundleIdentifier)
      ruleStore.warnedFailures = warnedFailures
      diagnostics = diagnosticStore.append(
        DiagnosticEvent(
          applicationName: rule.applicationName,
          inputSourceName: rule.inputSourceName,
          succeeded: true,
          message: NSLocalizedString("diagnostic.success", comment: "")
        )
      )
      refreshWarnings()
    } catch {
      recordFailure(rule: rule, message: error.localizedDescription)
    }
  }

  /// 记录失败。
  private func recordFailure(rule: AppRule, message: String) {
    diagnostics = diagnosticStore.append(
      DiagnosticEvent(
        applicationName: rule.applicationName,
        inputSourceName: rule.inputSourceName,
        succeeded: false,
        message: message
      )
    )
    warnedFailures.insert(rule.bundleIdentifier)
    ruleStore.warnedFailures = warnedFailures
    refreshWarnings()
  }

  /// 合并规则。
  private func mergeRule(_ imported: AppRule) {
    if let index = rules.firstIndex(where: {
      $0.bundleIdentifier == imported.bundleIdentifier
    }) {
      var rule = imported
      rule.id = rules[index].id
      rules[index] = rule
    } else {
      rules.append(imported)
    }
    persistRules()
  }

  /// 保存规则。
  private func persistRules() {
    rules.sort {
      $0.applicationName.localizedStandardCompare($1.applicationName) == .orderedAscending
    }
    ruleStore.saveRules(rules)
    refreshWarnings()
  }

  /// 刷新当前输入源。
  private func refreshCurrentInputSource() {
    currentInputSource = inputSourceService.currentInputSource()
  }

  /// 刷新警告信息。
  private func refreshWarnings() {
    warningMessages = rules.compactMap { rule in
      if warnedFailures.contains(rule.bundleIdentifier) {
        return String(
          format: NSLocalizedString("warning.switchFailed", comment: ""),
          rule.applicationName
        )
      }
      return nil
    }
  }

  /// 确认导入。
  private func confirmImport(newCount: Int, overwriteCount: Int) -> Bool {
    let alert = NSAlert()
    alert.messageText = NSLocalizedString("import.confirm.title", comment: "")
    alert.informativeText = String(
      format: NSLocalizedString("import.confirm.message", comment: ""),
      newCount,
      overwriteCount
    )
    alert.addButton(withTitle: NSLocalizedString("action.import", comment: ""))
    alert.addButton(withTitle: NSLocalizedString("action.cancel", comment: ""))
    return alert.runModal() == .alertFirstButtonReturn
  }
}

/// 应用状态错误。
enum AppStateError: LocalizedError {
  /// 无效应用。
  case invalidApplication
  /// 不支持配置。
  case unsupportedConfiguration

  /// 错误说明。
  var errorDescription: String? {
    switch self {
    case .invalidApplication:
      return NSLocalizedString("error.invalidApplication", comment: "")
    case .unsupportedConfiguration:
      return NSLocalizedString("error.unsupportedConfiguration", comment: "")
    }
  }
}
