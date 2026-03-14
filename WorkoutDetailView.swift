import Foundation
import Combine

class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var isLoading = false

    private let saveKey = "garmin_workouts_v1"

    init() {
        load()
        if workouts.isEmpty {
            workouts = Workout.samples
            save()
        }
    }

    func add(_ workout: Workout) {
        workouts.insert(workout, at: 0)
        save()
    }

    func update(_ workout: Workout) {
        guard let idx = workouts.firstIndex(where: { $0.id == workout.id }) else { return }
        workouts[idx] = workout
        save()
    }

    func delete(at offsets: IndexSet) {
        workouts.remove(atOffsets: offsets)
        save()
    }

    func delete(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        save()
    }

    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Workout].self, from: data) else { return }
        workouts = decoded
    }

    // MARK: - Stats
    var totalDistanceKm: Double { workouts.reduce(0) { $0 + $1.distanceKm } }
    var totalDurationSeconds: Int { workouts.reduce(0) { $0 + $1.durationSeconds } }
    var totalCalories: Int { workouts.reduce(0) { $0 + $1.calories } }
    var avgHeartRate: Int {
        guard !workouts.isEmpty else { return 0 }
        return workouts.reduce(0) { $0 + $1.avgHeartRate } / workouts.count
    }

    var thisWeekWorkouts: [Workout] {
        let start = Calendar.current.startOfWeek(for: Date())
        return workouts.filter { $0.date >= start }
    }

    var thisWeekDistanceKm: Double { thisWeekWorkouts.reduce(0) { $0 + $1.distanceKm } }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps) ?? date
    }
}
