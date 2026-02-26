import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showOnboarding = true
    @State private var selectedTab = 0
    @State private var showCrash = false
    @State private var showBootSequence = true
    @State private var bootSequenceChecked = false

    @AppStorage("hasSeenBoot") private var hasSeenBoot = false

    var body: some View {
        ZStack {
            if showBootSequence && bootSequenceChecked {
                BootSequenceView(onComplete: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showBootSequence = false
                        hasSeenBoot = true
                    }
                })
            } else if showOnboarding && !showBootSequence {
                OnboardingView(
                    viewModel: makeOnboardingViewModel(),
                    onComplete: {
                        showOnboarding = false
                    }
                )
            } else if !showBootSequence {
                mainTabView
                    .scanlines()
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await loadSeedData()
            await checkOnboarding()
            bootSequenceChecked = true
            // If user has seen boot before, skip it (they already saw onboarding too)
            if hasSeenBoot {
                showBootSequence = false
            }
        }
    }

    private var mainTabView: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                TodayView(
                    viewModel: makeTodayViewModel(),
                    makeWeeklyDiagnosticViewModel: makeWeeklyDiagnosticViewModel
                )
                    .tabItem {
                        Label("Today", systemImage: "terminal")
                    }
                    .tag(0)

                HistoryView(viewModel: makeHistoryViewModel())
                    .tabItem {
                        Label("History", systemImage: "doc.text")
                    }
                    .tag(1)

                PatternsView(viewModel: makePatternsViewModel())
                    .tabItem {
                        Label("Patterns", systemImage: "waveform")
                    }
                    .tag(2)

                DocsView(makeBugLibraryViewModel: makeBugLibraryViewModel)
                    .tabItem {
                        Label("Docs", systemImage: "book")
                    }
                    .tag(3)
            }
            .tint(.green)
            .onAppear {
                // Improve tab bar contrast
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(white: 0.08, alpha: 1.0)

                // Unselected items - brighter
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.5, alpha: 1.0)
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: UIColor(white: 0.5, alpha: 1.0)
                ]

                // Selected items - green
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemGreen
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor.systemGreen
                ]

                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }

            // Crash button - always accessible
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    CrashButton(action: { showCrash = true })
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showCrash) {
            CrashView(viewModel: makeCrashViewModel())
        }
    }

    // MARK: - Data Loading

    private func loadSeedData() async {
        let loader = SeedDataLoader(modelContext: modelContext)
        do {
            try await loader.loadSeedDataIfNeeded()
        } catch {
            print("Failed to load seed data: \(error)")
        }
    }

    private func checkOnboarding() async {
        let viewModel = makeOnboardingViewModel()
        showOnboarding = await viewModel.checkOnboardingNeeded()
    }

    // MARK: - Factory Methods

    private func makeOnboardingViewModel() -> OnboardingViewModel {
        let bugRepo = LocalBugRepository(modelContext: modelContext)
        let userRepo = LocalUserRepository(modelContext: modelContext)
        return OnboardingViewModel(bugRepository: bugRepo, userRepository: userRepo)
    }

    private func makeTodayViewModel() -> TodayViewModel {
        let fixRepo = LocalFixRepository(modelContext: modelContext)
        let fixCompletionRepo = LocalFixCompletionRepository(modelContext: modelContext)
        let userRepo = LocalUserRepository(modelContext: modelContext)
        let analyticsRepo = LocalAnalyticsEventRepository(modelContext: modelContext)
        let patternRepo = LocalPatternRepository(modelContext: modelContext)
        let diagnosticRepo = LocalWeeklyDiagnosticRepository(modelContext: modelContext)
        let timerSessionRepo = LocalTimerSessionRepository(modelContext: modelContext)
        let bugRepo = LocalBugRepository(modelContext: modelContext)
        let microEducationRepo = LocalMicroEducationRepository(modelContext: modelContext)

        let dailyFixService = DailyFixService(
            fixRepository: fixRepo,
            fixCompletionRepository: fixCompletionRepo,
            userRepository: userRepo,
            analyticsEventRepository: analyticsRepo
        )

        let timerService = TimerService(timerSessionRepository: timerSessionRepo)
        let microEducationService = MicroEducationService(repository: microEducationRepo)
        let streakService = StreakService(userRepository: userRepo)

        let weeklyDiagnosticService = WeeklyDiagnosticService(
            weeklyDiagnosticRepository: diagnosticRepo,
            bugRepository: bugRepo,
            userRepository: userRepo,
            analyticsEventRepository: analyticsRepo
        )

        let detectors: [PatternDetector] = [
            AvoidanceDetector(),
            TemporalCrashDetector(),
            ContextSpikeDetector(),
            CorrelatedBugsDetector(),
            PlateauDetector(),
            ImprovementDetector()
        ]

        let diagnosticEngine = DiagnosticEngine(
            analyticsEventRepository: analyticsRepo,
            weeklyDiagnosticRepository: diagnosticRepo,
            patternRepository: patternRepo,
            bugRepository: bugRepo,
            userRepository: userRepo,
            detectors: detectors
        )

        let patternSurfacingService = PatternSurfacingService(
            diagnosticEngine: diagnosticEngine,
            analyticsEventRepository: analyticsRepo,
            userRepository: userRepo
        )

        return TodayViewModel(
            dailyFixService: dailyFixService,
            fixRepository: fixRepo,
            bugRepository: bugRepo,
            patternSurfacingService: patternSurfacingService,
            timerService: timerService,
            microEducationService: microEducationService,
            streakService: streakService,
            userRepository: userRepo,
            weeklyDiagnosticService: weeklyDiagnosticService,
            fixCompletionRepository: fixCompletionRepo,
            diagnosticEngine: diagnosticEngine
        )
    }

    private func makeWeeklyDiagnosticViewModel() -> WeeklyDiagnosticViewModel {
        let diagnosticRepo = LocalWeeklyDiagnosticRepository(modelContext: modelContext)
        let bugRepo = LocalBugRepository(modelContext: modelContext)
        let userRepo = LocalUserRepository(modelContext: modelContext)
        let analyticsRepo = LocalAnalyticsEventRepository(modelContext: modelContext)

        let weeklyDiagnosticService = WeeklyDiagnosticService(
            weeklyDiagnosticRepository: diagnosticRepo,
            bugRepository: bugRepo,
            userRepository: userRepo,
            analyticsEventRepository: analyticsRepo
        )

        return WeeklyDiagnosticViewModel(weeklyDiagnosticService: weeklyDiagnosticService)
    }

    private func makeHistoryViewModel() -> HistoryViewModel {
        let userRepo = LocalUserRepository(modelContext: modelContext)
        let versionEntryRepo = LocalVersionEntryRepository(modelContext: modelContext)
        let fixCompletionRepo = LocalFixCompletionRepository(modelContext: modelContext)
        let timerSessionRepo = LocalTimerSessionRepository(modelContext: modelContext)

        let versionService = VersionService(
            userRepository: userRepo,
            versionEntryRepository: versionEntryRepo,
            fixCompletionRepository: fixCompletionRepo
        )

        let statsService = StatsService(
            fixCompletionRepository: fixCompletionRepo,
            timerSessionRepository: timerSessionRepo,
            userRepository: userRepo
        )

        return HistoryViewModel(
            versionService: versionService,
            versionEntryRepository: versionEntryRepo,
            userRepository: userRepo,
            statsService: statsService
        )
    }

    private func makeCrashViewModel() -> CrashViewModel {
        let crashRepo = LocalCrashRepository(modelContext: modelContext)
        let fixRepo = LocalFixRepository(modelContext: modelContext)
        let fixCompletionRepo = LocalFixCompletionRepository(modelContext: modelContext)
        let userRepo = LocalUserRepository(modelContext: modelContext)
        let analyticsRepo = LocalAnalyticsEventRepository(modelContext: modelContext)

        let crashService = CrashService(
            crashRepository: crashRepo,
            fixRepository: fixRepo,
            fixCompletionRepository: fixCompletionRepo,
            userRepository: userRepo,
            analyticsEventRepository: analyticsRepo
        )

        let bugRepo = LocalBugRepository(modelContext: modelContext)

        return CrashViewModel(
            crashService: crashService,
            bugRepository: bugRepo,
            fixRepository: fixRepo
        )
    }

    private func makePatternsViewModel() -> PatternsViewModel {
        let patternRepo = LocalPatternRepository(modelContext: modelContext)
        let userRepo = LocalUserRepository(modelContext: modelContext)
        let weeklyDiagnosticRepo = LocalWeeklyDiagnosticRepository(modelContext: modelContext)
        let bugRepo = LocalBugRepository(modelContext: modelContext)

        let trendAnalysisService = TrendAnalysisService(
            weeklyDiagnosticRepository: weeklyDiagnosticRepo,
            bugRepository: bugRepo
        )

        return PatternsViewModel(
            patternRepository: patternRepo,
            userRepository: userRepo,
            bugRepository: bugRepo,
            trendAnalysisService: trendAnalysisService
        )
    }

    private func makeBugLibraryViewModel() -> BugLibraryViewModel {
        let bugRepo = LocalBugRepository(modelContext: modelContext)
        let userRepo = LocalUserRepository(modelContext: modelContext)
        let weeklyDiagnosticRepo = LocalWeeklyDiagnosticRepository(modelContext: modelContext)
        let crashRepo = LocalCrashRepository(modelContext: modelContext)
        let patternRepo = LocalPatternRepository(modelContext: modelContext)

        let bugLifecycleService = BugLifecycleService(
            bugRepository: bugRepo,
            weeklyDiagnosticRepository: weeklyDiagnosticRepo,
            crashRepository: crashRepo,
            patternRepository: patternRepo
        )

        return BugLibraryViewModel(
            bugRepository: bugRepo,
            userRepository: userRepo,
            bugLifecycleService: bugLifecycleService
        )
    }
}

// MARK: - Crash Button with Pulse Animation

private struct CrashButton: View {
    let action: () -> Void
    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            Text("[ ! ]")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(2)
                .shadow(color: .red.opacity(0.5), radius: 5, x: 0, y: 0)
                .scaleEffect(isPulsing ? 1.05 : 1.0)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}
