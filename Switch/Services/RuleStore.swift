import Foundation

/// 规则存储。
final class RuleStore {
  /// 配置键。
  private enum Key {
    static let rules = "rules"
    static let switchingEnabled = "switchingEnabled"
    static let onboardingCompleted = "onboardingCompleted"
    static let warnedFailures = "warnedFailures"
  }

  /// 用户设置。
  private let defaults: UserDefaults
  /// 编码器。
  private let encoder = JSONEncoder()
  /// 解码器。
  private let decoder = JSONDecoder()

  /// 创建存储。
  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  /// 加载规则。
  func loadRules() -> [AppRule] {
    guard let data = defaults.data(forKey: Key.rules) else {
      return []
    }
    return (try? decoder.decode([AppRule].self, from: data)) ?? []
  }

  /// 保存规则。
  func saveRules(_ rules: [AppRule]) {
    defaults.set(try? encoder.encode(rules), forKey: Key.rules)
  }

  /// 自动切换状态。
  var switchingEnabled: Bool {
    get {
      defaults.object(forKey: Key.switchingEnabled) as? Bool ?? true
    }
    set {
      defaults.set(newValue, forKey: Key.switchingEnabled)
    }
  }

  /// 引导完成状态。
  var onboardingCompleted: Bool {
    get {
      defaults.bool(forKey: Key.onboardingCompleted)
    }
    set {
      defaults.set(newValue, forKey: Key.onboardingCompleted)
    }
  }

  /// 已提示失败项。
  var warnedFailures: Set<String> {
    get {
      Set(defaults.stringArray(forKey: Key.warnedFailures) ?? [])
    }
    set {
      defaults.set(Array(newValue), forKey: Key.warnedFailures)
    }
  }
}
