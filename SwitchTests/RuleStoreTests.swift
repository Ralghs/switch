import XCTest

@testable import Switch

/// 规则存储测试。
final class RuleStoreTests: XCTestCase {
  /// 测试设置。
  private var defaults: UserDefaults!
  /// 测试存储。
  private var store: RuleStore!

  /// 准备测试。
  override func setUp() {
    super.setUp()
    defaults = UserDefaults(suiteName: "RuleStoreTests")
    defaults.removePersistentDomain(forName: "RuleStoreTests")
    store = RuleStore(defaults: defaults)
  }

  /// 清理测试。
  override func tearDown() {
    defaults.removePersistentDomain(forName: "RuleStoreTests")
    defaults = nil
    store = nil
    super.tearDown()
  }

  /// 验证默认开启。
  func testSwitchingIsEnabledByDefault() {
    XCTAssertTrue(store.switchingEnabled)
  }

  /// 验证规则往返。
  func testRulesRoundTrip() {
    let rule = AppRule(
      bundleIdentifier: "com.example.app",
      applicationName: "Example",
      applicationPath: "/Applications/Example.app",
      inputSourceID: "com.apple.keylayout.ABC",
      inputSourceName: "ABC"
    )

    store.saveRules([rule])

    XCTAssertEqual(store.loadRules(), [rule])
  }
}
