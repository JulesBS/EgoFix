import SwiftUI

struct DocsView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("DOCS")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.white)

                    Text("// Pull-based education. Read when ready.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.6))

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    DocSectionView(
                        title: "What is a Bug?",
                        content: "In EgoFix, a bug is an ego pattern — a habitual response that fires when it shouldn't. Need to be right. Need to be liked. Need to impress. These aren't flaws to eliminate; they're defensive functions to refactor."
                    )

                    DocSectionView(
                        title: "What is a Fix?",
                        content: "A fix is a daily micro-mission designed to interrupt the pattern. Not therapy. Not journaling. Just one small, specific action that creates a moment of awareness."
                    )

                    DocSectionView(
                        title: "What is a Crash?",
                        content: "A crash is when the bug takes over. You snapped at someone. You talked over them. You performed when you didn't need to. Log it. No judgment. Data helps."
                    )

                    DocSectionView(
                        title: "What is a Version?",
                        content: "Your version number represents accumulated progress. Every 7 fixes applied = minor update (1.0 → 1.1). Every 10 minor updates = major update (1.9 → 2.0). It's not a score. It's a changelog."
                    )

                    DocSectionView(
                        title: "Pattern Detection",
                        content: "The app watches for patterns you might not notice. Avoiding certain fixes. Crashing on specific days. Bugs that flare together. This isn't surveillance — it's surfacing blind spots."
                    )
                }
                .padding()
            }
        }
    }
}

struct DocSectionView: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.green)

            Text(content)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
}
