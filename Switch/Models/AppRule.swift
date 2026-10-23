import Foundation

/// 应用输入法规则。
struct AppRule: Codable, Identifiable, Equatable {
  /// 规则标识。
  var id: UUID
  /// 应用标识。
  let bundleIdentifier: String
  /// 应用名称。
  var applicationName: String
  /// 应用路径。
  var applicationPath: String?
  /// 输入源标识。
  var inputSourceID: String
  /// 输入源名称。
  var inputSourceName: String
  /// 是否启用。
  var isEnabled: Bool

  /// 创建规则。
  init(
    id: UUID = UUID(),
    bundleIdentifier: String,
    applicationName: String,
    applicationPath: String?,
    inputSourceID: String,
    inputSourceName: String,
    isEnabled: Bool = true
  ) {
    self.id = id
    self.bundleIdentifier = bundleIdentifier
    self.applicationName = applicationName
    self.applicationPath = applicationPath
    self.inputSourceID = inputSourceID
    self.inputSourceName = inputSourceName
    self.isEnabled = isEnabled
  }
}
