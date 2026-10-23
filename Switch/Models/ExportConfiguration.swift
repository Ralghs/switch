import Foundation

/// 导出配置。
struct ExportConfiguration: Codable {
  /// 文件格式版本。
  let formatVersion: Int
  /// 导出时间。
  let exportedAt: Date
  /// 自动切换状态。
  let automaticSwitchingEnabled: Bool
  /// 登录启动偏好。
  let launchAtLoginEnabled: Bool
  /// 应用规则。
  let rules: [AppRule]
}
