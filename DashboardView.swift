import Foundation

// MARK: - Workout Model
struct Workout: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var title: String
    var distanceKm: Double
    var durationSeconds: Int
    var avgHeartRate: Int
    var maxHeartRate: Int
    var avgPaceSecondsPerKm: Int
    var calories: Int
    var elevationGainM: Int
    var laps: [Lap]
    var notes: String
    var aiAnalysis: String?
    var aiAnalysisDate: Date?
    var garminActivityId: String?

    // Computed
    var paceString: String {
        let min = avgPaceSecondsPerKm / 60
        let sec = avgPaceSecondsPerKm % 60
        return String(format: "%d:%02d /km", min, sec)
    }

    var durationString: String {
        let h = durationSeconds / 3600
        let m = (durationSeconds % 3600) / 60
        let s = durationSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    var speedKmh: Double {
        guard durationSeconds > 0 else { return 0 }
        return distanceKm / (Double(durationSeconds) / 3600.0)
    }

    var formattedDistance: String {
        String(format: "%.2f km", distanceKm)
    }

    // For Gemini prompt
    var summaryForAI: String {
        """
        Allenamento di corsa - \(title)
        Data: \(DateFormatter.displayFull.string(from: date))
        Distanza: \(String(format: "%.2f", distanceKm)) km
        Durata: \(durationString)
        Passo medio: \(paceString)
        Velocità media: \(String(format: "%.1f", speedKmh)) km/h
        FC media: \(avgHeartRate) bpm
        FC massima: \(maxHeartRate) bpm
        Calorie: \(calories) kcal
        Dislivello positivo: \(elevationGainM) m
        Numero di lap: \(laps.count)
        \(laps.isEmpty ? "" : "Dettaglio lap:\n" + laps.enumerated().map { i, l in "  Lap \(i+1): \(l.distanceKm, format: "%.2f") km in \(l.durationString), passo \(l.paceString), HR \(l.avgHeartRate) bpm" }.joined(separator: "\n"))
        \(notes.isEmpty ? "" : "Note atleta: \(notes)")
        """
    }
}

// MARK: - Lap
struct Lap: Identifiable, Codable {
    var id: UUID = UUID()
    var distanceKm: Double
    var durationSeconds: Int
    var avgHeartRate: Int
    var avgPaceSecondsPerKm: Int

    var paceString: String {
        let min = avgPaceSecondsPerKm / 60
        let sec = avgPaceSecondsPerKm % 60
        return String(format: "%d:%02d", min, sec)
    }

    var durationString: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Sample Data
extension Workout {
    static var samples: [Workout] {
        [
            Workout(
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                title: "Corsa mattutina",
                distanceKm: 8.42,
                durationSeconds: 2538,
                avgHeartRate: 148,
                maxHeartRate: 172,
                avgPaceSecondsPerKm: 302,
                calories: 612,
                elevationGainM: 45,
                laps: [
                    Lap(distanceKm: 1, durationSeconds: 308, avgHeartRate: 140, avgPaceSecondsPerKm: 308),
                    Lap(distanceKm: 1, durationSeconds: 304, avgHeartRate: 145, avgPaceSecondsPerKm: 304),
                    Lap(distanceKm: 1, durationSeconds: 300, avgHeartRate: 150, avgPaceSecondsPerKm: 300),
                    Lap(distanceKm: 1, durationSeconds: 298, avgHeartRate: 153, avgPaceSecondsPerKm: 298),
                    Lap(distanceKm: 1, durationSeconds: 301, avgHeartRate: 151, avgPaceSecondsPerKm: 301),
                ],
                notes: "Buona uscita, gambe fresche",
                aiAnalysis: nil
            ),
            Workout(
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                title: "Interval training 5×1km",
                distanceKm: 9.15,
                durationSeconds: 2820,
                avgHeartRate: 162,
                maxHeartRate: 185,
                avgPaceSecondsPerKm: 308,
                calories: 720,
                elevationGainM: 30,
                laps: [
                    Lap(distanceKm: 1, durationSeconds: 420, avgHeartRate: 135, avgPaceSecondsPerKm: 420),
                    Lap(distanceKm: 1, durationSeconds: 248, avgHeartRate: 175, avgPaceSecondsPerKm: 248),
                    Lap(distanceKm: 1, durationSeconds: 252, avgHeartRate: 178, avgPaceSecondsPerKm: 252),
                    Lap(distanceKm: 1, durationSeconds: 245, avgHeartRate: 182, avgPaceSecondsPerKm: 245),
                    Lap(distanceKm: 1, durationSeconds: 250, avgHeartRate: 180, avgPaceSecondsPerKm: 250),
                    Lap(distanceKm: 1, durationSeconds: 255, avgHeartRate: 183, avgPaceSecondsPerKm: 255),
                ],
                notes: "Recuperi 90s. Difficile ma finito",
                aiAnalysis: nil
            ),
            Workout(
                date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
                title: "Long run domenicale",
                distanceKm: 18.50,
                durationSeconds: 6120,
                avgHeartRate: 138,
                maxHeartRate: 158,
                avgPaceSecondsPerKm: 331,
                calories: 1380,
                elevationGainM: 180,
                laps: [],
                notes: "Passo easy, ottimo recupero",
                aiAnalysis: "✅ Ottimo long run! Il passo conservativo di 5:31/km e la FC media di 138 bpm indicano una corretta esecuzione in zona aerobica. Il dislivello di 180m aggiunge stimolo senza compromettere il recupero. Suggerisco di mantenere questo volume per altre 2 settimane prima di incrementare."
            )
        ]
    }
}

// MARK: - Double formatting
extension Double {
    var format: (String) -> String {{ fmt in String(format: fmt, self) }}
}

// MARK: - DateFormatter
extension DateFormatter {
    static let displayFull: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        f.locale = Locale(identifier: "it_IT")
        return f
    }()
    static let displayShort: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale(identifier: "it_IT")
        return f
    }()
    static let displayTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
}
