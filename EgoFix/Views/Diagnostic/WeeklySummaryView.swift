import SwiftUI

struct WeeklySummaryView: View {
    let summary: WeeklySummaryData
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text("WEEKLY SUMMARY")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.white)
                    .opacity(appeared ? 1 : 0)

                // Stats grid
                HStack(spacing: 24) {
                    statBlock(label: "APPLIED", value: summary.applied, color: .green)
                    statBlock(label: "SKIPPED", value: summary.skipped, color: .yellow)
                    statBlock(label: "FAILED", value: summary.failed, color: .red)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                // Comment
                Text(summary.comment)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                Button(action: onDismiss) {
                    Text("[ Continue ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding()
                }
                .opacity(appeared ? 1 : 0)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    private func statBlock(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            Text("\(value)")
                .font(.system(.largeTitle, design: .monospaced))
                .foregroundColor(color)

            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(width: 80)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}
