import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    init(viewModel: OnboardingViewModel, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.state {
            case .boot:
                EmptyView()

            case .scanning:
                if let bug = viewModel.currentBug {
                    BugScanCardView(
                        bug: bug,
                        index: viewModel.currentScanIndex,
                        total: viewModel.allBugs.count,
                        nickname: viewModel.nickname(for: bug.slug),
                        inlineComment: viewModel.inlineComment(for: bug.slug),
                        onRespond: { response in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.respondToBug(bug.id, response: response)
                            }
                        }
                    )
                    .id(bug.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }

            case .moreDetected:
                MoreDetectedView(onContinue: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.continueAfterMoreDetected()
                    }
                })
                .transition(.opacity)

            case .confirmation:
                ScanConfirmationView(
                    activeBugs: viewModel.activeBugs,
                    deprioritizedCount: viewModel.deprioritizedBugs.count,
                    allRatedRarely: viewModel.allRatedRarely,
                    responseLabel: viewModel.responseLabel,
                    nickname: viewModel.nickname,
                    isLoading: viewModel.isLoading,
                    onCommit: {
                        Task {
                            await viewModel.commitConfiguration()
                        }
                    }
                )
                .transition(.opacity)

            case .committing:
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(.green)
                    Spacer()
                }
            }
        }
        .task {
            await viewModel.loadBugs()
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete {
                onComplete()
            }
        }
    }
}

// MARK: - Bug Scan Card

private struct BugScanCardView: View {
    let bug: Bug
    let index: Int
    let total: Int
    let nickname: String
    let inlineComment: String
    let onRespond: (BugResponse) -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PATTERN DETECTED")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))
                Spacer()
                Text("\(index + 1)/\(total)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.3))
            }
            .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 0) {
                    // Soul animation
                    BugSoulView(slug: bug.slug, intensity: .present, size: .medium)
                        .frame(height: 120)
                        .padding(.bottom, 20)

                    // Bug nickname
                    Text(nickname)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 16)

                    // Full description
                    Text(bug.bugDescription)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(white: 0.7))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 16)

                    // Inline comment
                    if !inlineComment.isEmpty {
                        Text(inlineComment)
                            .font(.system(.callout, design: .monospaced))
                            .foregroundColor(BugColors.color(for: bug.slug).opacity(0.7))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 24)
                    }

                    // Question
                    Text("Does this run in your system?")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))
                        .padding(.bottom, 20)
                }
            }

            Spacer()

            // Response buttons
            VStack(spacing: 10) {
                ForEach(BugResponse.allCases, id: \.rawValue) { response in
                    Button(action: { onRespond(response) }) {
                        Text("[ \(response.label) ]")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(buttonColor(for: response))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(buttonColor(for: response).opacity(0.08))
                            .cornerRadius(2)
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .onAppear {
            appeared = false
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                appeared = true
            }
        }
    }

    private func buttonColor(for response: BugResponse) -> Color {
        switch response {
        case .yesOften: return .green
        case .sometimes: return Color(white: 0.6)
        case .rarely: return Color(white: 0.4)
        }
    }
}

// MARK: - "2 more detected" Pause

private struct MoreDetectedView: View {
    let onContinue: () -> Void

    @State private var showText = false
    @State private var showContinue = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                if showText {
                    Text("2 more patterns detected...")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }

            Spacer()

            if showContinue {
                Button(action: onContinue) {
                    Text("[ Continue scan ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }
                .transition(.opacity)
            }

            Spacer()
                .frame(height: 80)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
                showText = true
            }
            withAnimation(.easeIn(duration: 0.4).delay(1.5)) {
                showContinue = true
            }
        }
    }
}

// MARK: - Scan Confirmation

private struct ScanConfirmationView: View {
    let activeBugs: [Bug]
    let deprioritizedCount: Int
    let allRatedRarely: Bool
    let responseLabel: (Bug) -> String
    let nickname: (String) -> String
    let isLoading: Bool
    let onCommit: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)

            Text("SCAN COMPLETE")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.4))
                .padding(.bottom, 24)

            Text("\(activeBugs.count) active patterns detected:")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .padding(.bottom, 20)

            VStack(spacing: 16) {
                ForEach(Array(activeBugs.enumerated()), id: \.element.id) { index, bug in
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(rankColor(for: index))
                            .frame(width: 32, alignment: .trailing)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(nickname(bug.slug))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.white)

                                Text(responseLabel(bug))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(Color(white: 0.4))
                            }

                            BugSoulView(slug: bug.slug, intensity: .quiet, size: .small)
                                .frame(height: 50)
                        }

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            if deprioritizedCount > 0 {
                Text("\(deprioritizedCount) patterns deprioritized.")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))
                    .padding(.bottom, 20)
            }

            VStack(spacing: 6) {
                if allRatedRarely {
                    Text("// Interesting. Let's start here anyway.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))
                } else {
                    Text("// Fixes will target your top patterns.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))

                    Text("// #1 gets the most attention.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))

                    Text("// You can adjust this anytime.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))
                }
            }
            .padding(.bottom, 20)

            Spacer()

            if isLoading {
                ProgressView()
                    .tint(.green)
                    .padding(.bottom, 80)
            } else {
                Button(action: onCommit) {
                    Text("[ Commit configuration ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }
                .padding(.bottom, 80)
                .opacity(appeared ? 1 : 0)
            }
        }
        .padding(.horizontal, 24)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return .green
        case 1: return Color(red: 0.5, green: 0.75, blue: 0.35)
        case 2: return Color(red: 0.65, green: 0.65, blue: 0.3)
        default: return Color(white: 0.4)
        }
    }
}
