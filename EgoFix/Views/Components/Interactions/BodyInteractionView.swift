import SwiftUI

struct BodyInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    private var config: BodyConfig? {
        interactionManager.bodyConfig
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InteractionHeader(type: "BODY", status: statusText, typeColor: .mint)

            Text(fix.prompt)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)

            if let config = config {
                // WHERE section
                VStack(alignment: .leading, spacing: 8) {
                    Text("WHERE")
                        .font(EgoTheme.label())
                        .foregroundColor(EgoTheme.textMuted)
                        .tracking(1.5)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], alignment: .leading, spacing: 8) {
                        ForEach(config.scanRegions, id: \.self) { region in
                            chipButton(
                                label: region,
                                isSelected: interactionManager.selectedBodyRegions.contains(region),
                                action: { interactionManager.toggleBodyRegion(region) }
                            )
                        }
                    }
                }

                // WHAT section
                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT")
                        .font(EgoTheme.label())
                        .foregroundColor(EgoTheme.textMuted)
                        .tracking(1.5)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], alignment: .leading, spacing: 8) {
                        ForEach(config.sensationDescriptors, id: \.self) { sensation in
                            chipButton(
                                label: sensation,
                                isSelected: interactionManager.selectedBodySensations.contains(sensation),
                                action: { interactionManager.toggleBodySensation(sensation) }
                            )
                        }
                    }
                }
            }

            InlineCommentView(comment: fix.inlineComment)
        }
        .interactionCard(borderColor: borderColor)
        .accessibilityLabel("Body awareness interaction, \(statusText)")
    }

    // MARK: - Chip Button

    @ViewBuilder
    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(isSelected ? .white : EgoTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.mint.opacity(0.3) : EgoTheme.surface.opacity(0.5))
                .cornerRadius(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(isSelected ? Color.mint.opacity(0.6) : EgoTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(label), \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
    }

    // MARK: - Computed

    private var statusText: String {
        let regions = interactionManager.selectedBodyRegions.count
        let sensations = interactionManager.selectedBodySensations.count
        if regions == 0 && sensations == 0 { return "Select regions + sensations" }
        return "\(regions) region\(regions == 1 ? "" : "s"), \(sensations) sensation\(sensations == 1 ? "" : "s")"
    }

    private var borderColor: Color {
        if !interactionManager.selectedBodyRegions.isEmpty && !interactionManager.selectedBodySensations.isEmpty {
            return Color.mint.opacity(0.5)
        }
        return EgoTheme.border
    }
}
