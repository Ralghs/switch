import XCTest

@testable import Switch

/// 诊断存储测试。
final class DiagnosticStoreTests: XCTestCase {
  /// 测试设置。
  private var defaults: UserDefaults!
  /// 测试存储。
  private var store: DiagnosticStore!

  /// 准备测试。
  override func setUp() {
    super.setUp()
    defaults = UserDefaults(suiteName: "DiagnosticStoreTests")
    defaults.removePersistentDomain(forName: "DiagnosticStoreTests")
    store = DiagnosticStore(defaults: defaults)
  }

  /// 清理测试。
  override func tearDown() {
    defaults.removePersistentDomain(forName: "DiagnosticStoreTests")
    defaults = nil
    store = nil
    super.tearDown()
  }

  /// 验证最大数量。
  func testKeepsLatestOneHundredEvents() {
    for index in 0..<105 {
      _ = store.append(
        DiagnosticEvent(
          applicationName: "App \(index)",
          inputSourceName: "ABC",
          succeeded: true,
          message: "OK"
        )
      )
    }

    let events = store.load()
    XCTAssertEqual(events.count, 100)
    XCTAssertEqual(events.first?.applicationName, "App 104")
    XCTAssertEqual(events.last?.applicationName, "App 5")
  }

  /// 验证清空。
  func testClearRemovesAllEvents() {
    _ = store.append(
      DiagnosticEvent(
        applicationName: "Example",
        inputSourceName: "ABC",
        succeeded: false,
        message: "Failed"
      )
    )

    store.clear()

    XCTAssertTrue(store.load().isEmpty)
  }
}
