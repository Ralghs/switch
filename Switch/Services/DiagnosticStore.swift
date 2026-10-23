import Foundation

/// 诊断存储。
final class DiagnosticStore {
  /// 最大记录数量。
  static let maximumCount = 100

  /// 存储键。
  private let key = "diagnosticEvents"
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

  /// 加载事件。
  func load() -> [DiagnosticEvent] {
    guard let data = defaults.data(forKey: key) else {
      return []
    }
    return (try? decoder.decode([DiagnosticEvent].self, from: data)) ?? []
  }

  /// 添加事件。
  func append(_ event: DiagnosticEvent) -> [DiagnosticEvent] {
    var events = load()
    events.insert(event, at: 0)
    events = Array(events.prefix(Self.maximumCount))
    defaults.set(try? encoder.encode(events), forKey: key)
    return events
  }

  /// 清空事件。
  func clear() {
    defaults.removeObject(forKey: key)
  }
}
