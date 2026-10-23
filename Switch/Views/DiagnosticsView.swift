import SwiftUI

/// 诊断页面。
struct DiagnosticsView: View {
  /// 全局状态。
  @EnvironmentObject private var state: AppState

  /// 页面内容。
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("diagnostics.description")
        .foregroundStyle(.secondary)

      if state.diagnostics.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "checkmark.circle")
            .font(.system(size: 42))
            .foregroundStyle(.secondary)
          Text("diagnostics.empty")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(state.diagnostics) { event in
          HStack(alignment: .top, spacing: 10) {
            Image(systemName: event.succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
              .foregroundStyle(event.succeeded ? .green : .red)
            VStack(alignment: .leading, spacing: 3) {
              HStack {
                Text(event.applicationName)
                  .font(.headline)
                Text("→")
                Text(event.inputSourceName)
              }
              Text(event.message)
                .foregroundStyle(.secondary)
              Text(event.date, format: .dateTime.year().month().day().hour().minute().second())
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
          }
          .padding(.vertical, 3)
        }
      }

      HStack {
        Button("diagnostics.copy") {
          state.copyDiagnostics()
        }
        .disabled(state.diagnostics.isEmpty)
        Button("diagnostics.clear") {
          state.clearDiagnostics()
        }
        .disabled(state.diagnostics.isEmpty)
        Spacer()
        Text(
          String(
            format: NSLocalizedString("diagnostics.count", comment: ""),
            state.diagnostics.count,
            DiagnosticStore.maximumCount
          )
        )
        .foregroundStyle(.secondary)
      }
    }
  }
}
