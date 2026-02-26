import SwiftUI

struct StandardInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    @State private var showValidation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("STANDARD")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)

                Spacer()

                Text("Ready")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
            }

            // Prompt display
            Text(fix.prompt)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(4)

            // Validation toggle
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showValidation.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(showValidation ? "v" : ">")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.green)
                            .frame(width: 12)

                        Text("VALIDATION")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                if showValidation {
                    Text(fix.validation)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))
                        .lineSpacing(4)
                        .padding(.leading, 18)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Inline comment
            if let comment = fix.inlineComment {
                Text("// \(comment)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.35))
                    .italic()
            }
        }
        .padding(16)
        .background(Color(white: 0.06))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(white: 0.15), lineWidth: 1)
        )
    }
}

