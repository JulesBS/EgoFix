import SwiftUI

struct AuditInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AUDIT")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text("End-of-day review")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
            }

            Text(fix.prompt)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(4)

            if let config = fix.auditConfig {
                Text(config.auditPrompt)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.6))

                ForEach(config.categories) { category in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.label.uppercased())
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(Color(white: 0.5))

                        let binding = Binding<String>(
                            get: { interactionManager.auditItems[category.id] ?? "" },
                            set: { interactionManager.auditItems[category.id] = $0 }
                        )

                        TextField("Note...", text: binding, axis: .vertical)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(1...3)
                            .padding(6)
                            .background(Color(white: 0.08))
                            .cornerRadius(2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color(white: 0.2), lineWidth: 1)
                            )
                    }
                }
            }

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
