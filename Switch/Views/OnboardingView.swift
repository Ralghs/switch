import SwiftUI

/// 首次启动引导。
struct OnboardingView: View {
  /// 全局状态。
  @EnvironmentObject private var state: AppState
  /// 完成回调。
  let onComplete: () -> Void
  /// 当前步骤。
  @State private var step = 0

  /// 引导内容。
  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: stepImage)
        .font(.system(size: 64))
        .foregroundStyle(.blue)
        .symbolRenderingMode(.hierarchical)

      Text(stepTitle)
        .font(.largeTitle.bold())

      Text(stepDescription)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .frame(maxWidth: 460)

      if step == 2 {
        Toggle(
          "general.launchAtLogin",
          isOn: Binding(
            get: { state.isLaunchAtLoginEnabled },
            set: state.setLaunchAtLogin
          )
        )
        .toggleStyle(.switch)
      }

      Spacer()

      HStack {
        if step > 0 {
          Button("action.back") {
            step -= 1
          }
        }
        Spacer()
        Button(step == 2 ? "action.finish" : "action.continue") {
          if step == 2 {
            onComplete()
          } else {
            step += 1
          }
        }
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(32)
  }

  /// 步骤图标。
  private var stepImage: String {
    ["arrow.left.arrow.right", "list.bullet.rectangle", "menubar.rectangle"][step]
  }

  /// 步骤标题。
  private var stepTitle: LocalizedStringKey {
    ["onboarding.step1.title", "onboarding.step2.title", "onboarding.step3.title"][step]
  }

  /// 步骤说明。
  private var stepDescription: LocalizedStringKey {
    [
      "onboarding.step1.description",
      "onboarding.step2.description",
      "onboarding.step3.description",
    ][step]
  }
}
