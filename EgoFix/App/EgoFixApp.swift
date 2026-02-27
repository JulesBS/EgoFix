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
                let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
                let fm = FileManager.default
                // Remove all SQLite companion files (-shm, -wal) alongside the main store
                for suffix in ["", "-shm", "-wal"] {
                    let fileURL = storeURL.deletingLastPathComponent()
                        .appending(path: "default.store\(suffix)")
                    try? fm.removeItem(at: fileURL)
                }
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
