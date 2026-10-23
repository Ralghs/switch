import Foundation

/// 本地诊断事件。
struct DiagnosticEvent: Codable, Identifiable, Equatable {
  /// 事件标识。
  let id: UUID
  /// 发生时间。
  let date: Date
  /// 应用名称。
  let applicationName: String
  /// 输入源名称。
  let inputSourceName: String
  /// 是否成功。
  let succeeded: Bool
  /// 结果说明。
  let message: String

  /// 创建事件。
  init(
    id: UUID = UUID(),
    date: Date = Date(),
    applicationName: String,
    inputSourceName: String,
    succeeded: Bool,
    message: String
  ) {
    self.id = id
    self.date = date
    self.applicationName = applicationName
    self.inputSourceName = inputSourceName
    self.succeeded = succeeded
    self.message = message
  }
}
