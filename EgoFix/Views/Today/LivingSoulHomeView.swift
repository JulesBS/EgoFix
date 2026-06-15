import SwiftUI

// MARK: - Concept: The Living Soul home
//
// The creature from the awakening doesn't die when onboarding ends — it follows
// you home. Its seven orbiting cubes ARE your seven bugs (canonical order). Left
// alone, each cube flickers to reflect your *actual* current state: a quiet bug
// breathes green, a loud bug agitates red. The daily fix becomes "tending" the
// soul — applying it makes that bug's cube pulse green and settle; a crash flares
// it red. You aren't checking a box. You're watching a live model of yourself
// respond to what you do.
//
// This view is a self-contained vertical slice driven by `SoulBugVital` data so it
// runs in Xcode Previews. Wiring it into the real Today flow is a follow-up.

/// One bug's live state, as the home reads it.
struct SoulBugVital: Identifiable {
    var id: String { slug }
    let slug: String
    let intensity: BugIntensity
    var isPrimary: Bool = false
    /// A revelation the engine surfaced on this bug, shown on inspect. Optional.
    var noticed: String? = nil

    /// Maps intensity to the animator's mood index (0=quiet, 1=present, 2=loud).
    var mood: Int {
        switch intensity {
        case .quiet: return 0
        case .present: return 1
        case .loud: return 2
        }
    }
}

struct LivingSoulHomeView: View {
    let vitals: [SoulBugVital]
    let version: String
    /// The day's fix, framed as something the soul needs.
    let todaysPrompt: String
    let todaysBugSlug: String

    /// Fired when the user tends the soul (applies the fix).
    var onApplied: (() -> Void)? = nil
    /// Fired when the user logs a crash on the primary bug.
    var onCrashed: (() -> Void)? = nil

    @State private var renderer: OnboardingSoulRenderer?
    @State private var rendererFailed = false
    @State private var showInspect = false
    @State private var tended = false
    @State private var crashed = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Canonical cube order — the single source of truth shared with onboarding.
    private let order = ScenarioWeightCalculator.allBugSlugs

    private var shouldPause: Bool {
        scenePhase != .active || reduceMotion
    }

    private var primary: SoulBugVital? {
        vitals.first(where: { $0.isPrimary }) ?? vitals.first
    }

    // Stability read across all active bugs.
    private var stability: (label: String, color: Color) {
        if vitals.contains(where: { $0.intensity == .loud }) {
            return ("UNSTABLE", .red)
        }
        if vitals.contains(where: { $0.intensity == .present }) {
            return ("ACTIVE", EgoTheme.amber)
        }
        return ("STABLE", EgoTheme.green)
    }

    private var soulStatusLine: String {
        if crashed { return "// logged. the bug won this round." }
        if tended { return "// it settled. for now." }
        let loud = vitals.filter { $0.intensity == .loud }
        if let first = loud.first {
            return "// \(loud.count) running hot. \(first.slug) loudest."
        }
        let active = vitals.filter { $0.intensity != .quiet }.count
        if active == 0 { return "// quiet. nothing firing right now." }
        return "// \(active) pattern\(active == 1 ? "" : "s") active. holding."
    }

