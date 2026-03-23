import SwiftUI
import SwiftData

@main
struct EgoFixApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                UserProfile.self,
                Bug.self,
                Fix.self,
                FixCompletion.self,
                TimerSession.self,
                Crash.self,
                VersionEntry.self,
                AnalyticsEvent.self,
                DetectedPattern.self,
                WeeklyDiagnostic.self,
                MicroEducation.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                // If schema changed, try to delete and recreate (development only)
                print("Schema changed, attempting to recreate database: \(error)")
                let fm = FileManager.default
                let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                    ?? URL.applicationSupportDirectory

                // Deduplicate candidate store URLs
                var seen = Set<String>()
                let candidates = [
                    appSupport.appending(path: "default.store"),
                    URL.applicationSupportDirectory.appending(path: "default.store"),
                    modelConfiguration.url
                ].filter { seen.insert($0.absoluteString).inserted }

                for storeURL in candidates {
                    for suffix in ["", "-shm", "-wal"] {
                        let fileURL = storeURL.deletingLastPathComponent()
                            .appending(path: storeURL.lastPathComponent + suffix)
                        try? fm.removeItem(at: fileURL)
                    }
                }

                // Ensure the directory exists before recreating
                try? fm.createDirectory(at: appSupport, withIntermediateDirectories: true)

                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            }
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
