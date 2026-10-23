import ServiceManagement

/// 登录项服务。
final class LoginItemService {
  /// 当前是否启用。
  var isEnabled: Bool {
    SMAppService.mainApp.status == .enabled
  }

  /// 更新登录项。
  func setEnabled(_ enabled: Bool) throws {
    if enabled {
      try SMAppService.mainApp.register()
    } else {
      try SMAppService.mainApp.unregister()
    }
  }
}