    var body: some View {
        ZStack {
            EgoTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                soulHero
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)

                Text(soulStatusLine)
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .animation(.easeOut(duration: 0.25), value: soulStatusLine)

                if showInspect {
                    inspectPanel
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    tendPanel
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        .transition(.opacity)
                }
            }
        }
        .onChange(of: vitals.map(\.mood)) { _, _ in pushMoods() }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("SELF")
                .font(EgoTheme.label())
                .tracking(2.8)
                .foregroundColor(EgoTheme.textMuted)
            Text("v\(version)")
                .font(EgoTheme.label())
                .foregroundColor(EgoTheme.textMuted.opacity(0.7))
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(stability.color)
                    .frame(width: 6, height: 6)
                    .shadow(color: stability.color.opacity(0.6), radius: 4)
                Text(stability.label)
                    .font(EgoTheme.label())
                    .tracking(1.5)
                    .foregroundColor(stability.color)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("System \(stability.label.lowercased())")
        }
    }

    // MARK: Soul hero

    @ViewBuilder
    private var soulHero: some View {
        ZStack {
            if rendererFailed {
                // Graceful degradation: the ASCII soul stands in for the 3D creature.
                BugSoulView(
                    slug: primary?.slug ?? "need-to-be-right",
                    intensity: primary?.intensity ?? .present,
                    size: .large
                )
                .padding(40)
            } else {
                OnboardingSoulView(
                    onRendererReady: { r in
                        renderer = r
                        pushMoods()
                    },
                    onRendererFailed: { rendererFailed = true },
                    isPaused: shouldPause
                )
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 16)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.25)) { showInspect.toggle() }
        }
        .accessibilityElement()
        .accessibilityLabel(soulAccessibilityLabel)
        .accessibilityHint("Double tap to inspect your patterns")
    }

    private var soulAccessibilityLabel: String {
        let active = vitals.filter { $0.intensity != .quiet }.count
        let p = primary.map { "Primary pattern \($0.slug), \($0.intensity.rawValue)." } ?? ""
        return "Your self-model. \(active) patterns active. \(p)"
    }

    // MARK: Tend panel

    private var tendPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            if tended || crashed {
                FigmaSecondaryButton(label: "INSPECT") {
                    withAnimation(.easeOut(duration: 0.25)) { showInspect = true }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("// \(todaysBugSlug) needs attention")
                        .font(EgoTheme.label())
                        .foregroundColor(BugColors.color(for: todaysBugSlug).opacity(0.8))
                    Text(todaysPrompt)
                        .font(EgoTheme.mono(.callout))
                        .foregroundColor(EgoTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    FigmaCTAButton(label: "APPLIED") { tend() }
                    Button(action: logCrash) {
                        Text("[ it won ]")
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textMuted)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Log a crash")
                    .accessibilityHint("The bug won this time")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Inspect panel — the cubes labelled as your bugs

    private var inspectPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("INSPECT")
                    .font(EgoTheme.label())
                    .tracking(2.2)
                    .foregroundColor(EgoTheme.green)
                    .greenGlow()
                Spacer()
                Button("[ x ]") {
                    withAnimation(.easeOut(duration: 0.25)) { showInspect = false }
                }
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)
                .buttonStyle(.plain)
                .accessibilityLabel("Close inspector")
            }
            .padding(.bottom, 12)

            ForEach(orderedVitals) { vital in
                vitalRow(vital)
            }
        }
        .padding(20)
        .glassCard()
    }

    /// All seven bugs in canonical cube order — so the list matches the orbit.
    private var orderedVitals: [SoulBugVital] {
        order.map { slug in
            vitals.first(where: { $0.slug == slug })
                ?? SoulBugVital(slug: slug, intensity: .quiet)
        }
    }

    @ViewBuilder
    private func vitalRow(_ vital: SoulBugVital) -> some View {
        let dot = dotColor(for: vital.intensity)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Circle()
                    .fill(dot)
                    .frame(width: 7, height: 7)
                    .shadow(color: dot.opacity(0.6), radius: vital.intensity == .loud ? 4 : 0)
                Text(vital.slug)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(vital.isPrimary ? EgoTheme.textPrimary : EgoTheme.textMuted)
                Spacer()
                Text(vital.intensity.rawValue.uppercased())
                    .font(EgoTheme.label())
                    .foregroundColor(dot)
            }
            if let noticed = vital.noticed {
                Text("// \(noticed)")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted.opacity(0.85))
                    .padding(.leading, 19)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vital.slug), \(vital.intensity.rawValue)\(vital.isPrimary ? ", primary" : "")")
    }

    private func dotColor(for intensity: BugIntensity) -> Color {
        switch intensity {
        case .quiet: return EgoTheme.green
        case .present: return EgoTheme.amber
        case .loud: return .red
        }
    }

    // MARK: Actions

    private func tend() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let idx = order.firstIndex(of: todaysBugSlug) {
            renderer?.animator.applyFixReaction(cubeIndex: idx)
        }
        withAnimation(.easeOut(duration: 0.3)) { tended = true }
        onApplied?()
    }

    private func logCrash() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let idx = order.firstIndex(of: todaysBugSlug) {
            renderer?.animator.crashReaction(cubeIndex: idx)
        }
        withAnimation(.easeOut(duration: 0.3)) { crashed = true }
        onCrashed?()
    }

    /// Pushes the current vitals into the animator so idle cubes reflect real state.
    private func pushMoods() {
        guard let renderer else { return }
        let moods = order.map { slug -> Int in
            vitals.first(where: { $0.slug == slug })?.mood ?? 0
        }
        renderer.animator.setBugMoods(moods)
    }
}

#Preview("Living Soul — mixed") {
    LivingSoulHomeView(
        vitals: [
            SoulBugVital(slug: "need-to-be-right", intensity: .present),
            SoulBugVital(slug: "need-to-control", intensity: .loud, isPrimary: true,
                         noticed: "fires most on Mondays. something about that day."),
            SoulBugVital(slug: "need-to-compare", intensity: .present),
            SoulBugVital(slug: "need-to-be-liked", intensity: .quiet),
            SoulBugVital(slug: "need-to-impress", intensity: .quiet),
            SoulBugVital(slug: "need-to-deflect", intensity: .loud),
            SoulBugVital(slug: "need-to-narrate", intensity: .quiet)
        ],
        version: "1.4",
        todaysPrompt: "Next time you're about to redo someone's work, let it ship as-is.",
        todaysBugSlug: "need-to-control"
    )
}
