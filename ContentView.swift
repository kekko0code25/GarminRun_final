import SwiftUI

@main
struct GarminRunApp: App {
    @StateObject private var store = WorkoutStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
