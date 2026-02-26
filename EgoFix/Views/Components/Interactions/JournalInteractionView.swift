import SwiftUI

struct JournalInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("JOURNAL")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.blue)
                Spacer()
                Text("2-3 sentences")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
            }

            Text(fix.prompt)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(4)

            TextField("Write here...", text: $interactionManager.journalText, axis: .vertical)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(3...8)
                .padding(8)
                .background(Color(white: 0.08))
                .cornerRadius(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(white: 0.2), lineWidth: 1)
                )

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
