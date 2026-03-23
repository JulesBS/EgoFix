import SwiftUI

struct RecommendationCardView: View {
    let recommendation: PatternRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title with arrow indicator
            HStack(spacing: 8) {
                Text("▶")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.green)

                Text(recommendation.title.uppercased())
                    .font(EgoTheme.mono(.callout))
                    .fontWeight(.medium)
                    .foregroundColor(EgoTheme.textPrimary)
            }

            // Description
            Text(recommendation.description)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)
                .padding(.leading, 18)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EgoTheme.surface.opacity(0.3))
        .cornerRadius(2)
    }
}

#Preview {
    ZStack {
        EgoTheme.bg.ignoresSafeArea()

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
