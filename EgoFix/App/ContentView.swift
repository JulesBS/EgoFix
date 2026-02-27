import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showOnboarding = true
    @State private var showBootSequence = true
    @State private var bootSequenceChecked = false

    @AppStorage("hasSeenBoot") private var hasSeenBoot = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            if showBootSequence && bootSequenceChecked {
                BootSequenceView(
                    isFirstLaunch: !hasSeenBoot,
                    onComplete: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            hasSeenBoot = true
                            showBootSequence = false
                        }
                    }
                )
            } else if showOnboarding && !showBootSequence {
                let vm = makeOnboardingViewModel()
                OnboardingView(
                    viewModel: vm,
                    onComplete: {
                        hasCompletedOnboarding = true
                        showOnboarding = false
                    }
                )
                .onAppear {
                    // Start the scan after boot completes
                    if vm.state == .boot {
                        vm.beginScan()
                    }
                }
            } else if !showBootSequence {
                NavigationStack {
                    TodayView(
                        viewModel: makeTodayViewModel(),
                        makeWeeklyDiagnosticViewModel: makeWeeklyDiagnosticViewModel,
                        makeCrashViewModel: makeCrashViewModel
                    )
                }
                .scanlines()
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await loadSeedData()
            await checkOnboarding()
            bootSequenceChecked = true
            if hasSeenBoot && hasCompletedOnboarding {
                showBootSequence = false
                showOnboarding = false
            } else if hasSeenBoot && !hasCompletedOnboarding {
                // Seen boot but didn't finish onboarding — skip boot, show onboarding
                showBootSequence = false
                showOnboarding = true
            } else if !hasSeenBoot {
                // First launch — show boot then onboarding
                showBootSequence = true
                showOnboarding = true
            }
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
        let needed = await viewModel.checkOnboardingNeeded()
        if !needed {
            hasCompletedOnboarding = true
            showOnboarding = false
        }
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
        let crashRepo = LocalCrashRepository(modelContext: modelContext)
        let versionEntryRepo = LocalVersionEntryRepository(modelContext: modelContext)

        let dailyFixService = DailyFixService(
            fixRepository: fixRepo,
            fixCompletionRepository: fixCompletionRepo,
            userRepository: userRepo,
            analyticsEventRepository: analyticsRepo
        )

        let timerService = TimerService(timerSessionRepository: timerSessionRepo)
        let microEducationService = MicroEducationService(repository: microEducationRepo)
        let streakService = StreakService(userRepository: userRepo)

        let versionService = VersionService(
            userRepository: userRepo,
            versionEntryRepository: versionEntryRepo,
            fixCompletionRepository: fixCompletionRepo
        )

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

        let bugIntensityProvider = BugIntensityProvider(
            weeklyDiagnosticRepository: diagnosticRepo,
            crashRepository: crashRepo
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
            versionService: versionService,
            weeklyDiagnosticService: weeklyDiagnosticService,
            fixCompletionRepository: fixCompletionRepo,
            diagnosticEngine: diagnosticEngine,
            bugIntensityProvider: bugIntensityProvider
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
}
