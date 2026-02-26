import SwiftUI

struct RecommendationCardView: View {
    let recommendation: PatternRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title with arrow indicator
            HStack(spacing: 8) {
                Text("▶")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)

                Text(recommendation.title.uppercased())
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }

            // Description
            Text(recommendation.description)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.6))
                .lineSpacing(4)
                .padding(.leading, 18)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.06))
        .cornerRadius(4)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            RecommendationCardView(
                recommendation: PatternRecommendation(
                    actionType: .adjustPriority,
                    title: "Raise Bug Priority",
                    description: "Consider making this bug your top priority. Avoidance often signals resistance to change.",
                    priority: 1
                )
            )

            RecommendationCardView(
                recommendation: PatternRecommendation(
                    actionType: .celebrateProgress,
                    title: "Acknowledge Your Progress",
                    description: "You're improving. Take a moment to recognize the work you've done.",
                    priority: 1
                )
            )
        }
        .padding()
    }
}
