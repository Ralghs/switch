import Carbon
import Foundation

/// 输入源错误。
enum InputSourceError: LocalizedError {
  /// 输入源不存在。
  case unavailable(String)
  /// 系统切换失败。
  case switchFailed(OSStatus)

  /// 错误说明。
  var errorDescription: String? {
    switch self {
    case .unavailable(let name):
      return String(format: NSLocalizedString("error.inputSourceUnavailable", comment: ""), name)
    case .switchFailed(let status):
      return String(format: NSLocalizedString("error.inputSourceSwitchFailed", comment: ""), status)
    }
  }
}

/// 输入源服务协议。
protocol InputSourceServing {
  /// 列出可选输入源。
  func availableInputSources() -> [InputSourceDescriptor]
  /// 获取当前输入源。
  func currentInputSource() -> InputSourceDescriptor?
  /// 切换输入源。
  func selectInputSource(id: String) throws
}

/// macOS 输入源服务。
final class InputSourceService: InputSourceServing {
  /// 列出可选输入源。
  func availableInputSources() -> [InputSourceDescriptor] {
    let filters =
      [
        kTISPropertyInputSourceIsEnabled: true,
        kTISPropertyInputSourceIsSelectCapable: true,
      ] as CFDictionary
    let sources =
      TISCreateInputSourceList(filters, false).takeRetainedValue()
      as! [TISInputSource]

    return
      sources
      .filter(isKeyboardSource)
      .compactMap(descriptor)
      .uniqued()
      .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
  }

  /// 获取当前输入源。
  func currentInputSource() -> InputSourceDescriptor? {
    let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    return descriptor(for: source)
  }

  /// 切换输入源。
  func selectInputSource(id: String) throws {
    guard let source = source(withID: id) else {
      throw InputSourceError.unavailable(id)
    }
    let status = TISSelectInputSource(source)
    guard status == noErr else {
      throw InputSourceError.switchFailed(status)
    }
  }

  /// 根据标识查找输入源。
  private func source(withID id: String) -> TISInputSource? {
    let filter = [kTISPropertyInputSourceID: id] as CFDictionary
    let sources =
      TISCreateInputSourceList(filter, false).takeRetainedValue()
      as! [TISInputSource]
    return sources.first
  }

  /// 构建输入源信息。
  private func descriptor(for source: TISInputSource) -> InputSourceDescriptor? {
    guard
      let id: String = property(source, key: kTISPropertyInputSourceID),
      let name: String = property(source, key: kTISPropertyLocalizedName)
    else {
      return nil
    }
    return InputSourceDescriptor(id: id, name: name)
  }

  /// 判断键盘输入源。
  private func isKeyboardSource(_ source: TISInputSource) -> Bool {
    guard let type: String = property(source, key: kTISPropertyInputSourceType) else {
      return false
    }
    let keyboardTypes = [
      kTISTypeKeyboardLayout as String,
      kTISTypeKeyboardInputMethodWithoutModes as String,
      kTISTypeKeyboardInputMethodModeEnabled as String,
      kTISTypeKeyboardInputMode as String,
    ]
    return keyboardTypes.contains(type)
  }

  /// 读取输入源属性。
  private func property<T>(_ source: TISInputSource, key: CFString) -> T? {
    guard let pointer = TISGetInputSourceProperty(source, key) else {
      return nil
    }
    return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue() as? T
  }
}

/// 输入源去重。
extension Array where Element == InputSourceDescriptor {
  /// 按标识去重。
  fileprivate func uniqued() -> [Element] {
    var identifiers = Set<String>()
    return filter { identifiers.insert($0.id).inserted }
  }
}
