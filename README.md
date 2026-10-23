# Switch

Switch 是一款 macOS 菜单栏工具。应用成为前台时，它会根据用户规则切换到指定输入法。

## 许可证

本项目采用 [MIT 许可证](LICENSE)。

## 系统要求

- macOS 13 Ventura 或更高版本
- Apple Silicon 或 Intel Mac
- Xcode（建议使用 Apple 当前支持的稳定版本）

## 开发

项目使用 SwiftUI、AppKit、Carbon Input Source Services 和 ServiceManagement：

1. 安装完整 Xcode。
2. 安装 XcodeGen：`brew install xcodegen`。
3. 在项目目录执行 `xcodegen generate`。
4. 打开 `Switch.xcodeproj`。
5. 选择本地开发 Team。
6. 运行 `Switch` scheme 验证 Mac App Store 沙盒版本，或运行 `SwitchDirect` scheme 验证官网版本。

也可以直接用 Xcode 打开 `Package.swift` 做基础编译和单元测试；App Sandbox、登录项和正式 App Bundle 请使用生成的 Xcode 工程验证。

## 隐私

所有规则和最近 100 条诊断记录仅存储在本机。Switch 不记录输入内容或窗口标题，也不上传分析数据。

## 发行

- `Switch` target：启用 App Sandbox，用于 Mac App Store。正式发布前必须用 TestFlight 验证真实输入焦点中的切换结果。
- `SwitchDirect` target：关闭 App Sandbox并启用 Hardened Runtime，用于 Developer ID 签名、公证后的官网分发。

由于 `TISSelectInputSource` 在 App Sandbox 中存在已知的焦点时序风险，不能仅以 API 返回 `noErr` 作为商店版可用依据。若 TestFlight 版本无法稳定切换，应使用 `SwitchDirect` 分发。
